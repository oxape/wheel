//
//  ZYWorkOperation.m
//  BDSClientSample
//
//  Created by oxape on 2018/1/3.
//  Copyright © 2018年 zy. All rights reserved.
//

#import "ZMWorkOperation.h"

@interface ZMWorkOperation()

@property (nonatomic, assign, getter = isExecuting) BOOL executing;
@property (nonatomic, assign, getter = isFinished) BOOL finished;
@property (nonatomic, assign) NSInteger retryTimes;
@property (nonatomic, copy) zmWorkQueueCancelBlock (^workBlock)(zmWorkQueueNoParamsBlock done, zmWorkQueueNoParamsBlock retry);
@property (nonatomic, copy) void (^doneBlock)(void);
@property (nonatomic, copy) void (^retryBlock)(void);
@property (nonatomic, copy) void (^cancellBlock)(void);

@end

@implementation ZMWorkOperation

@synthesize executing = _executing;
@synthesize finished = _finished;
@synthesize cancelled = _cancelled;

+ (ZMWorkOperation *)operationWithBlock:(zmWorkQueueCancelBlock (^)(zmWorkQueueNoParamsBlock done, zmWorkQueueNoParamsBlock retry))block retryTimes:(NSInteger)retryTimes {
    ZMWorkOperation *operation = [[ZMWorkOperation alloc] initWithBlock:block retryTimes:(NSInteger)retryTimes];
    return operation;
}

- (instancetype)initWithBlock:(zmWorkQueueCancelBlock (^)(zmWorkQueueNoParamsBlock done, zmWorkQueueNoParamsBlock retry))block retryTimes:(NSInteger)retryTimes {
    self = [super init];
    if (self) {
        self.workBlock = block;
        self.retryTimes = retryTimes;
    }
    return self;
}

- (void)start {
    @synchronized (self) {
        if (self.isCancelled) {
            self.finished = YES;
            return;
        }
        __weak typeof(self) wself = self;
        self.doneBlock = ^{
            __strong typeof(wself) self = wself;
            self.finished = YES;
            self.executing = NO;
        };
        
        self.retryBlock = ^{
            __strong typeof(wself) self = wself;
            if (self.retryTimes == 0) {
                self.finished = YES;
                self.executing = NO;
            } else {
                self.retryTimes--;
                self.cancellBlock = [self doWork];
            }
        };
        self.executing = YES;
        self.cancellBlock = [self doWork];
    }
}

- (zmWorkQueueNoParamsBlock)doWork {
    return self.workBlock(self.doneBlock, self.retryBlock);
}

- (void)cancel {
    if (self.isFinished) return;
    [super cancel];
    
    if (self.cancellBlock) {
        self.cancellBlock();
        
        if (self.isExecuting) self.executing = NO;
        if (!self.isFinished) self.finished = YES;
    }
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
