//
// AKSDeviceConsole.m
//
// Copyright (c) 2013 Konstant Info Private Limited
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "AKSDeviceConsole.h"
#import "AppDelegate.h"
#import <QuartzCore/QuartzCore.h>
#include <assert.h>
#include <stdbool.h>
#include <sys/types.h>
#include <unistd.h>
#include <sys/sysctl.h>
#import "AKSLogsViewController.h"

#define AKS_LOG_DIR     [[AKSDeviceConsole documentsDirectory] stringByAppendingPathComponent:@"AKSLogs"]
#define FILE_SIZE_LIMIT     (6*1024*1024)
#define MAXIMUM_NUMBER_LOG  (10)

@interface AKSDeviceConsole () {
	UITextView *textView;
    UIButton *shareButton;
    NSString *currentLogPath;
}

@property (nonatomic, strong) UIWindow *window;

@end

@implementation AKSDeviceConsole

+ (instancetype)sharedInstance {
	static id __sharedInstance;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
	    __sharedInstance = [[AKSDeviceConsole alloc] init];
	});
	return __sharedInstance;
}

+ (NSString *)documentsDirectory {
	return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
}

- (id)init {
	if (self = [super init]) {
		[self initialSetup];
	}
	return self;
}

- (void)initialSetup {
	[self resetLogData];
}

+ (void)startService {
	dispatch_async(dispatch_get_main_queue(), ^(void) {
	    [AKSDeviceConsole sharedInstance];
	});
}
// Returns true if the current process is being debugged (either
// running under the debugger or has a debugger attached post facto).
+ (BOOL)AmIBeingDebugged {
    int                 junk;
    int                 mib[4];
    struct kinfo_proc   info;
    size_t              size;
    
    // Initialize the flags so that, if sysctl fails for some bizarre
    // reason, we get a predictable result.
    
    info.kp_proc.p_flag = 0;
    
    // Initialize mib, which tells sysctl the info we want, in this case
    // we're looking for information about a specific process ID.
    
    mib[0] = CTL_KERN;
    mib[1] = KERN_PROC;
    mib[2] = KERN_PROC_PID;
    mib[3] = getpid();
    
    // Call sysctl.
    
    size = sizeof(info);
    junk = sysctl(mib, sizeof(mib) / sizeof(*mib), &info, &size, NULL, 0);
    assert(junk == 0);
    
    // We're being debugged if the P_TRACED flag is set.
    
    return ( (info.kp_proc.p_flag & P_TRACED) != 0 );
}

- (void)resetLogData {
    NSString *dir = AKS_LOG_DIR;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator<NSString *> *enumerator = [fileManager enumeratorAtPath:dir];
    NSMutableArray *files = [NSMutableArray new];
    NSMutableArray *attributes = [NSMutableArray new];
    for (NSString *path in enumerator) {
        [files addObject:path];
    }
    NSArray *filesResults = [files sortedArrayUsingComparator:^NSComparisonResult(NSString *path1, NSString *path2) {
        NSDictionary *fileAttributes1 = [fileManager attributesOfItemAtPath:[dir stringByAppendingPathComponent:path1] error:NULL];
        NSDictionary *fileAttributes2 = [fileManager attributesOfItemAtPath:[dir stringByAppendingPathComponent:path2] error:NULL];
        NSDate *date1 = fileAttributes1[NSFileModificationDate];
        NSDate *date2 = fileAttributes2[NSFileModificationDate];
        return [date2 compare:date1];
    }];
    for (NSString *path in filesResults) {
        NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:[dir stringByAppendingPathComponent:path] error:NULL];
        if (fileAttributes) {
            NSDictionary *dict = @{NSFileSize: fileAttributes[NSFileSize], NSFileModificationDate: fileAttributes[NSFileModificationDate]};
            [attributes addObject:dict];
        } else {
            NSDictionary *dict = @{NSFileSize: @(0), NSFileModificationDate: [NSDate dateWithTimeIntervalSince1970:0]};
            [attributes addObject:dict];
        }
    }
    NSString *logsPath;
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyy-MM-dd-HH-mm-ss";
    formatter.timeZone = [NSTimeZone systemTimeZone];
    formatter.locale = [NSLocale autoupdatingCurrentLocale];
    NSString *formattedDate = [formatter stringFromDate:[NSDate date]];
    formattedDate = [formattedDate stringByAppendingString:@".txt"];
    if (filesResults.firstObject) {
        NSDictionary *dict = attributes.firstObject;
        NSUInteger size = [[dict objectForKey:NSFileSize] integerValue];
        if (size > FILE_SIZE_LIMIT) {
            logsPath = [AKS_LOG_DIR stringByAppendingPathComponent:formattedDate];
        } else {
            logsPath = [AKS_LOG_DIR stringByAppendingPathComponent:filesResults.firstObject];
        }
    } else {
        logsPath = [AKS_LOG_DIR stringByAppendingPathComponent:formattedDate];
    }
    currentLogPath = logsPath;
    if (![fileManager fileExistsAtPath:AKS_LOG_DIR]) {
        [fileManager createDirectoryAtPath:AKS_LOG_DIR withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    if (![fileManager fileExistsAtPath:logsPath]) {
        [@"\n" writeToFile:currentLogPath atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    }
	freopen([currentLogPath fileSystemRepresentation], "a", stderr);
    freopen([currentLogPath fileSystemRepresentation], "a", stdout);
    ZMLogDebug(@"freopen");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self setUpToGetLogData];
    });
}

- (void)showConsole {
	if (textView == nil) {
        self.alreadyShow = YES;
		CGRect bounds = [[UIScreen mainScreen] bounds];
		CGRect viewRectTextView = CGRectMake(0, 0, bounds.size.width, bounds.size.height);

		textView = [[UITextView alloc] initWithFrame:viewRectTextView];
		[textView setBackgroundColor:[UIColor blackColor]];
		[textView setFont:[UIFont systemFontOfSize:10]];
		[textView setEditable:NO];
		[textView setTextColor:[UIColor whiteColor]];
		[[textView layer] setOpacity:1];
        [self.window addSubview:textView];
        [self.window bringSubviewToFront:textView];
        
        shareButton = [UIButton new];
        shareButton.frame = CGRectMake(bounds.size.width-80-16, 16, 80, 32);
        [shareButton setBackgroundColor:[UIColor whiteColor]];
        [shareButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [shareButton setTitle:@"分享日志" forState:UIControlStateNormal];
        [self.window addSubview:shareButton];
        [self.window bringSubviewToFront:shareButton];
        
        UISwipeGestureRecognizer *sgr = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(hideWithAnimation)];
        sgr.numberOfTouchesRequired = 1;
        sgr.direction = UISwipeGestureRecognizerDirectionRight;
        [textView addGestureRecognizer:sgr];
        
        [shareButton addTarget:self action:@selector(shareTap) forControlEvents:UIControlEventTouchUpInside];

		[self showThisViewWithAnimation:textView duration:0.30];
		[self scrollToLast];
    } else {
        [self hideConsole];
    }
}

- (void)shareTap {
    [self hideWithAnimation];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:[AKSLogsViewController new]];
    [self.window.rootViewController presentViewController:nav animated:YES completion:nil];
}

- (void)hideWithAnimation {
	[self hideThisViewWithAnimation:textView duration:0.25];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self hideConsole];
    });
}
- (void)hideConsole {
    [textView removeFromSuperview];
    [shareButton removeFromSuperview];
	textView  = nil;
}
- (void)scrollToLast {
    if (!textView) {
        return;
    }
	NSRange txtOutputRange;
	txtOutputRange.location = textView.text.length;
	txtOutputRange.length = 0;
	textView.editable = YES;
	[textView scrollRangeToVisible:txtOutputRange];
	[textView setSelectedRange:txtOutputRange];
	textView.editable = NO;
}

- (void)setUpToGetLogData {
	NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:currentLogPath];
	[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(getData:) name:NSFileHandleReadCompletionNotification object:fileHandle];
	[fileHandle readInBackgroundAndNotify];
}

- (void)getData:(NSNotification *)notification {
	NSData *data = notification.userInfo[NSFileHandleNotificationDataItem];
	if (data.length) {
		NSString *string = [NSString.alloc initWithData:data encoding:NSUTF8StringEncoding];
        if (string && textView) {
            textView.editable = YES;
            textView.text = [textView.text stringByAppendingString:string];
            textView.editable = NO;
        }
		double delayInSeconds = 0.1;
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
		dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
		    [self scrollToLast];
		});
	}
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:currentLogPath error:NULL];
    NSUInteger size = [[fileAttributes objectForKey:NSFileSize] integerValue];
    if (size > FILE_SIZE_LIMIT) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleReadCompletionNotification object:notification.object];
        [self rollFileAtPath:AKS_LOG_DIR];
        NSDateFormatter *formatter = [NSDateFormatter new];
        formatter.dateFormat = @"yyyy-MM-dd-HH-mm-ss";
        formatter.timeZone = [NSTimeZone systemTimeZone];
        formatter.locale = [NSLocale autoupdatingCurrentLocale];
        NSString *formattedDate = [formatter stringFromDate:[NSDate date]];
        formattedDate = [formattedDate stringByAppendingString:@".txt"];
        currentLogPath = [AKS_LOG_DIR stringByAppendingPathComponent:formattedDate];
        freopen([currentLogPath fileSystemRepresentation], "a", stderr);
        freopen([currentLogPath fileSystemRepresentation], "a", stdout);
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:currentLogPath];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(getData:) name:NSFileHandleReadCompletionNotification object:fileHandle];
        [fileHandle readInBackgroundAndNotify];
    } else {
        if (data.length) {
            [self performSelector:@selector(refreshLog:) withObject:notification afterDelay:0.1];
        } else {
            [self performSelector:@selector(refreshLog:) withObject:notification afterDelay:0.5];
        }
    }
}

- (void)refreshLog:(NSNotification *)notification {
	[notification.object readInBackgroundAndNotify];
}

- (void)rollFileAtPath:(NSString *)path {
    NSString *dir = path;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator<NSString *> *enumerator = [fileManager enumeratorAtPath:dir];
    NSMutableArray *files = [NSMutableArray new];
    NSMutableArray *attributes = [NSMutableArray new];
    for (NSString *path in enumerator) {
        [files addObject:path];
    }
    if (files.count <= MAXIMUM_NUMBER_LOG+1) {
        return;
    }
    NSArray *filesResults = [files sortedArrayUsingComparator:^NSComparisonResult(NSString *path1, NSString *path2) {
        NSDictionary *fileAttributes1 = [fileManager attributesOfItemAtPath:[dir stringByAppendingPathComponent:path1] error:NULL];
        NSDictionary *fileAttributes2 = [fileManager attributesOfItemAtPath:[dir stringByAppendingPathComponent:path2] error:NULL];
        NSDate *date1 = fileAttributes1[NSFileModificationDate];
        NSDate *date2 = fileAttributes2[NSFileModificationDate];
        return [date2 compare:date1];
    }];
    NSUInteger count = filesResults.count;
    for (NSString *path in filesResults.reverseObjectEnumerator) {
        if (count > MAXIMUM_NUMBER_LOG+1) {
            NSError *error;
            [fileManager removeItemAtPath:[dir stringByAppendingPathComponent:path] error:&error];
            if (error) {
                ZMLogError(@"removeItemAtPath error");
            }
            count--;
        } else {
            break;
        }
    }
}

- (void)hideThisViewWithAnimation:(UIView *)view duration:(float)dur; {
	[UIView animateWithDuration:dur animations: ^{
	    [view setFrame:CGRectMake([[UIScreen mainScreen]bounds].size.width, 0, view.frame.size.width, view.frame.size.height)];
        shareButton.hidden = YES;
	} completion: ^(BOOL finished) {}];
}
- (void)showThisViewWithAnimation:(UIView *)view duration:(float)dur; {
	CGRect original = [view frame];
	[view setFrame:CGRectMake([[UIScreen mainScreen] bounds].size.width, 0, view.frame.size.width, view.frame.size.height)];
	[UIView animateWithDuration:dur animations: ^{
#ifdef DEBUG
	    [view setFrame:original];
#else
        [view setFrame:CGRectMake([[UIScreen mainScreen] bounds].size.width, 0, 1, view.frame.size.height)];
#endif
        shareButton.hidden = NO;
	} completion: ^(BOOL finished) {}];
}
- (UIWindow *)window {
    if (_window) {
        return _window;
    }
    _window = UIApplication.sharedApplication.keyWindow;
    if (!_window) _window = UIApplication.sharedApplication.windows.lastObject;
    return _window;
}

@end
