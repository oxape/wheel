//
//  DopPlayerBar.m
//  iosmanew
//
//  Created by oxape on 16/6/29.
//  Copyright © 2016年 oxape. All rights reserved.
//

#import "DopPlayerBar.h"
#import "UIImage+FontAwesome.h"

@interface DopPlayerBar ()

@property (nonatomic, strong) UIButton *starButton;
@property (nonatomic, strong) UIButton *downloadButton;
@property (nonatomic, strong) UILabel *tipLabel;

@end

@implementation DopPlayerBar

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor blackColor];
        [self initSubviews];
        [self setLayout];
        [self setAction];
    }
    return self;
}

- (void)initSubviews
{
    self.starButton = [[UIButton alloc] init];
    self.starButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    self.starButton.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
    [self.starButton setImageEdgeInsets:UIEdgeInsetsMake(0, 12, 0, 0)];
    [self.starButton setTitleEdgeInsets:UIEdgeInsetsMake(18, -8, 0, 0)];
    self.starButton.titleLabel.font = [UIFont systemFontOfSize: 10];
    [self.starButton setTitle:@"收藏" forState:UIControlStateNormal];
    if (self.favorited) {
        [self.starButton setImage:[UIImage imageWithIcon:@"fa-heart" backgroundColor:[UIColor clearColor] iconColor:[UIColor redColor] andSize:CGSizeMake(20, 20)] forState:UIControlStateNormal];
    }else{
        [self.starButton setImage:[UIImage imageWithIcon:@"fa-heart-o" backgroundColor:[UIColor clearColor] iconColor:[UIColor whiteColor] andSize:CGSizeMake(20, 20)] forState:UIControlStateNormal];
    }
    
    self.downloadButton = [[UIButton alloc] init];
    self.downloadButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    self.downloadButton.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
    [self.downloadButton setImageEdgeInsets:UIEdgeInsetsMake(0, 6, 0, 0)];
    [self.downloadButton setTitleEdgeInsets:UIEdgeInsetsMake(18, -14, 0, 0)];
    self.downloadButton.titleLabel.font = [UIFont systemFontOfSize: 10];
    
    [self.downloadButton setImage:[UIImage imageWithIcon:@"fa-download" backgroundColor:[UIColor clearColor] iconColor:[UIColor whiteColor] andSize:CGSizeMake(20, 20)] forState:UIControlStateNormal];
    [self.downloadButton setTitle:@"缓存" forState:UIControlStateNormal];
    self.tipLabel = [[UILabel alloc] init];
    self.tipLabel.font = [UIFont systemFontOfSize:12];
    self.tipLabel.textColor = [UIColor whiteColor];
    self.tipLabel.text = self.tipText;
    self.tipLabel.text = @"播放次数:32万";
    [self addSubview:self.starButton];
//    [self addSubview:self.downloadButton];
    [self addSubview:self.tipLabel];
}

- (void)setLayout
{
    for (UIView *subview in self.subviews) {
        subview.translatesAutoresizingMaskIntoConstraints = NO;
    }
    NSDictionary *viewsDict = @{@"tip":self.tipLabel, @"star":self.starButton, @"download":self.downloadButton};
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[tip(32)]|" options:0 metrics:nil views:viewsDict]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[tip]-[star(48)]-8-|" options:NSLayoutFormatAlignAllBottom|NSLayoutFormatAlignAllTop metrics:nil views:viewsDict]];
}

- (void)setAction
{
    [self.starButton addTarget:self action:@selector(starButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.downloadButton addTarget:self action:@selector(downloadButtonClick) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setTipText:(NSString *)tipText
{
    _tipText = tipText;
    self.tipLabel.text = tipText;
}

- (void)setFavorited:(BOOL)favorited
{
    _favorited = favorited;
    if (_favorited) {
        [self.starButton setImage:[UIImage imageWithIcon:@"fa-heart" backgroundColor:[UIColor clearColor] iconColor:[UIColor redColor] andSize:CGSizeMake(20, 20)] forState:UIControlStateNormal];
        [self.starButton setTitle:@"已收藏" forState:UIControlStateNormal];
        [self.starButton setTitleEdgeInsets:UIEdgeInsetsMake(18, -11, 0, 0)];
    }else{
        [self.starButton setImage:[UIImage imageWithIcon:@"fa-heart-o" backgroundColor:[UIColor clearColor] iconColor:[UIColor whiteColor] andSize:CGSizeMake(20, 20)] forState:UIControlStateNormal];
        [self.starButton setTitle:@"收藏" forState:UIControlStateNormal];
        [self.starButton setTitleEdgeInsets:UIEdgeInsetsMake(18, -8, 0, 0)];
    }
}

- (void)starButtonClick
{
    if (self.starBlock) {
        self.starBlock(self.favorited);
    }
}

- (void)downloadButtonClick
{
    if (self.downloadBlock) {
        self.downloadBlock();
    }
}

@end
