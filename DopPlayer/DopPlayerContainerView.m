//
//  DopPlayerContainerView.m
//  iosmanew
//
//  Created by oxape on 16/3/3.
//  Copyright © 2016年 oxape. All rights reserved.
//

#import "DopPlayerContainerView.h"
#import "UIImage+FontAwesome.h"

@interface DopPlayerContainerView ()

@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, strong) UIButton *nextButton;
@property (nonatomic, strong) DopPlayerProgressView *progressView;
@property (nonatomic, strong) UIButton *fullScreenButton;

@property (nonatomic, strong) UIButton *lockButton;
@property (nonatomic, strong) UIButton *navigationButton;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *setttingButton;

@property (nonatomic, strong) UIView *topContainer;
@property (nonatomic, strong) UIView *bottomContainer;

@end

@implementation DopPlayerContainerView

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.play = YES;
        self.fullScreen = NO;
        
        [self initSubviews];
        [self setLayout];
        [self setAction];
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] init];
        tapRecognizer.numberOfTapsRequired=1;
        tapRecognizer.numberOfTouchesRequired = 1;
        [tapRecognizer addTarget:self action:@selector(tapAction:)];
        [self addGestureRecognizer:tapRecognizer];
        
        UITapGestureRecognizer *doubleTapRecognizer = [[UITapGestureRecognizer alloc] init];
        doubleTapRecognizer.numberOfTapsRequired=2;
        tapRecognizer.numberOfTouchesRequired = 1;
        [doubleTapRecognizer addTarget:self action:@selector(playButtonClick)];
        [self addGestureRecognizer:doubleTapRecognizer];
        
        UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] init];
        [pinchRecognizer addTarget:self action:@selector(pinchAction:)];
        [self addGestureRecognizer:pinchRecognizer];
        
        [tapRecognizer requireGestureRecognizerToFail:doubleTapRecognizer];
    }
    return self;
}

- (void)setPlayLayer:(CALayer *)playLayer
{
    if(_playLayer != nil)
    {
        [_playLayer removeFromSuperlayer];
    }
    [self.layer addSublayer:playLayer];
    playLayer.zPosition = -1;
    playLayer.frame = self.frame;
    _playLayer = playLayer;
}

- (void)initSubviews{
    self.topContainer = [[UIView alloc] init];
    self.topContainer.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.8];
    [self addSubview:self.topContainer];
    
    self.bottomContainer = [[UIView alloc] init];
    self.bottomContainer.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.8];
    [self addSubview:self.bottomContainer];
    
    self.navigationButton = [[UIButton alloc] init];
    [self.navigationButton setBackgroundImage:[UIImage imageWithIcon:@"fa-angle-left" backgroundColor:[UIColor clearColor] iconColor:[UIColor whiteColor] andSize:CGSizeMake(32, 32)] forState:UIControlStateNormal];
    [self.topContainer addSubview:self.navigationButton];
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = [UIFont systemFontOfSize:14];
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.topContainer addSubview:self.titleLabel];
    self.setttingButton = [[UIButton alloc] init];
    [self.setttingButton setBackgroundImage:[UIImage imageWithIcon:@"fa-cog" backgroundColor:[UIColor clearColor] iconColor:[UIColor whiteColor] andSize:CGSizeMake(32, 32)] forState:UIControlStateNormal];
    [self.topContainer addSubview:self.setttingButton];
    
    self.playButton = [[UIButton alloc] init];
    if (self.isPlay) {
        [self.playButton setBackgroundImage:[UIImage imageWithIcon:@"fa-pause" backgroundColor:[UIColor clearColor] iconColor:[UIColor whiteColor] andSize:CGSizeMake(24, 24)] forState:UIControlStateNormal];
    }else{
        [self.playButton setBackgroundImage:[UIImage imageWithIcon:@"fa-play" backgroundColor:[UIColor clearColor] iconColor:[UIColor whiteColor] andSize:CGSizeMake(24, 24)] forState:UIControlStateNormal];
    }
    [self.bottomContainer addSubview:self.playButton];
    
    self.fullScreenButton = [[UIButton alloc] init];
    if (self.isFullScreen) {
        [self.fullScreenButton setBackgroundImage:[UIImage imageWithIcon:@"fa-compress" backgroundColor:[UIColor clearColor] iconColor:[UIColor whiteColor] andSize:CGSizeMake(24, 24)] forState:UIControlStateNormal];
    }else{
        [self.fullScreenButton setBackgroundImage:[UIImage imageWithIcon:@"fa-expand" backgroundColor:[UIColor clearColor] iconColor:[UIColor whiteColor] andSize:CGSizeMake(24, 24)] forState:UIControlStateNormal];
    }
    [self.bottomContainer addSubview:self.fullScreenButton];
    
    self.progressView = [[DopPlayerProgressView alloc] init];
    [self.bottomContainer addSubview:self.progressView];
    
    self.lockButton = [[UIButton alloc] init];
    self.lockButton.layer.cornerRadius = 4;
    self.lockButton.layer.masksToBounds = YES;
    self.lockButton.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.8];
    self.lockButton.imageView.contentMode = UIViewContentModeRight;
    if (self.isLock) {
        [self.lockButton setImage:[UIImage imageWithIcon:@"fa-lock" backgroundColor:[UIColor clearColor] iconColor:[UIColor whiteColor] andSize:CGSizeMake(32,32)] forState:UIControlStateNormal];
    }else{
        [self.lockButton setImage:[UIImage imageWithIcon:@"fa-unlock-alt" backgroundColor:[UIColor clearColor] iconColor:[UIColor whiteColor] andSize:CGSizeMake(32, 32)] forState:UIControlStateNormal];
    }
    [self addSubview:self.lockButton];
}

- (void)setLayout{
    for (UIView *subview in self.subviews) {
        subview.translatesAutoresizingMaskIntoConstraints = NO;
        for (UIView *view in subview.subviews) {
            view.translatesAutoresizingMaskIntoConstraints = NO;
        }
    }
    NSDictionary *viewsDict = @{@"top":self.topContainer, @"bottom":self.bottomContainer, @"lock":self.lockButton, @"nav":self.navigationButton, @"title":self.titleLabel, @"setting":self.setttingButton, @"play":self.playButton, @"full":self.fullScreenButton, @"progress":self.progressView};
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[top(32)]" options:0 metrics:nil views:viewsDict]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[top]|" options:0 metrics:nil views:viewsDict]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[bottom(32)]|" options:0 metrics:nil views:viewsDict]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[bottom]|" options:0 metrics:nil views:viewsDict]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[nav(32)]" options:0 metrics:nil views:viewsDict]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[nav(32)]-[title]-[setting(32)]-|" options:NSLayoutFormatAlignAllTop|NSLayoutFormatAlignAllBottom metrics:nil views:viewsDict]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[nav(32)]" options:0 metrics:nil views:viewsDict]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[play(24)]-8-[progress]-8-[full(24)]-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:viewsDict]];
//    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[full(24)]-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:viewsDict]];
//    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self.progressView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.fullScreenButton attribute:NSLayoutAttributeLeft multiplier:1.0 constant:8.0];
//    constraint.priority = 900;
//    [self addConstraint:constraint];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-4-[play]-4-|" options:0 metrics:nil views:viewsDict]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-4-[full]-4-|" options:0 metrics:nil views:viewsDict]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[progress(32)]" options:0 metrics:nil views:viewsDict]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(-4)-[lock(48)]" options:0 metrics:nil views:viewsDict]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.lockButton attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.lockButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:0.0 constant:48]];
}

- (void)setAction
{
    [self.navigationButton addTarget:self action:@selector(navigationButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.playButton addTarget:self action:@selector(playButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.fullScreenButton addTarget:self action:@selector(fullScreenButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.lockButton addTarget:self action:@selector(lockButtonClick:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)layoutSubviews{
    [super layoutSubviews];
    if (self.playLayer) {
        [UIView animateWithDuration:0.2 animations:^{
            _playLayer.frame = self.frame;
        }];
    }
}

- (void)setFullScreen:(BOOL)fullScreen
{
    _fullScreen = fullScreen;
    if (self.isFullScreen) {
        [self.fullScreenButton setBackgroundImage:[UIImage imageWithIcon:@"fa-compress" backgroundColor:[UIColor clearColor] iconColor:[UIColor whiteColor] andSize:CGSizeMake(24, 24)] forState:UIControlStateNormal];
    }else{
        [self.fullScreenButton setBackgroundImage:[UIImage imageWithIcon:@"fa-expand" backgroundColor:[UIColor clearColor] iconColor:[UIColor whiteColor] andSize:CGSizeMake(24, 24)] forState:UIControlStateNormal];
    }
}

- (void)setPlay:(BOOL)play
{
    _play = play;
    if (self.isPlay) {
        [self.playButton setBackgroundImage:[UIImage imageWithIcon:@"fa-pause" backgroundColor:[UIColor clearColor] iconColor:[UIColor whiteColor] andSize:CGSizeMake(24, 24)] forState:UIControlStateNormal];
    }else{
        [self.playButton setBackgroundImage:[UIImage imageWithIcon:@"fa-play" backgroundColor:[UIColor clearColor] iconColor:[UIColor whiteColor] andSize:CGSizeMake(24, 24)] forState:UIControlStateNormal];
    }
}

- (void)navigationButtonClick:(UIButton *)sender
{
    if (self.isFullScreen) {
        self.fullScreen = NO;
        self.fullScreenBlock(self.isFullScreen);
        return;
    }
    if (self.navBlock) {
        self.navBlock();
    }
}

- (void)playButtonClick
{
    if (self.isLock) {
        self.lockButton.hidden = NO;
        return;
    }
    self.play = !self.isPlay;
    if (self.playBlock) {
        self.playBlock(self.isPlay);
    }
}

- (void)fullScreenButtonClick:(UIButton *)sender
{
    self.fullScreen = !self.isFullScreen;
    if (self.fullScreenBlock) {
        self.fullScreenBlock(self.isFullScreen);
    }
}

- (void)lockButtonClick:(UIButton *)sender
{
    self.lock = !self.isLock;
    if (self.isLock) {
        [self.lockButton setImage:[UIImage imageWithIcon:@"fa-lock" backgroundColor:[UIColor clearColor] iconColor:[UIColor whiteColor] andSize:CGSizeMake(32, 32)] forState:UIControlStateNormal];
    }else{
        [self.lockButton setImage:[UIImage imageWithIcon:@"fa-unlock-alt" backgroundColor:[UIColor clearColor] iconColor:[UIColor whiteColor] andSize:CGSizeMake(32, 32)] forState:UIControlStateNormal];
    }
    if (self.isLock) {
        [UIView animateWithDuration:4.5 animations:^{
            self.lockButton.hidden = YES;
        }];
    }
    [UIView animateWithDuration:0.5 animations:^{
        if (self.isLock) {
            self.topContainer.hidden = YES;
            self.bottomContainer.hidden = YES;
        }else{
            self.topContainer.hidden = NO;
            self.bottomContainer.hidden = NO;
        }
    }];
    if (self.lockBlock) {
        self.lockBlock(self.isLock);
    }
}

- (void)setTitle:(NSString *)title
{
    self.titleLabel.text = title;
}

- (void)tapAction:(id)sender
{
    if (self.isLock) {
        self.lockButton.hidden = !self.lockButton.hidden;
        return;
    }
    [UIView animateWithDuration:0.5 animations:^{
        self.lockButton.hidden = !self.lockButton.hidden;
        self.topContainer.hidden = !self.topContainer.hidden;
        self.bottomContainer.hidden = !self.bottomContainer.hidden;
    }];
}

- (void)pinchAction:(UIPinchGestureRecognizer *)recognizer
{
    if (self.isLock) {
        self.lockButton.hidden = NO;
        return;
    }
    CGFloat scale = recognizer.scale;
    recognizer.scale = 1.0;
    if (scale > 1.2) {
        self.fullScreen = YES;
        if (self.fullScreenBlock) {
            self.fullScreenBlock(self.isFullScreen);
        }
    }
    if (scale < 0.8) {
        self.fullScreen = NO;
        if (self.fullScreenBlock) {
            self.fullScreenBlock(self.isFullScreen);
        }
    }
}

@end
