//
//  NSArray+OXPExtension.m
//  ygnews
//
//  Created by oxape on 2017/4/5.
//  Copyright © 2017年 oxape. All rights reserved.
//

#import "NSArray+OXPExtension.h"
#import "Masonry.h"

@implementation NSArray (OXPExtension)

- (void)arrangeWithSpace:(CGFloat)space {
    if (self.count < 2) {
        return;
    }
    UIView *lastView = nil;
    for (UIView *view in self) {
        if (lastView == nil) {
            lastView = view;
            continue;
        }
        [view mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(lastView.mas_right).offset(space);
        }];
        lastView = view;
    }
}

@end
