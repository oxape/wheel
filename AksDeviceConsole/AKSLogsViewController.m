//
//  AKSLogsViewController.m
//  ZMSpark
//
//  Created by oxape on 2018/3/20.
//  Copyright © 2018年 zhuomi. All rights reserved.
//

#import "AKSLogsViewController.h"
#import "AKSDeviceConsole.h"
#import "ZipArchive.h"

#define AKS_LOG_DIR     [[AKSDeviceConsole documentsDirectory] stringByAppendingPathComponent:@"AKSLogs"]

@interface AKSLogsViewController ()<UITableViewDataSource, UITableViewDelegate, UIDocumentInteractionControllerDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *data;
@property (nonatomic, strong) NSArray *attributes;
@property (nonatomic, strong) UIDocumentInteractionController *fileInteractionController;

@end

@implementation AKSLogsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupViews];
    [self fetchData];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.navigationController.navigationBar.translucent = NO;
}

- (NSString *)title {
    return @"选择要分享的文件";
}

- (void)setupViews {
    UIView *superView = self.view;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消"     style:UIBarButtonItemStylePlain target:self action:@selector(cancel)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"分享全部"     style:UIBarButtonItemStylePlain target:self action:@selector(share)];
    
    UITableView *tableView = [UITableView new];
    [superView addSubview:tableView];
    tableView.frame = self.view.bounds;
    tableView.estimatedRowHeight = 44;//54为你估算的每个单元格的平均行高，方便系统计算滚动条大小等动作
    tableView.rowHeight = UITableViewAutomaticDimension;//实际值为-1,让系统自动计算Cell的行高。
    tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    tableView.dataSource = self;
    tableView.delegate = self;
    self.tableView = tableView;
}

- (void)fetchData {
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
    self.data = filesResults;
    self.attributes = attributes;
    [self.tableView reloadData];
}

/**
 *  打开共享菜单
 *
 *  @param file_url 文件路径
 */
-(void)openFileViewController: (NSString *) file_url  {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSURL *file_URL = [NSURL fileURLWithPath:file_url];
        
        if (file_URL != nil) {
            if (self.fileInteractionController == nil) {
                self.fileInteractionController = [[UIDocumentInteractionController alloc] init];
                
                self.fileInteractionController = [UIDocumentInteractionController interactionControllerWithURL:file_URL];
                self.fileInteractionController.delegate = self;
            }else {
                self.fileInteractionController.URL = file_URL;
            }
            CGRect navRect = self.navigationController.navigationBar.frame;
            
            navRect.size = CGSizeMake(1500.0f, 40.0f);
            
            if (![self.fileInteractionController presentOpenInMenuFromRect:navRect inView:self.view animated:YES]) {
                self.fileInteractionController = nil;
                [ZMProgressHUD showToastStatus:@"未安装可打开此文件的应用"];
            }
        }
    });
}

- (void)cancel {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)share {
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyy-MM-dd-HH-mm-ss";
    formatter.timeZone = [NSTimeZone systemTimeZone];
    formatter.locale = [NSLocale autoupdatingCurrentLocale];
    NSString *formattedDate = [formatter stringFromDate:[NSDate date]];
    NSString *logPath = [formattedDate stringByAppendingString:@".zip"];
    NSString *sharePath = [NSTemporaryDirectory() stringByAppendingPathComponent:logPath];
    [ZMProgressHUD showProgressIndicator];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *ppdd = [NSString stringWithFormat:@"%@", @"zhytek"];
        ppdd = [ppdd stringByAppendingString:@"_2018"];
        ppdd = [ppdd stringByAppendingString:@"2234"];
        BOOL success = [SSZipArchive createZipFileAtPath:sharePath withContentsOfDirectory:AKS_LOG_DIR keepParentDirectory:NO compressionLevel:0 password:ppdd AES:NO progressHandler:^(NSUInteger entryNumber, NSUInteger total) {
            ZMLogVerbose(@"%lu/%lu", entryNumber, total);
        }];
        [ZMProgressHUD dismissProgressStatus];
        if (success) {
            [self openFileViewController:sharePath];
        } else {
            [ZMProgressHUD showToastStatus:@"导出日志失败"];
        }
    });
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.data.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([self class])];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:NSStringFromClass([self class])];
    }
    cell.textLabel.text = self.data[indexPath.row];
    cell.textLabel.textColor = [UIColor blackColor];
    NSDate *date = self.attributes[indexPath.row][NSFileModificationDate];
    NSUInteger size = [self.attributes[indexPath.row][NSFileSize] integerValue];
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyy-MM-dd-HH-mm-ss";
    formatter.timeZone = [NSTimeZone systemTimeZone];
    formatter.locale = [NSLocale autoupdatingCurrentLocale];
    NSString *formattedDate = [formatter stringFromDate:date];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@(%.3fMb)", formattedDate, (float)size/1024/1024];
    cell.detailTextLabel.textColor = [UIColor grayColor];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *path = self.data[indexPath.row];
    NSString *dir = AKS_LOG_DIR;
    NSString *filePath = [dir stringByAppendingPathComponent:path];
    NSString *sharePath = filePath;
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyy-MM-dd-HH-mm-ss";
    formatter.timeZone = [NSTimeZone systemTimeZone];
    formatter.locale = [NSLocale autoupdatingCurrentLocale];
    NSString *formattedDate = [formatter stringFromDate:[NSDate date]];
    NSString *logPath = [formattedDate stringByAppendingString:@".zip"];
    sharePath = [NSTemporaryDirectory() stringByAppendingPathComponent:logPath];
    [ZMProgressHUD showProgressIndicator];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        SSZipArchive *zipArchive = [[SSZipArchive alloc] initWithPath:sharePath];
        BOOL success = [zipArchive open];
        if (success) {
            NSString *ppdd = [NSString stringWithFormat:@"%@", @"zhytek"];
            ppdd = [ppdd stringByAppendingString:@"_2018"];
            ppdd = [ppdd stringByAppendingString:@"2234"];
            success &= [zipArchive writeFileAtPath:filePath withFileName:nil compressionLevel:0 password:ppdd AES:NO];
            success &= [zipArchive close];
        }
        [ZMProgressHUD dismissProgressStatus];
        if (success) {
            [self openFileViewController:sharePath];
        } else {
            [ZMProgressHUD showToastStatus:@"导出日志失败"];
        }
    });
}

@end
