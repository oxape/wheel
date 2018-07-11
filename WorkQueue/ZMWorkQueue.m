//
//  ZMWorkQueue.m
//  BDSClientSample
//
//  Created by oxape on 2018/1/3.
//  Copyright © 2018年 zy. All rights reserved.
//

#import "ZMWorkQueue.h"

@implementation ZMWorkQueue

- (instancetype)init {
    self = [super init];
    if (self) {
        self.maxConcurrentOperationCount = 4;
    }
    return self;
}

@end
