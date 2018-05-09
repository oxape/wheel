//
//  AKSConsole.h
//  ZMSpark
//
//  Created by oxape on 2018/3/20.
//  Copyright © 2018年 zhuomi. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const AKSNewLogMessageNotification;


typedef enum : NSUInteger {
    AKSInvocationGestureNone        = 0,
    AKSInvocationGestureSwipeUp     = 1,
    AKSInvocationGestureSwipeDown   = (1 << 1),
    AKSInvocationGestureSwipeFromRightEdge = (1 << 2), // For whatever reason, this gesture recognizer always only needs one touch, regardless of your numberOfTouches setting.
    AKSInvocationGestureDoubleTap = (1 << 3),
    AKSInvocationGestureTripleTap = (1 << 4),
    AKSInvocationGestureLongPress = (1 << 5),
} AKSInvocationGestureMask;

@interface AKSConsole : NSObject <UIGestureRecognizerDelegate>

/*
 Call this from your UIApplication didFinishLaunching:... method.
 
 Optionally, multiple email addresses can be specified, separated by commas in the string.
 */
+ (void)enableWithNumberOfTouches:(NSUInteger)fingerCount performingGestures:(AKSInvocationGestureMask)invocationGestures;
/* You can also always show it manually */
+ (void)show;
+ (instancetype)sharedManager;

@end
