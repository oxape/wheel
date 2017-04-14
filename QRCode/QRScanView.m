//
//  QRScanView.m
//  sunaccess
//
//  Created by oxape on 2017/4/13.
//  Copyright © 2017年 oxape. All rights reserved.
//

#import "QRScanView.h"

@interface QRScanView ()

@property (nonatomic, assign) CGRect region;

@end

@implementation QRScanView

- (instancetype)initWithRegion:(CGRect)region {
    if (self = [super initWithFrame:CGRectZero]) {
        _region = region;
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    [[[UIColor blackColor] colorWithAlphaComponent:0.5] setFill];
    
    CGContextAddRect(context, rect);
    CGContextFillPath(context);
    CGContextClearRect(context, self.region);
    
    [[UIColor whiteColor] setStroke];
    CGContextAddRect(context, self.region);
    CGContextStrokePath(context);
    CGRect region = self.region;
    
    CGFloat length = 16;
    CGFloat lineWidth = 6;
    CGFloat rectLineWidth = 0.5;
    [[UIColor orangeColor] setStroke];
    CGContextMoveToPoint(context, CGRectGetMinX(region)-lineWidth/2-rectLineWidth, CGRectGetMinY(region)+length);
    CGContextAddLineToPoint(context, CGRectGetMinX(region)-lineWidth/2-rectLineWidth, CGRectGetMinY(region)-lineWidth/2-rectLineWidth);
    CGContextAddLineToPoint(context, CGRectGetMinX(region)+length, CGRectGetMinY(region)-lineWidth/2-rectLineWidth);
    
    CGContextMoveToPoint(context, CGRectGetMinX(region)-lineWidth/2-rectLineWidth, CGRectGetMaxY(region)-length);
    CGContextAddLineToPoint(context, CGRectGetMinX(region)-lineWidth/2-rectLineWidth, CGRectGetMaxY(region)+lineWidth/2+rectLineWidth);
    CGContextAddLineToPoint(context, CGRectGetMinX(region)+length, CGRectGetMaxY(region)+lineWidth/2+rectLineWidth);
    
    CGContextMoveToPoint(context, CGRectGetMaxX(region)+lineWidth/2+rectLineWidth, CGRectGetMinY(region)+length);
    CGContextAddLineToPoint(context, CGRectGetMaxX(region)+lineWidth/2+rectLineWidth, CGRectGetMinY(region)-lineWidth/2-rectLineWidth);
    CGContextAddLineToPoint(context, CGRectGetMaxX(region)-length, CGRectGetMinY(region)-lineWidth/2-rectLineWidth);
    
    CGContextMoveToPoint(context, CGRectGetMaxX(region)+lineWidth/2+rectLineWidth, CGRectGetMaxY(region)-length);
    CGContextAddLineToPoint(context, CGRectGetMaxX(region)+lineWidth/2+rectLineWidth, CGRectGetMaxY(region)+lineWidth/2+rectLineWidth);
    CGContextAddLineToPoint(context, CGRectGetMaxX(region)-length, CGRectGetMaxY(region)+lineWidth/2+rectLineWidth);
    
    CGContextSetLineWidth(context, lineWidth);
    CGContextStrokePath(context);
}

@end
