//
//  DopPlayerContainerView.h
//  iosmanew
//
//  Created by oxape on 16/3/3.
//  Copyright © 2016年 oxape. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DopPlayerProgressView.h"

@interface DopPlayerContainerView : UIView

@property (nonatomic, strong) CALayer *playLayer;
@property (nonatomic, strong, readonly) DopPlayerProgressView *progressView;

@property (nonatomic, assign, getter=isPlay) BOOL play;
@property (nonatomic, assign, getter=isFullScreen) BOOL fullScreen;
@property (nonatomic, assign, getter=isLock) BOOL lock;

@property (nonatomic, copy) void (^playBlock)(BOOL isPlay);
@property (nonatomic, copy) void(^nextBlock)();
@property (nonatomic, copy) void(^fullScreenBlock)(BOOL isFull);

@property (nonatomic, copy) void(^lockBlock)(BOOL isLock);

@property (nonatomic, copy) void(^navBlock)();

- (void)setTitle:(NSString *)title;

@end
