//
//  DopPlayerProgressView.m
//  iosmanew
//
//  Created by oxape on 16/6/10.
//  Copyright © 2016年 oxape. All rights reserved.
//

#import "DopPlayerProgressView.h"

@interface DopPlayerProgressView ()

@property (nonatomic, assign, getter=isTrack) BOOL track;

@property (nonatomic, strong) UIView *slider;
@property (nonatomic, strong) UILabel *currentProgress;
@property (nonatomic, strong) UILabel *totalProgress;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) NSLayoutConstraint *progressConstraint;

@end

@implementation DopPlayerProgressView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initSubviews];
        [self setLayout];
    }
    return self;
}

- (void)initSubviews
{
    self.currentProgress = [[UILabel alloc] init];
    self.currentProgress.textColor = [UIColor whiteColor];
    self.currentProgress.font = [UIFont systemFontOfSize:12];
    self.currentProgress.textAlignment = NSTextAlignmentLeft;
    self.currentProgress.text = @"00:00";
    [self addSubview:self.currentProgress];
    
    self.totalProgress = [[UILabel alloc] init];
    self.totalProgress.textColor = [UIColor whiteColor];
    self.totalProgress.font = [UIFont systemFontOfSize:12];
    self.totalProgress.text = @"00:00";
    self.totalProgress.textAlignment = NSTextAlignmentRight;
    [self addSubview:self.totalProgress];
    
    self.progressView = [[UIProgressView alloc] init];
    self.progressView.trackTintColor = [UIColor colorWithWhite:0.9 alpha:0.5];
    self.progressView.progressTintColor = [UIColor colorWithWhite:0.2 alpha:0.5];
    [self addSubview:self.progressView];
    
    self.slider = [[UIView alloc] init];
    self.slider.backgroundColor = [UIColor whiteColor];
    self.slider.layer.cornerRadius = 4;
    self.slider.layer.masksToBounds = YES;
    [self addSubview:self.slider];
}

- (void)setLayout
{
    for (UIView *subview in self.subviews) {
        subview.translatesAutoresizingMaskIntoConstraints = NO;
    }
    
    NSDictionary *viewsDict = @{@"slider":self.slider, @"current":self.currentProgress, @"total":self.totalProgress, @"progress":self.progressView};
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[current(16)]-(>=0)-[progress(4)]-8-|" options:0 metrics:nil views:viewsDict]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[progress]-|" options:0 metrics:nil views:viewsDict]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[current(64)]-(>=8)-[total(64)]-|" options:NSLayoutFormatAlignAllTop|NSLayoutFormatAlignAllBottom metrics:nil views:viewsDict]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[slider(8)]" options:NSLayoutFormatAlignAllTop|NSLayoutFormatAlignAllBottom metrics:nil views:viewsDict]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[slider(8)]" options:NSLayoutFormatAlignAllTop|NSLayoutFormatAlignAllBottom metrics:nil views:viewsDict]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.slider attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.progressView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
    self.progressConstraint = [NSLayoutConstraint constraintWithItem:self.slider attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.progressView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0];
    [self addConstraint:self.progressConstraint];
}

- (void)setCurrentSeconds:(NSUInteger)currentSeconds
{
    _currentSeconds = currentSeconds;
    [self updateProgress];
}

- (void)setTotalSeconds:(NSUInteger)totalSeconds
{
    _totalSeconds = totalSeconds;
    [self updateProgress];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self updateProgress];
}

- (void)updateProgress
{
    if (self.totalSeconds < self.currentSeconds) {
        self.totalSeconds= self.currentSeconds;
    }
    if (self.totalSeconds != 0) {
        float progress = (float)self.currentSeconds/self.totalSeconds;
        [self.progressView setProgress:progress];
        if (!self.isTrack) {
            self.progressConstraint.constant = self.progressView.bounds.size.width*progress;
        }
    }else{
        [self.progressView setProgress:0];
        if (!self.isTrack) {
            self.progressConstraint.constant = 0;
        }
    }
    if (!self.isTrack) {
        [self.currentProgress setText:[self stringFromSecond:self.currentSeconds]];
    }
    [self.totalProgress setText:[self stringFromSecond:self.totalSeconds]];
}

- (NSString *)stringFromSecond:(NSUInteger)seconds
{
    return [NSString stringWithFormat:@"%02lu:%02lu:%02lu", seconds/(60*60), (seconds/60)%60, seconds%60];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    self.track = YES;
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    self.track = YES;
    UITouch *touch = [touches anyObject];
    [self calcSeekToBlock:touch];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    self.track = NO;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    self.track = NO;
    UITouch *touch = [touches anyObject];
    NSUInteger seconds = [self calcSeekToBlock:touch];
    if (self.seekToBlock) {
        self.seekToBlock(seconds);
    }
}

- (NSUInteger)calcSeekToBlock:(UITouch *)touch
{
    double seconds = 0;
    CGPoint point = [touch locationInView:self.progressView];
    if (point.x > self.progressView.bounds.size.width) {
        seconds = (double) self.totalSeconds;
    }else if(point.x < 0){
        seconds = (double)0;
    }else{
        seconds = (double) self.totalSeconds * point.x / self.progressView.bounds.size.width;
    }
    [self.currentProgress setText:[self stringFromSecond:seconds]];
    if (self.totalSeconds != 0) {
        float progress = seconds/self.totalSeconds;
        self.progressConstraint.constant = self.progressView.bounds.size.width*progress;
    }else{
        self.progressConstraint.constant = 0;
    }
    return seconds;
}

@end
