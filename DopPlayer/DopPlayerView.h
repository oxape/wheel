//
//  DopPlayerView.h
//  iosmanew
//
//  Created by oxape on 16/6/7.
//  Copyright © 2016年 oxape. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DopPlayerContainerView.h"
#import "DopPlayerBar.h"

@interface DopPlayerView : UIView

@property (nonatomic, strong) DopPlayerContainerView *playerContainer;
@property (nonatomic, strong) DopPlayerBar *playerBar;

@property (nonatomic, assign, getter=isFullScreen) BOOL fullScreen;

- (void)setCustomView:(UIView *)customView animated:(BOOL)animated coverBar:(BOOL)cover;

@end
