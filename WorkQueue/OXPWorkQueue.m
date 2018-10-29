//
//  OXPWorkQueue.m
//
//  Created by oxape on 2018/1/3.
//

#import "OXPWorkQueue.h"

@implementation OXPWorkQueue

- (instancetype)init {
    self = [super init];
    if (self) {
        self.maxConcurrentOperationCount = 4;
    }
    return self;
}

@end
