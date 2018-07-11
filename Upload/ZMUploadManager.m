//
//  ZMUploadManager.m
//  ZMSpark
//
//  Created by zm on 2018/1/18.
//  Copyright © 2018年 Funky. All rights reserved.
//

#import "ZMUploadManager.h"
#import "ZMRequestService.h"
#import "ZMWorkQueue.h"
#import "ZMWorkOperation.h"
#import <MJExtension/MJExtension.h>
#import "ZMStorageManager.h"
#import "ZMHSLoginViewModel.h"
#import "NotificationDefs.h"


@interface ZMUploadManager()

@property (nonatomic, strong) ZMWorkQueue *workQueue;

@end

@implementation ZMUploadManager

static NSString *kQueueOperationsChanged = @"kQueueOperationsChanged";
static ZMUploadManager *_sharedObject = nil;

+ (instancetype)sharedManager {
    static dispatch_once_t p = 0;
    dispatch_once(&p, ^{
        _sharedObject = [[ZMUploadManager alloc] init];
    });
    return _sharedObject;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.workQueue = [[ZMWorkQueue alloc] init];
        [self.workQueue addObserver:self forKeyPath:@"operationCount" options:NSKeyValueObservingOptionNew context:&kQueueOperationsChanged];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeOnlyWifiUploadNotification) name:CHANGE_ONLYWIFIUPLOAD_NOTIFICATION object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeNetWorkNotification) name:CHANGEZMNETWORKSTATE_NOTIFICATION object:nil];
        
        ZMHSUserModel *userModel = [ZMHSLoginViewModel shareInstance].userModel;
        ZMNetworkState networkStatus = [ZMRequestService defaultManager].networkStatus;
        if ((!userModel.IsOnlyWifiUpload) || (userModel.IsOnlyWifiUpload && networkStatus == ZMNetworkState_WiFi)) {
            [self judgeUnUploadMessage];
        }
         
    }
    return self;
}

- (void)changeNetWorkNotification {
    ZMNetworkState networkStatus = [ZMRequestService defaultManager].networkStatus;
    switch (networkStatus) {
        case ZMNetworkState_WiFi: {
            ZMLogDebug(@"切换到wifi状态下");
            [self judgeUnUploadMessage];
        }
            break;
        case ZMNetworkState_WWAN: {
            ZMLogDebug(@"切换到手机网络状态下");
            if (self.wantUpload) {
                [self judgeUnUploadMessage];
            } else {
                if (![ZMHSLoginViewModel shareInstance].userModel.IsOnlyWifiUpload && self.workQueue.operationCount == 0) {
                    [self judgeUnUploadMessage];
                } else if ([ZMHSLoginViewModel shareInstance].userModel.IsOnlyWifiUpload){
                    [self cancelAllJob];
                }
            }
        }
            break;
        default: {
            [self cancelAllJob];
        }
            break;
    }    
}

- (void)judgeUnUploadMessage {
    NSArray<ZMDialogMessage *> *messages = [ZMDialogMessage queryMessagesNoRemotePath];
    if (!IsEmptyArr(messages)) {
        ZMLogDebug(@"有需要上传的Message");
        for (ZMDialogMessage *message in messages) {
            [self addUploadJob:message];
        }
    }
}

- (void)addUploadJob:(ZMDialogMessage *)message {
    
    if (self.wantUpload) {
        
        [self uploadJobForAnyNetworkStatus:message];
        
    } else {
        
        if ([ZMHSLoginViewModel shareInstance].userModel.IsOnlyWifiUpload && [ZMRequestService defaultManager].networkStatus != ZMNetworkState_WiFi) {
            ZMLogDebug(@"非wifi环境下不可上传任务");
            return;
        }
        [self uploadJobForAnyNetworkStatus:message];
    }
}

- (void)uploadJobForAnyNetworkStatus:(ZMDialogMessage *)message {
    ZMLogDebug(@"添加上传任务");

    if (message.messageType != ZMDialogMessageTypeText) {
        return;
    }
    
    NSString *info = [message mj_JSONString];
    NSInteger create_time = message.timestamp;
    ZMRequestService *service = [ZMRequestService defaultManager];
    ZMWorkOperation *operation = [ZMWorkOperation operationWithBlock:^zmWorkQueueCancelBlock(zmWorkQueueNoParamsBlock done, zmWorkQueueNoParamsBlock retry) {
        NSURLSessionDataTask *task = [service.sessionManager POST:@"v1/api/translate/result" parameters:@{@"info": info, @"createtime": @(create_time)} constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
            NSError *error;
            [formData appendPartWithFileURL:[[ZMStorageManager sharedManager] fileURLForPath:message.srcPath] name:@"src" error:&error];
            if (error) {
                ZMLogError(@"src path error = %@", error);
            }
            if (message.resourcePath.length) {
                [formData appendPartWithFileURL:[[ZMStorageManager sharedManager] fileURLForPath:message.resourcePath] name:@"dest" error:&error];
                if (error) {
                    ZMLogError(@"dest path error = %@", error);
                }
            } else {
                ZMLogWarn(@"addUploadJob resourcePath = nil");
            }
        } progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            ZMLogDebug(@"success upload %@", message);
            if ([responseObject isKindOfClass:[NSDictionary class]]) {
                if (responseObject[@"result"] && [responseObject[@"result"] isKindOfClass:[NSDictionary class]]) {
                    if (responseObject[@"result"][@"dest"] && [responseObject[@"result"][@"dest"] isKindOfClass:[NSString class]]) {
                        [message updateRemotePath:responseObject[@"result"][@"dest"]];
                    }
                    if (responseObject[@"result"][@"src"] && [responseObject[@"result"][@"src"] isKindOfClass:[NSString class]]) {
                        [message updateSrcRemotePath:responseObject[@"result"][@"src"]];
                    }
                    if (responseObject[@"result"][@"bucket"] && [responseObject[@"result"][@"bucket"] isKindOfClass:[NSString class]]) {
                        [message updateBucket:responseObject[@"result"][@"bucket"]];
                    }
                }
            }
            done();
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            ZMLogDebug(@"failure upload %@", message);
            if ([ZMRequestService defaultManager].networkStatus == ZMNetworkState_NoNetWork) {
                ZMLogDebug(@"没有网络");
                done();
            } else {
                retry();
            }
        }];
        return ^{
            ZMLogDebug(@"cancel upload %@", message);
            [task cancel];
        };
    } retryTimes:2];
    [self.workQueue addOperation:operation];
}

- (void)cancelAllJob {
    ZMLogDebug(@"取消所有上传任务");
    [self.workQueue cancelAllOperations];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                         change:(NSDictionary *)change context:(void *)context {
    if (object == self.workQueue && [keyPath isEqualToString:@"operationCount"] && context == &kQueueOperationsChanged) {
        ZMLogDebug(@"operationCount = %li", self.workQueue.operationCount);
        if (self.workQueue.operationCount == 0) {
            // Do something here when your queue has completed
            ZMLogDebug(@"queue has completed");
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
    
    ZMHSUserModel *userModel = [ZMHSLoginViewModel shareInstance].userModel;
    if (!userModel.IsOnlyWifiUpload) {
        ZMLogDebug(@"关闭 仅在wifi下上传");
        [self judgeUnUploadMessage];
    } else if (userModel.IsOnlyWifiUpload) {
        ZMLogDebug(@"开启 仅在wifi下上传");
        [self cancelAllJob];
    }
}

@end
