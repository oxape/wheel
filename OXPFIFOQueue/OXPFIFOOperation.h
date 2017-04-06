//
//  OXPFIFOOperation.h
//  ygnews
//
//  Created by oxape on 2017/3/31.
//  Copyright © 2017年 oxape. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OXPFIFOOperation : NSOperation

+ (instancetype)blockOperationWithBlock:(void (^)())block afterDelay:(CFTimeInterval)delay inQueue:(dispatch_queue_t)queue;

- (instancetype)initWithBlock:(void (^)())block afterDelay:(CFTimeInterval)delay inQueue:(dispatch_queue_t)queue;

@end
