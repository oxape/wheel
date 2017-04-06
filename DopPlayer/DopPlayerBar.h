//
//  DopPlayerBar.h
//  iosmanew
//
//  Created by oxape on 16/6/29.
//  Copyright © 2016年 oxape. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DopPlayerBar : UIView

@property (nonatomic, copy) void (^downloadBlock)();
@property (nonatomic, copy) void (^starBlock)(BOOL);
@property (nonatomic, assign) BOOL favorited;

@property (nonatomic, strong) NSString *tipText;

@end
