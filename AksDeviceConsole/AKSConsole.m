//
//  AKSConsole.m
//  ZMSpark
//
//  Created by oxape on 2018/3/20.
//  Copyright © 2018年 zhuomi. All rights reserved.
//

#import "AKSConsole.h"
#import "AKSDeviceConsole.h"

@interface AKSConsole () {
}
@property (nonatomic) BOOL isShowing;
@property (nonatomic) BOOL isDisabled;
@property (nonatomic, weak) UIWindow *window;
@property (nonatomic) NSMapTable *windowsWithGesturesAttached;
@property (nonatomic) AKSInvocationGestureMask invocationGestures;
@property (nonatomic) NSUInteger invocationGesturesTouchCount;

@end

@implementation AKSConsole

+ (instancetype)sharedManager
{
    static dispatch_once_t onceToken;
    static AKSConsole *sharedManager;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

+ (void)enableWithNumberOfTouches:(NSUInteger)fingerCount performingGestures:(AKSInvocationGestureMask)invocationGestures;
{
    if (AKSConsole.sharedManager.isDisabled) return;
    AKSConsole.sharedManager.invocationGestures = invocationGestures;
    AKSConsole.sharedManager.invocationGesturesTouchCount = fingerCount;
    
    // dispatched to next main-thread loop so the app delegate has a chance to set up its window
    dispatch_async(dispatch_get_main_queue(), ^{
        [AKSConsole.sharedManager ensureWindow];
        [AKSConsole.sharedManager attachToWindow:AKSConsole.sharedManager.window];
    });
}

+ (void)show
{
    [AKSConsole.sharedManager ensureWindow];
    [AKSConsole.sharedManager handleOpenGesture:nil];
}

- (instancetype)init
{
    if ( (self = [super init]) ) {
        if ([self.class isProbablyAppStoreBuild]) {
            self.isDisabled = YES;
            NSLog(@"[BugshotKit] App Store build detected. BugshotKit is disabled.");
            return self;
        }
        self.windowsWithGesturesAttached = [NSMapTable weakToWeakObjectsMapTable];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(newWindowDidBecomeVisible:) name:UIWindowDidBecomeVisibleNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self name:UIWindowDidBecomeVisibleNotification object:nil];
}

- (void)ensureWindow
{
    if (self.window) return;
    
    self.window = UIApplication.sharedApplication.keyWindow;
    if (! self.window) self.window = UIApplication.sharedApplication.windows.lastObject;
    if (! self.window) [[NSException exceptionWithName:NSGenericException reason:@"BugshotKit cannot find any application windows" userInfo:nil] raise];
    if (! self.window.rootViewController) [[NSException exceptionWithName:NSGenericException reason:@"BugshotKit requires a rootViewController set on the window" userInfo:nil] raise];
}

- (void)newWindowDidBecomeVisible:(NSNotification *)n
{
    UIWindow *newWindow = (UIWindow *) n.object;
    if (! newWindow || ! [newWindow isKindOfClass:UIWindow.class]) return;
    [self attachToWindow:newWindow];
}

- (void)attachToWindow:(UIWindow *)window
{
    [[AKSDeviceConsole sharedInstance] hideConsole];
    if (self.isDisabled) return;
    
    if ([self.windowsWithGesturesAttached objectForKey:window]) return;
    [self.windowsWithGesturesAttached setObject:window forKey:window];
    
    AKSInvocationGestureMask invocationGestures = self.invocationGestures;
    NSUInteger fingerCount = self.invocationGesturesTouchCount;
    
    if (invocationGestures & (AKSInvocationGestureSwipeUp | AKSInvocationGestureSwipeDown)) {
        // Need to actually handle all four directions to work with rotation, since we're attaching right to the window (which doesn't autorotate).
        // Making four different GRs, rather than one with all four directions set, so it's possible to distinguish which direction was swiped in the action method.
        //
        // (dealing with rotation is awesome)
        
        UISwipeGestureRecognizer *sgr = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleOpenGesture:)];
        sgr.numberOfTouchesRequired = fingerCount;
        sgr.direction = UISwipeGestureRecognizerDirectionUp;
        sgr.delegate = self;
        [window addGestureRecognizer:sgr];
        
        sgr = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleOpenGesture:)];
        sgr.numberOfTouchesRequired = fingerCount;
        sgr.direction = UISwipeGestureRecognizerDirectionDown;
        sgr.delegate = self;
        [window addGestureRecognizer:sgr];
        
        sgr = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleOpenGesture:)];
        sgr.numberOfTouchesRequired = fingerCount;
        sgr.direction = UISwipeGestureRecognizerDirectionLeft;
        sgr.delegate = self;
        [window addGestureRecognizer:sgr];
        
        sgr = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleOpenGesture:)];
        sgr.numberOfTouchesRequired = fingerCount;
        sgr.direction = UISwipeGestureRecognizerDirectionRight;
        sgr.delegate = self;
        [window addGestureRecognizer:sgr];
        
        if (invocationGestures & AKSInvocationGestureSwipeUp) NSLog(@"[AKSConsole] Enabled for %d-finger swipe up.", (int) fingerCount);
        if (invocationGestures & AKSInvocationGestureSwipeDown) NSLog(@"[AKSConsole] Enabled for %d-finger swipe down.", (int) fingerCount);
    }
    
    if (invocationGestures & AKSInvocationGestureSwipeFromRightEdge) {
        // Similar deal with these (see swipe recognizers above), but screen-edge gesture recognizers always return 0 upon reading the .edges property.
        // I guess it's write-only. So we actually need four different action methods to know which one was invoked.
        
        UIScreenEdgePanGestureRecognizer *egr = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(topEdgePanGesture:)];
        egr.edges = UIRectEdgeTop;
        egr.minimumNumberOfTouches = fingerCount;
        egr.maximumNumberOfTouches = fingerCount;
        egr.delegate = self;
        [window addGestureRecognizer:egr];
        
        egr = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(bottomEdgePanGesture:)];
        egr.edges = UIRectEdgeBottom;
        egr.minimumNumberOfTouches = fingerCount;
        egr.maximumNumberOfTouches = fingerCount;
        egr.delegate = self;
        [window addGestureRecognizer:egr];
        
        egr = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(leftEdgePanGesture:)];
        egr.edges = UIRectEdgeLeft;
        egr.minimumNumberOfTouches = fingerCount;
        egr.maximumNumberOfTouches = fingerCount;
        egr.delegate = self;
        [window addGestureRecognizer:egr];
        
        egr = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(rightEdgePanGesture:)];
        egr.edges = UIRectEdgeRight;
        egr.minimumNumberOfTouches = fingerCount;
        egr.maximumNumberOfTouches = fingerCount;
        egr.delegate = self;
        [window addGestureRecognizer:egr];
        
        NSLog(@"[AKSConsole] Enabled for swipe from right edge.");
    }
    
    if (invocationGestures & AKSInvocationGestureDoubleTap) {
        UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleOpenGesture:)];
        tgr.numberOfTouchesRequired = fingerCount;
        tgr.numberOfTapsRequired = 2;
        tgr.delegate = self;
        [window addGestureRecognizer:tgr];
        NSLog(@"[AKSConsole] Enabled for %d-finger double-tap.", (int) fingerCount);
    }
    
    if (invocationGestures & AKSInvocationGestureTripleTap) {
        UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleOpenGesture:)];
        tgr.numberOfTouchesRequired = fingerCount;
        tgr.numberOfTapsRequired = 3;
        tgr.delegate = self;
        [window addGestureRecognizer:tgr];
        NSLog(@"[AKSConsole] Enabled for %d-finger triple-tap.", (int) fingerCount);
    }
    
    if (invocationGestures & AKSInvocationGestureLongPress) {
        UILongPressGestureRecognizer *tgr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleOpenGesture:)];
        tgr.numberOfTouchesRequired = fingerCount;
        tgr.delegate = self;
        [window addGestureRecognizer:tgr];
        NSLog(@"[AKSConsole] Enabled for %d-finger long press.", (int) fingerCount);
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer { return YES; }

- (void)leftEdgePanGesture:(UIScreenEdgePanGestureRecognizer *)egr
{
    if ([egr translationInView:self.window].x < 60) return;
    if (self.window.rootViewController.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) [self handleOpenGesture:egr];
}

- (void)rightEdgePanGesture:(UIScreenEdgePanGestureRecognizer *)egr
{
    if ([egr translationInView:self.window].x > -60) return;
    if (self.window.rootViewController.interfaceOrientation == UIInterfaceOrientationPortrait) [self handleOpenGesture:egr];
}

- (void)topEdgePanGesture:(UIScreenEdgePanGestureRecognizer *)egr
{
    if ([egr translationInView:self.window].y < 60) return;
    if (self.window.rootViewController.interfaceOrientation == UIInterfaceOrientationLandscapeLeft) [self handleOpenGesture:egr];
}

- (void)bottomEdgePanGesture:(UIScreenEdgePanGestureRecognizer *)egr
{
    if ([egr translationInView:self.window].y > -60) return;
    if (self.window.rootViewController.interfaceOrientation == UIInterfaceOrientationLandscapeRight) [self handleOpenGesture:egr];
}

- (void)handleOpenGesture:(UIGestureRecognizer *)sender
{
    UIInterfaceOrientation interfaceOrientation = self.window.rootViewController.interfaceOrientation;
    
    if (sender && [sender isKindOfClass:UISwipeGestureRecognizer.class]) {
        UISwipeGestureRecognizer *sgr = (UISwipeGestureRecognizer *)sender;
        
        BOOL validSwipe = NO;
        if (self.invocationGestures & AKSInvocationGestureSwipeUp) {
            if      (interfaceOrientation == UIInterfaceOrientationPortrait && sgr.direction == UISwipeGestureRecognizerDirectionUp) validSwipe = YES;
            else if (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown && sgr.direction == UISwipeGestureRecognizerDirectionDown) validSwipe = YES;
            else if (interfaceOrientation == UIInterfaceOrientationLandscapeLeft && sgr.direction == UISwipeGestureRecognizerDirectionLeft) validSwipe = YES;
            else if (interfaceOrientation == UIInterfaceOrientationLandscapeRight && sgr.direction == UISwipeGestureRecognizerDirectionRight) validSwipe = YES;
        }
        
        if (! validSwipe && (self.invocationGestures & AKSInvocationGestureSwipeDown)) {
            if      (interfaceOrientation == UIInterfaceOrientationPortrait && sgr.direction == UISwipeGestureRecognizerDirectionDown) validSwipe = YES;
            else if (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown && sgr.direction == UISwipeGestureRecognizerDirectionUp) validSwipe = YES;
            else if (interfaceOrientation == UIInterfaceOrientationLandscapeLeft && sgr.direction == UISwipeGestureRecognizerDirectionRight) validSwipe = YES;
            else if (interfaceOrientation == UIInterfaceOrientationLandscapeRight && sgr.direction == UISwipeGestureRecognizerDirectionLeft) validSwipe = YES;
        }
        
        if (! validSwipe) return;
    }
    [[AKSDeviceConsole sharedInstance] showConsole];
}

#pragma mark - App Store build detection

+ (BOOL)isProbablyAppStoreBuild
{
#if TARGET_IPHONE_SIMULATOR
    return NO;
#else
    // Adapted from https://github.com/blindsightcorp/BSMobileProvision
    
    NSString *binaryMobileProvision = [NSString stringWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"embedded" ofType:@"mobileprovision"] encoding:NSISOLatin1StringEncoding error:NULL];
    if (! binaryMobileProvision) return YES; // no provision
    
    NSScanner *scanner = [NSScanner scannerWithString:binaryMobileProvision];
    NSString *plistString;
    if (! [scanner scanUpToString:@"<plist" intoString:nil] || ! [scanner scanUpToString:@"</plist>" intoString:&plistString]) return YES; // no XML plist found in provision
    plistString = [plistString stringByAppendingString:@"</plist>"];
    
    NSData *plistdata_latin1 = [plistString dataUsingEncoding:NSISOLatin1StringEncoding];
    NSError *error = nil;
    NSDictionary *mobileProvision = [NSPropertyListSerialization propertyListWithData:plistdata_latin1 options:NSPropertyListImmutable format:NULL error:&error];
    if (error) return YES; // unknown plist format
    
    if (! mobileProvision || ! mobileProvision.count) return YES; // no entitlements
    
    if (mobileProvision[@"ProvisionsAllDevices"]) return NO; // enterprise provisioning
    
    if (mobileProvision[@"ProvisionedDevices"] && ((NSDictionary *)mobileProvision[@"ProvisionedDevices"]).count) return NO; // development or ad-hoc
    
    return YES; // expected development/enterprise/ad-hoc entitlements not found
#endif
}

@end
