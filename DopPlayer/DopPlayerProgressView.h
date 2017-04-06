//
//  DopPlayerProgressView.h
//  iosmanew
//
//  Created by oxape on 16/6/10.
//  Copyright © 2016年 oxape. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DopPlayerProgressView : UIView

@property (nonatomic, assign) NSUInteger currentSeconds;
@property (nonatomic, assign) NSUInteger totalSeconds;
@property (nonatomic, assign) NSUInteger cacheSeconds;

@property (nonatomic, copy) void(^seekToBlock)(NSUInteger seconds);

@end
