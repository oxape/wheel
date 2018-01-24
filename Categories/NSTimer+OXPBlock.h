//
//  NSTimer+OXPBlock.h
//  SkyOC
//
//  Created by oxape on 2015/12/11.
//  Copyright © 2015年 oxape. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSTimer (OXPBlock)

+ (NSTimer *)oxp_scheduledTimerWithTimeInterval:(NSTimeInterval)inerval
                                        repeats:(BOOL)repeats
                                          block:(void(^)(NSTimer *timer))block;

@end
