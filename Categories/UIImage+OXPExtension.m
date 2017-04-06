//
//  UIImage+OXPExtension.m
//  ygnews
//
//  Created by oxape on 2017/3/29.
//  Copyright © 2017年 oxape. All rights reserved.
//

#import "UIImage+OXPExtension.h"
#import "SDImageCache.h"
#import "SDWebImageDownloader.h"

@implementation UIImage (OXPExtension)

+ (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size {
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, size.width, size.height));
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}


@end
