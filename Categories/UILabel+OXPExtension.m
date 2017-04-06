//
//  UILabel+OXPExtension.m
//  ygnews
//
//  Created by oxape on 2017/3/17.
//  Copyright © 2017年 oxape. All rights reserved.
//

#import "UILabel+OXPExtension.h"

@implementation UILabel (OXPExtension)

+ (UILabel *)labelUsingFont:(UIFont *)font textColor:(UIColor *)textColor textAlignment:(NSTextAlignment)textAlignment {
    UILabel *label = [UILabel new];
    label.font = font;
    label.textColor = textColor;
    label.textAlignment = textAlignment;
    return label;
}

@end
