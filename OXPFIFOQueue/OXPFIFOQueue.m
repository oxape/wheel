//
//  OXPFIFOQueue.m
//  ygnews
//
//  Created by oxape on 2017/3/31.
//  Copyright © 2017年 oxape. All rights reserved.
//

#import "OXPFIFOQueue.h"
#import "OXPFIFOOperation.h"

@interface OXPFIFOQueue ()

@property (nonatomic, strong) NSMutableArray *queues;
@property (nonatomic, strong) dispatch_queue_t barrierQueue;

@end

@implementation OXPFIFOQueue

static OXPFIFOQueue *_defaultQueue = nil;

+ (instancetype)defaultQueue
{
    static dispatch_once_t p = 0;
    dispatch_once(&p, ^{
        _defaultQueue = [[OXPFIFOQueue alloc] init];
    });
    // returns the same object each time
    return _defaultQueue;
}

- (instancetype)init {
    if (self = [super init]) {
        //将queue变为串行队列
        self.maxConcurrentOperationCount = 1;
    }
    return self;
}

- (void)executeBlock:(void (^)())block{
    [self executeBlock:block afterDelay:0];
}

- (void)executeBlock:(void (^)())block afterDelay:(CFTimeInterval)delay {
    [self executeBlock:block afterDelay:delay inQueue:dispatch_get_main_queue()];
}

- (void)executeBlock:(void (^)())block afterDelay:(CFTimeInterval)delay inQueue:(dispatch_queue_t)queue {
    OXPFIFOOperation *operation = [OXPFIFOOperation blockOperationWithBlock:block afterDelay:delay inQueue:queue];
    [self addOperation:operation];
}

@end
