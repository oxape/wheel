//
//  UIView+OXPExtension.m
//  ygnews
//
//  Created by oxape on 2017/3/28.
//  Copyright © 2017年 oxape. All rights reserved.
//

#import "UIView+OXPExtension.h"

@implementation UIView (OXPExtension)

- (UIViewController *)oxp_viewController {
    for (UIView *next = self; next != nil; next = next.superview) {
        UIResponder *responder = next.nextResponder;
        if ([responder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)responder;
        }
    }
    
    return nil;
}

@end
