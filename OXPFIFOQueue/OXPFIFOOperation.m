//
//  OXPFIFOOperation.m
//  ygnews
//
//  Created by oxape on 2017/3/31.
//  Copyright © 2017年 oxape. All rights reserved.
//

#import "OXPFIFOOperation.h"

@interface OXPFIFOOperation ()

@property (nonatomic, strong) void (^executeBlock)();
@property (nonatomic, assign) CFTimeInterval delay;
@property (nonatomic, strong) dispatch_queue_t queue;
@property (assign, nonatomic, getter = isExecuting) BOOL executing;
@property (assign, nonatomic, getter = isFinished) BOOL finished;

@end

@implementation OXPFIFOOperation

@synthesize executing = _executing;
@synthesize finished = _finished;

- (instancetype)initWithBlock:(void (^)())block afterDelay:(CFTimeInterval)delay inQueue:(dispatch_queue_t)queue {
    self = [super init];
    if (self) {
        self.executeBlock = block;
        self.delay = delay;
        self.queue = queue;
    }
    return self;
}

+ (instancetype)blockOperationWithBlock:(void (^)())block afterDelay:(CFTimeInterval)delay inQueue:(dispatch_queue_t)queue {
    OXPFIFOOperation *operation = [[OXPFIFOOperation alloc] initWithBlock:block afterDelay:delay inQueue:queue];
    return operation;
}

- (void)start {
    @synchronized (self) {
        if (self.isCancelled) {
            self.finished = YES;
            return;
        }
        dispatch_queue_t queue = self.queue?:dispatch_get_main_queue();
        if (self.delay > 0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, self.delay * NSEC_PER_SEC), queue, ^{
                if (self.executeBlock) {
                    self.executeBlock();
                }
                [self done];
            });
        } else {
            dispatch_async(queue, ^{
                if (self.executeBlock) {
                    self.executeBlock();
                }
                [self done];
            });
        }
    }
}

- (void)done {
    self.finished = YES;
    self.executing = NO;
}

- (void)setFinished:(BOOL)finished {
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)setExecuting:(BOOL)executing {
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

- (BOOL)isAsynchronous {
    return YES;
}

@end
