//
//  OXPUploadManager.m
//
//  Created by oxape on 2018/1/18.
//

#import "OXPUploadManager.h"
#import "OXPWorkQueue.h"
#import "OXPWorkOperation.h"
#import <MJExtension/MJExtension.h>

@interface OXPUploadManager()

@property (nonatomic, strong) OXPWorkQueue *workQueue;

@end

@implementation OXPUploadManager

static NSString *kQueueOperationsChanged = @"kQueueOperationsChanged";
static OXPUploadManager *_sharedObject = nil;

+ (instancetype)sharedManager {
    static dispatch_once_t p = 0;
    dispatch_once(&p, ^{
        _sharedObject = [[OXPUploadManager alloc] init];
    });
    return _sharedObject;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.workQueue = [[OXPWorkQueue alloc] init];
        [self.workQueue addObserver:self forKeyPath:@"operationCount" options:NSKeyValueObservingOptionNew context:&kQueueOperationsChanged];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeOnlyWifiUploadNotification) name:CHANGE_ONLYWIFIUPLOAD_NOTIFICATION object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeNetWorkNotification) name:CHANGEZMNETWORKSTATE_NOTIFICATION object:nil];
        
        /*
        判断网络状态确定是否需要上次启动前的数据
        */
         
    }
    return self;
}

- (void)changeNetWorkNotification {
    //判断网络状态
}

- (void)addUploadJob:(id)message {
    if (self.wantUpload) {
        [self uploadJobForAnyNetworkStatus:message];
    } else {
        [self uploadJobForAnyNetworkStatus:message];
    }
}

- (void)uploadJobForAnyNetworkStatus:(id)message {
    OXPLogDebug(@"添加上传任务");
    
    NSString *info = [message mj_JSONString];
    NSInteger create_time = message.timestamp;
    OXPWorkOperation *operation = [OXPWorkOperation operationWithBlock:^oxpWorkQueueCancelBlock(oxpWorkQueueNoParamsBlock done, oxpWorkQueueNoParamsBlock retry) {
        NSURLSessionDataTask *task = [service.sessionManager POST:@"/path/to/api" parameters:@{@"info": info, @"createtime": @(create_time)} constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
            NSError *error;
            [formData appendPartWithFileURL:@"/url/to/file" name:@"file" error:&error];
        } progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            OXPLogDebug(@"success upload %@", message);
            done();
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            OXPLogDebug(@"failure upload %@", message);
            if (/*没有网络直接完成*/) {
                OXPLogDebug(@"没有网络");
                done();
            } else {
                retry();
            }
        }];
        return ^{
            OXPLogDebug(@"cancel upload %@", message);
            [task cancel];
        };
    } retryTimes:2];
    [self.workQueue addOperation:operation];
}

- (void)cancelAllJob {
    OXPLogDebug(@"取消所有上传任务");
    [self.workQueue cancelAllOperations];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                         change:(NSDictionary *)change context:(void *)context {
    if (object == self.workQueue && [keyPath isEqualToString:@"operationCount"] && context == &kQueueOperationsChanged) {
        OXPLogDebug(@"operationCount = %li", self.workQueue.operationCount);
        if (self.workQueue.operationCount == 0) {
            // Do something here when your queue has completed
            OXPLogDebug(@"queue has completed");
            self.wantUpload = NO;
            if (self.allOperationsComplete) {
                self.allOperationsComplete();
                self.allOperationsComplete = nil;
            }
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object
                               change:change context:context];
    }
}

- (void)changeOnlyWifiUploadNotification {
    /*
    if (!userModel.IsOnlyWifiUpload) {
        OXPLogDebug(@"关闭 仅在wifi下上传");
        [self judgeUnUploadMessage];
    } else if (userModel.IsOnlyWifiUpload) {
        OXPLogDebug(@"开启 仅在wifi下上传");
        [self cancelAllJob];
    }
    */
}

@end
