//
//  DopPlayerViewController.m
//  iosmanew
//
//  Created by oxape on 16/6/2.
//  Copyright © 2016年 oxape. All rights reserved.
//

#import "DopPlayerViewController.h"
#import "DopPlayerView.h"
#import "DopFATableViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface DopPlayerViewController ()

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerItem *currentItem;
@property (nonatomic, strong) DopPlayerView *playerView;
@property (nonatomic, strong) DopFATableViewController *FATableViewCtl;
@property (nonatomic, assign, getter=isLock) BOOL lock;

@end

@implementation DopPlayerViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
        DopPlayerContainerView *playerContainer = self.playerView.playerContainer;
        [playerContainer setPlayLayer:playerLayer];
        __weak DopPlayerViewController *weakSelf = self;  //这里不用__weak会造成内存泄露，但是由于是这里重新声明了变量导致编译器检测不出来循环引用,（self.child.child三层关系导致编译器检测不出来循环引用。错误的解释）
        [self.playerView.playerContainer setNavBlock:^{
            [weakSelf.player pause];
            weakSelf.player = nil;
            [weakSelf.navigationController popViewControllerAnimated:YES];
            weakSelf.navigationController.navigationBarHidden = NO;
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
        }];
        [playerContainer setPlayBlock:^(BOOL isPlay) {
            if (isPlay) {
                [weakSelf.player play];
            }else{
                [weakSelf.player pause];
            }
        }];
        [playerContainer setFullScreenBlock:^(BOOL isFullScreen) {
            DopPlayerView *playerView = weakSelf.playerView;
            playerView.fullScreen = isFullScreen;
        }];
        [playerContainer setLockBlock:^(BOOL isLock) {
            weakSelf.lock = isLock;
        }];
        [playerContainer.progressView setSeekToBlock:^(NSUInteger seconds) {
            [weakSelf.player seekToTime:CMTimeMake(seconds, 1.0)];
        }];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    self.navigationController.navigationBarHidden = YES;
    
    [self.view addSubview:self.playerView];
    id top = self.topLayoutGuide;
    id bottom = self.bottomLayoutGuide;
    NSDictionary *viewsDict = @{@"top":top, @"bottom":bottom, @"playerView":self.playerView};
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[top][playerView][bottom]" options:0 metrics:nil views:viewsDict]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[playerView]|" options:0 metrics:nil views:viewsDict]];
    
    __weak DopPlayerViewController *weakSelf = self;
    [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        [weakSelf.playerView.playerContainer.progressView setTotalSeconds:(NSUInteger)CMTimeGetSeconds(weakSelf.currentItem.duration)];
        [weakSelf.playerView.playerContainer.progressView setCurrentSeconds:(NSUInteger)CMTimeGetSeconds(weakSelf.currentItem.currentTime)];
    }];
    [self.player play];
}

-(void)addObserverToPlayerItem:(AVPlayerItem *)playerItem{
    //监控状态属性，注意AVPlayer也有一个status属性，通过监控它的status也可以获得播放状态
    [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    //监控网络加载情况属性
    [playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    
    NSLog(@"add ObbserverToPlayerItem %@", playerItem);
}
-(void)removeObserverFromPlayerItem:(AVPlayerItem *)playerItem{
    [playerItem removeObserver:self forKeyPath:@"status"];
    [playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    NSLog(@"remove ObbserverToPlayerItem %@", playerItem);
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
//    AVPlayerItem *playerItem=object;
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItemStatus status= [[change objectForKey:@"new"] intValue];
        if(status==AVPlayerItemStatusReadyToPlay){
            [self.playerView.playerContainer.progressView setTotalSeconds:(NSUInteger)CMTimeGetSeconds(self.currentItem.duration)];
        }else if(status == AVPlayerItemStatusFailed){
            NSLog(@"error = %@", self.currentItem.error);
            NSLog(@"%@", [self.currentItem errorLog]);
        }
    }else if([keyPath isEqualToString:@"loadedTimeRanges"]){
//        NSArray *array=playerItem.loadedTimeRanges;
//        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];//本次缓冲时间范围
//        float startSeconds = CMTimeGetSeconds(timeRange.start);
//        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
//        NSTimeInterval totalBuffer = startSeconds + durationSeconds;//缓冲总长度
//        NSLog(@"共缓冲：%.2f",totalBuffer);
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    NSLog(@"Rotate %ld", [UIDevice currentDevice].orientation);
    if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)) {
        self.playerView.fullScreen = YES;
        NSLog(@"full");
    }else{
        self.playerView.fullScreen = NO;
        NSLog(@"not full");
    }
}

- (BOOL)shouldAutorotate
{
    if (self.isLock) {
        return NO;
    }else{
        return [super shouldAutorotate];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (void)dealloc
{
    if(self.currentItem){
        [self.currentItem cancelPendingSeeks];
        [self.currentItem.asset cancelLoading];
    }
    [self removeObserverFromPlayerItem:self.currentItem];
}

#pragma mark - delay create property

- (AVPlayer *)player
{
    if (!_player) {
        if (self.currentItem) {
            [self removeObserverFromPlayerItem:self.currentItem];
        }
         self.currentItem = [AVPlayerItem playerItemWithURL:self.videoURL];
        if (self.currentItem) {
            [self addObserverToPlayerItem:self.currentItem];
        }
        _player = [AVPlayer playerWithPlayerItem:self.currentItem];
    }
    return _player;
}

- (void)setVideoURL:(NSURL *)videoURL
{
    _videoURL = videoURL;
    BOOL currentEmpty = self.currentItem == nil;
    if (!currentEmpty) {
        [self removeObserverFromPlayerItem:self.currentItem];
        self.currentItem = nil;
    }
    self.currentItem = [AVPlayerItem playerItemWithURL:self.videoURL];
    if (self.currentItem) {
        [self addObserverToPlayerItem:self.currentItem];
    }
    [self.player replaceCurrentItemWithPlayerItem:self.currentItem];
}

- (void)setVideoTitle:(NSString *)videoTitle
{
    _videoTitle = videoTitle;
    DopPlayerContainerView *playerContainer = self.playerView.playerContainer;
    [playerContainer setTitle:videoTitle];
}

- (void)setCustomView:(UIView *)customView
{
    DopPlayerView *playerView = self.playerView;
    [playerView setCustomView:customView animated:NO coverBar:NO];
}

- (void)setCustomView:(UIView *)customView animated:(BOOL)animated coverBar:(BOOL)cover
{
    DopPlayerView *playerView = self.playerView;
    [playerView setCustomView:customView animated:animated coverBar:cover];
}

- (DopPlayerView *)playerView
{
    if (!_playerView) {
        DopPlayerView *playerView = [[DopPlayerView alloc] init];
        playerView.translatesAutoresizingMaskIntoConstraints = NO;
        
        _playerView = playerView;
    }
    return _playerView;
}

- (DopPlayerBar *)playerBar
{
    return self.playerView.playerBar;
}

@end
