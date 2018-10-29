//
//  OXPWorkOperation.h
//
//  Created by oxape on 2018/1/3.
//

#import <Foundation/Foundation.h>

typedef void (^oxpWorkQueueNoParamsBlock)(void);
typedef void (^oxpWorkQueueCancelBlock)(void);;

@interface OXPWorkOperation : NSOperation

+ (OXPWorkOperation *)operationWithBlock:(oxpWorkQueueCancelBlock (^)(oxpWorkQueueNoParamsBlock done, oxpWorkQueueNoParamsBlock retry))block retryTimes:(NSInteger)retryTimes;

@end
