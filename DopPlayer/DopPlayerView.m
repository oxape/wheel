//
//  DopPlayerView.m
//  iosmanew
//
//  Created by oxape on 16/6/7.
//  Copyright © 2016年 oxape. All rights reserved.
//

#import "DopPlayerView.h"

@interface DopPlayerView ()

@property (nonatomic, strong) UIView *customContainer;
@property (nonatomic, strong) NSMutableArray *constraintsArray;
@property (nonatomic, strong) NSLayoutConstraint *constraintHeight;

@end

@implementation DopPlayerView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initSubviews];
        [self setLayout];
        NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:320];
        constraint.priority = 100;
        [self addConstraint:constraint];
    }
    return self;
}

- (void)initSubviews{
    self.playerContainer = [[DopPlayerContainerView alloc] init];
    self.playerContainer.backgroundColor = [UIColor blackColor];
    [self addSubview:self.playerContainer];
    self.playerContainer.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.playerBar = [[DopPlayerBar alloc] init];
    [self addSubview:self.playerBar];
    self.playerBar.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.customContainer = [[UIView alloc] init];
    self.customContainer.backgroundColor = [UIColor whiteColor];
    [self addSubview:self.customContainer];
    self.customContainer.translatesAutoresizingMaskIntoConstraints = NO;
}

- (void)setLayout{
    [self setFullScreen:NO];
}

- (void)updateConstraints
{
    NSDictionary *viewsDict = @{@"player":self.playerContainer, @"bar":self.playerBar, @"custom":self.customContainer};
    [super updateConstraints];
    [self removeConstraints:self.constraintsArray];
    [self.constraintsArray removeAllObjects];
    if (self.isFullScreen) {
        [self.constraintsArray addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[player]|" options:0 metrics:nil views:viewsDict]];
        [self.constraintsArray addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[player][bar(32)]" options:NSLayoutFormatAlignAllLeft|NSLayoutFormatAlignAllRight metrics:nil views:viewsDict]];
        [self.constraintsArray addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[custom(120)]" options:NSLayoutFormatAlignAllLeft|NSLayoutFormatAlignAllRight metrics:nil views:viewsDict]];
        [self.constraintsArray addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[custom]|" options:NSLayoutFormatAlignAllLeft|NSLayoutFormatAlignAllRight metrics:nil views:viewsDict]];
        [self.constraintsArray addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[player]|" options:0 metrics:nil views:viewsDict]];
        [self.constraintsArray addObject:self.constraintHeight];
        [self addConstraints:self.constraintsArray];
    }else{
        [self.constraintsArray addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[player][bar(32)]" options:NSLayoutFormatAlignAllLeft|NSLayoutFormatAlignAllRight metrics:nil views:viewsDict]];
        [self.constraintsArray addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[player]|" options:0 metrics:nil views:viewsDict]];
        [self.constraintsArray addObject:[NSLayoutConstraint constraintWithItem:self.playerContainer attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.playerContainer attribute:NSLayoutAttributeWidth multiplier:10.0f/16.0f constant:0.0]];
        NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self.customContainer attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
        constraint.priority = 900;
        [self.constraintsArray addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[custom]|" options:NSLayoutFormatAlignAllLeft|NSLayoutFormatAlignAllRight metrics:nil views:viewsDict]];
        [self.constraintsArray addObject:self.constraintHeight];
        [self.constraintsArray addObject:constraint];
        [self addConstraints:self.constraintsArray];
    }
}

- (void)setFullScreen:(BOOL)fullScreen
{
    _fullScreen = fullScreen;
    self.playerContainer.fullScreen = fullScreen;
    if(_fullScreen && !UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)){
        if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
            SEL selector = NSSelectorFromString(@"setOrientation:");
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
            [invocation setSelector:selector];
            [invocation setTarget:[UIDevice currentDevice]];
            int val = UIInterfaceOrientationLandscapeRight;
            [invocation setArgument:&val atIndex:2];
            [invocation invoke];
        }
    }
    if (!_fullScreen && !UIDeviceOrientationIsPortrait([UIDevice currentDevice].orientation)) {
        if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
            SEL selector = NSSelectorFromString(@"setOrientation:");
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
            [invocation setSelector:selector];
            [invocation setTarget:[UIDevice currentDevice]];
            int val = UIInterfaceOrientationPortrait;
            [invocation setArgument:&val atIndex:2];
            [invocation invoke];
        }
    }
    [UIView animateWithDuration:0.5 animations:^{
        [self updateConstraints];
        [self layoutIfNeeded];
    }];
}

- (NSMutableArray *)constraintsArray
{
    if (!_constraintsArray) {
        _constraintsArray = [[NSMutableArray alloc] init];
    }
    return _constraintsArray;
}

- (void)setPlayLayer:(CALayer *)playLayer
{
    [self.playerContainer setPlayLayer:playLayer];
}

- (void)setCustomView:(UIView *)customView animated:(BOOL)animated coverBar:(BOOL)cover
{
    if (self.customContainer) {
        if (!animated) {
            for(UIView *subview in self.customContainer.subviews){
                [subview removeFromSuperview];
            }
            [self.customContainer removeConstraints:[customView constraints]];
            
            customView.translatesAutoresizingMaskIntoConstraints = NO;
            [self.customContainer addSubview:customView];
            NSDictionary *viewsDict = @{@"custom":customView};
            [self.customContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[custom]|" options:0 metrics:nil views:viewsDict]];
            [self.customContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[custom]|" options:0 metrics:nil views:viewsDict]];
            if (cover) {
                self.constraintHeight.constant = 0;
            }else{
                self.constraintHeight.constant = 32;
            }
        }else{
            [UIView transitionFromView:[self.customContainer.subviews firstObject] toView:customView duration:0.3 options:UIViewAnimationOptionTransitionCrossDissolve completion:^(BOOL finished) {
                for(UIView *subview in self.customContainer.subviews){
                    [subview removeFromSuperview];
                }
                [self.customContainer addSubview:customView];
                
                [self.customContainer removeConstraints:[customView constraints]];
                customView.translatesAutoresizingMaskIntoConstraints = NO;
                [self.customContainer addSubview:customView];
                NSDictionary *viewsDict = @{@"custom":customView};
                [self.customContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[custom]|" options:0 metrics:nil views:viewsDict]];
                [self.customContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[custom]|" options:0 metrics:nil views:viewsDict]];
                if (cover) {
                    self.constraintHeight.constant = 0;
                }else{
                    self.constraintHeight.constant = 32;
                }
            }];
        }
    }
}

- (NSLayoutConstraint *)constraintHeight
{
    if (!_constraintHeight) {
        _constraintHeight = [NSLayoutConstraint constraintWithItem:self.customContainer attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.playerBar attribute:NSLayoutAttributeTop multiplier:1.0 constant:32];
    }
    return _constraintHeight;
}

@end
