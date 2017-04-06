//
//  OXPFIFOQueue.h
//  ygnews
//
//  Created by oxape on 2017/3/31.
//  Copyright © 2017年 oxape. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OXPFIFOQueue : NSOperationQueue

+ (instancetype)defaultQueue;
- (void)executeBlock:(void (^)())block;
- (void)executeBlock:(void (^)())block afterDelay:(CFTimeInterval)delay;
- (void)executeBlock:(void (^)())block afterDelay:(CFTimeInterval)delay inQueue:(dispatch_queue_t)queue;

@end
