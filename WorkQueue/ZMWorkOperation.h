//
//  ZMWorkOperation.h
//  BDSClientSample
//
//  Created by oxape on 2018/1/3.
//  Copyright © 2018年 zy. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^zmWorkQueueNoParamsBlock)(void);
typedef void (^zmWorkQueueCancelBlock)(void);;

@interface ZMWorkOperation : NSOperation

+ (ZMWorkOperation *)operationWithBlock:(zmWorkQueueCancelBlock (^)(zmWorkQueueNoParamsBlock done, zmWorkQueueNoParamsBlock retry))block retryTimes:(NSInteger)retryTimes;

@end
