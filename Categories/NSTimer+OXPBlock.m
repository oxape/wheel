//
//  NSTimer+OXPBlock.m
//  SkyOC
//
//  Created by oxape on 2015/12/11.
//  Copyright © 2015年 oxape. All rights reserved.
//

#import "NSTimer+OXPBlock.h"

@implementation NSTimer (OXPBlock)

+ (NSTimer *)oxp_scheduledTimerWithTimeInterval:(NSTimeInterval)inerval repeats:(BOOL)repeats block:(void (^)(NSTimer *timer))block{
    
    return [NSTimer scheduledTimerWithTimeInterval:inerval target:self selector:@selector(oxp_blcokTimeout:) userInfo:[block copy] repeats:repeats];
}

+ (void)oxp_blcokTimeout:(NSTimer *)timer {
    
    void (^block)(NSTimer *timer) = timer.userInfo;
    
    if (block) {
        block(timer);
    }
}
@end
