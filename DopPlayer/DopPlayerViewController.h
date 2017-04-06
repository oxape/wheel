//
//  DopPlayerViewController.h
//  iosmanew
//
//  Created by oxape on 16/6/2.
//  Copyright © 2016年 oxape. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DopPlayerBar.h"

@interface DopPlayerViewController : UIViewController

@property (nonatomic, strong) NSURL *videoURL;
@property (nonatomic, strong) NSString *videoTitle;
@property (nonatomic, strong, readonly) DopPlayerBar *playerBar;

- (void)setCustomView:(UIView*)customView;
- (void)setCustomView:(UIView *)customView animated:(BOOL)animate coverBar:(BOOL)cover;

@end
