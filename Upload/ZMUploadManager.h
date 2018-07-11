//
//  ZMUploadManager.h
//  ZMSpark
//
//  Created by zm on 2018/1/18.
//  Copyright © 2018年 Funky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZMDialogMessage.h"
#import "ZMWorkQueue.h"

@interface ZMUploadManager : NSObject

@property (nonatomic, strong, readonly) ZMWorkQueue *workQueue;
//FIXME:改成回调数组
@property (nonatomic, strong) void (^allOperationsComplete)(void);

@property (nonatomic, assign) BOOL wantUpload;

+ (instancetype)sharedManager;

- (void)addUploadJob:(ZMDialogMessage *)message;
- (void)uploadJobForAnyNetworkStatus:(ZMDialogMessage *)message;
- (void)cancelAllJob;

@end
