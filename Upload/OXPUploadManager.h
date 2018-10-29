//
//  OXPUploadManager.h
//
//  Created by oxape on 2018/1/18.
//

#import <Foundation/Foundation.h>
#import "OXPWorkQueue.h"

@interface OXPUploadManager : NSObject

@property (nonatomic, strong, readonly) OXPWorkQueue *workQueue;
//FIXME:改成回调数组
@property (nonatomic, strong) void (^allOperationsComplete)(void);

@property (nonatomic, assign) BOOL wantUpload;

+ (instancetype)sharedManager;

- (void)addUploadJob:(id)message;
- (void)uploadJobForAnyNetworkStatus:(id)message;
- (void)cancelAllJob;

@end
