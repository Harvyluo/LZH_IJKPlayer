//
//  XYVideoPlayerView.m
//  SmartClassRoom
//
//  Created by Nowind on 16/4/8.
//  Copyright © 2016年 newcloudnet. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import "Masonry.h"
#import <AVFoundation/AVAudioSession.h>

#import "XYVideoPlayerView.h"
#import "LZHProgressSlider.h"
#import "LZHButton.h"

#import "XYVideoModel.h"

#import <IJKMediaFramework/IJKMediaFramework.h>

typedef NS_ENUM(NSUInteger, Direction) {
    DirectionLeftOrRight,
    DirectionUpOrDown,
    DirectionNone
};

@interface XYVideoPlayerView()<IJKMediaUrlOpenDelegate,LZHButtonDelegate>

/* 视频播放器 */
@property(nonatomic, strong) id<IJKMediaPlayback>    player;
@property (nonatomic, weak) IBOutlet UIView          *upPlayerView;
// 工具条
@property (weak, nonatomic) IBOutlet UIView          *toolView;
@property (weak, nonatomic) IBOutlet UIView          *navView;
@property (weak, nonatomic) IBOutlet UILabel         *videoTitle;
@property (weak, nonatomic) IBOutlet UIButton        *backBtn;
@property (weak, nonatomic) IBOutlet UIView          *sliderBackView;
@property (strong, nonatomic) LZHProgressSlider      *slider;
//菊花
@property (nonatomic, strong)  UIActivityIndicatorView *activity;
@property (nonatomic, strong) CADisplayLink            *link;
@property (nonatomic, assign) NSTimeInterval           lastTime;
//播放、暂停
@property (strong, nonatomic) UIButton                 *playOrPauseBtn;
//全屏按钮
@property (weak, nonatomic) IBOutlet UIButton          *fullScreenBtn;
//加载失败的按钮
@property (strong, nonatomic) UIButton                 *loadFailBtn;
//添加手势的Button
@property (strong, nonatomic) LZHButton                *button;
//开始滑动的点
@property (assign, nonatomic) CGPoint                  startPoint;
//开始滑动时的亮度
@property (assign, nonatomic) CGFloat                  startVB;
//滑动方向
@property (assign, nonatomic) Direction                direction;
//滑动开始的播放进度
@property (assign, nonatomic) CGFloat                  startVideoRate;
//当期视频播放的进度
@property (assign, nonatomic) CGFloat                  currentRate;
//转载自定义的音量控件视图
@property (strong, nonatomic) UIView                   *LZHVolumeBackView;
//自定义控制音量
@property (strong, nonatomic) LZHProgressSlider        *LZHVolumeSlider;
//音量图标
@property (strong, nonatomic) UIImageView              *LZHVolumeImageView;
//当前的播放时间
@property (weak, nonatomic) IBOutlet UILabel           *currTimeLabel;
//总的播放时间
@property (weak, nonatomic) IBOutlet UILabel           *totalTimeLabel;
//全屏按钮
@property (weak, nonatomic) IBOutlet UIButton          *upFullScreenBtn;
//定时器
@property (nonatomic, retain) NSTimer                  *autoDismissTimer;

@end

@implementation XYVideoPlayerView{
    
    UISlider *systemSlider;
    UITapGestureRecognizer* singleTap;
}
#pragma mark - 初始化
// 快速创建View的方法
+ (instancetype)videoPlayerView
{
    XYVideoPlayerView *view = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil] firstObject];
    view.backgroundColor = [UIColor blackColor];
    return view;
}
- (void)awakeFromNib{
    [super awakeFromNib];
    //初始化播放控制器
    [self setupUpPlayer];
    //初始化UI
    [self setUI];
    
}
- (void)setUI{
    
    //滑块显示进度和缓冲
    self.slider = [[LZHProgressSlider alloc] initWithFrame:self.sliderBackView.bounds direction:AC_SliderDirectionHorizonal];
    [self.sliderBackView addSubview:self.slider];
    self.slider.enabled = NO;
    [self.slider addTarget:self action:@selector(progressValueChange:) forControlEvents:UIControlEventValueChanged];
    [self.slider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.sliderBackView);
    }];
    //菊花
    self.activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.activity.color = [UIColor redColor];
    [self.activity setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhiteLarge];//设置进度轮显示类型
    [self.upPlayerView addSubview:self.activity];
    [self.activity mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.mas_centerX);
        make.centerY.equalTo(self.mas_centerY);
    }];
    
    //添加自定义的Button到视频画面上 用于手势控制相关
    _button = [[LZHButton alloc]init];
    _button.touchDelegate = self;
    [self addSubview:_button];
    [_button mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.navView.mas_bottom);
        make.left.right.equalTo(self);
        make.bottom.equalTo(self.toolView.mas_top);
    }];
    //播放按钮
    self.playOrPauseBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.playOrPauseBtn setImage:[UIImage imageNamed:@"pauseBtn"] forState:UIControlStateNormal];
    [self.playOrPauseBtn setImage:[UIImage imageNamed:@"playBtn"] forState:UIControlStateSelected];
    [self.playOrPauseBtn addTarget:self action:@selector(playOrPause:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.playOrPauseBtn];
    [self.playOrPauseBtn mas_updateConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.mas_centerX);
        make.centerY.equalTo(self.mas_centerY);
        make.width.height.equalTo(@44);
    }];
    
    self.fullScreenBtn.showsTouchWhenHighlighted = YES;
    [self.fullScreenBtn setImage:[UIImage imageNamed:@"fullscreen"] forState:UIControlStateNormal];
    [self.fullScreenBtn setImage:[UIImage imageNamed:@"nonfullscreen"] forState:UIControlStateSelected];
    //系统的音量
    MPVolumeView *volumeView = [[MPVolumeView alloc]init];
    [self addSubview:volumeView];
    //转移到屏幕视线外的地方显示
    volumeView.frame = CGRectMake(-1000, -100, 100, 100);
    [volumeView sizeToFit];
    
    systemSlider = [[UISlider alloc]init];
    systemSlider.backgroundColor = [UIColor clearColor];
    for (UIControl *view in volumeView.subviews) {
        if ([view.superclass isSubclassOfClass:[UISlider class]]) {
            systemSlider = (UISlider *)view;
        }
    }
    systemSlider.autoresizesSubviews = NO;
    systemSlider.autoresizingMask = UIViewAutoresizingNone;
    [self addSubview:systemSlider];
    //自定义的音量显示
    self.LZHVolumeSlider.progressPercent = systemSlider.value;
    
    // 单击的 Recognizer
    singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    singleTap.numberOfTapsRequired = 1; // 单击
    singleTap.numberOfTouchesRequired = 1;
    [self addGestureRecognizer:singleTap];
}
// 初始化视频
- (void)setupUpPlayer
{
    //IJKFFOptions *options = [IJKFFOptions optionsByDefault];
    //options.showHudView = YES;
    //[options setFormatOptionValue:@"ijktcphook" forKey:@"http-tcp-hook"];
    _player = [[IJKFFMoviePlayerController alloc] initWithContentURL:nil withOptions:nil];
    UIView *playerView = [self.player view];
    playerView.frame = self.bounds;
    playerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:playerView];
    [self insertSubview:playerView atIndex:1];
    [_player setScalingMode:IJKMPMovieScalingModeAspectFill];
    [self installMovieNotificationObservers];
    
    if (![self.player isPlaying]) {
        [self.player prepareToPlay];
    }
    self.link = [CADisplayLink displayLinkWithTarget:self selector:@selector(upadte)];
    [self.link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
}
//音量调节
- (void)volumeChanged:(NSNotification *)notification
{
    self.LZHVolumeBackView.hidden = NO;
    self.LZHVolumeSlider.sliderPercent = systemSlider.value;
}

- (BOOL)willOpenUrl:(IJKMediaUrlOpenData*) urlOpenData
{
    return YES;
}
#pragma -mark 懒加载
- (UIView *)LZHVolumeBackView{
    
    if (!_LZHVolumeBackView) {
        
        _LZHVolumeBackView = [UIView new];
        _LZHVolumeBackView.hidden = YES;
        [self addSubview:_LZHVolumeBackView];
        [_LZHVolumeBackView mas_makeConstraints:^(MASConstraintMaker *make) {
            
            make.left.equalTo(self).offset(1);
            make.centerY.equalTo(self);
            make.width.equalTo(@50);
            make.height.equalTo(@100);
        }];
        
        _LZHVolumeImageView = [UIImageView new];
        _LZHVolumeImageView.image = [UIImage imageNamed:@"volume"];
        [self.LZHVolumeBackView addSubview:_LZHVolumeImageView];
        [_LZHVolumeImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            
            make.centerX.equalTo(self.LZHVolumeBackView.mas_centerX);
            make.bottom.equalTo(self.LZHVolumeBackView.mas_bottom);
            make.width.height.equalTo(@20);
        }];
        
        
        _LZHVolumeSlider = [[LZHProgressSlider alloc] initWithFrame:CGRectZero direction:AC_SliderDirectionVertical];
        _LZHVolumeSlider.isHiddenThumbImage = YES;
        [self.LZHVolumeBackView addSubview:_LZHVolumeSlider];
        [_LZHVolumeSlider mas_makeConstraints:^(MASConstraintMaker *make) {
            
            make.left.right.equalTo(self.LZHVolumeBackView);
            make.top.equalTo(self.LZHVolumeBackView.mas_top);
            make.bottom.equalTo(self.LZHVolumeImageView.mas_top);
        }];
        _LZHVolumeSlider.transform = CGAffineTransformRotate(_LZHVolumeSlider.transform, M_PI);
    }
    return _LZHVolumeBackView;
}
- (UIButton *)loadFailBtn{
    
    if (!_loadFailBtn) {
        
        _loadFailBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _loadFailBtn.backgroundColor = [UIColor clearColor];
        [_loadFailBtn setTitle:@"视频加载失败，点击重新加载" forState:UIControlStateNormal];
        [_loadFailBtn addTarget:self action:@selector(reloadAction:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_loadFailBtn];
        [_loadFailBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self);
            make.centerY.equalTo(self.mas_centerY);
            make.height.equalTo(@100);
        }];
    }
    return _loadFailBtn;
}
#pragma mark - 播放暂停按钮事件
// 暂停按钮的监听
- (void)playOrPause:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (![self.player isPlaying]) {
        [self.player play];
        self.link.paused = NO;
    }else{
        [self.player pause];
        self.link.paused = YES;
        [self.activity stopAnimating];
    }
}
- (void)reloadAction:(UIButton *)sender{
    
    [self changeCurrentplayerItemWithVideoModel];
}
- (IBAction)backBtnClicked:(id)sender {
    
    if ([self.delegate respondsToSelector:@selector(backToBeforeVC)]) {
        
        [self.delegate backToBeforeVC];
        
        if (self.isRotate) {
            
            [self fullScreenBtnCicked:self.fullScreenBtn];
        }

    }
    
}
//全屏
- (IBAction)fullScreenBtnCicked:(UIButton *)sender {
    
    sender.selected = !sender.selected;
    if ([self.delegate respondsToSelector:@selector(fullScreenWithPlayerView:)]) {
        
        self.isRotate = !self.isRotate;
        
        [self.delegate fullScreenWithPlayerView:self];
        
        [self.slider setNeedsDisplay];
        
        UIView *playerView = [self.player view];
        if (self.isRotate) {
        
            playerView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.height*9/16);
        }else{
            
            playerView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.width*9/16);
        }
        playerView.center = self.center;
        
    }
}
#pragma mark - 单击手势方法
- (void)handleSingleTap:(UITapGestureRecognizer *)sender{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(autoDismissBottomView:) object:nil];
    [self.autoDismissTimer invalidate];
    self.autoDismissTimer = nil;
    self.autoDismissTimer = [NSTimer timerWithTimeInterval:5.0 target:self selector:@selector(autoDismissBottomView:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.autoDismissTimer forMode:NSDefaultRunLoopMode];
    [UIView animateWithDuration:0.5 animations:^{
        if (self.toolView.alpha == 0.0) {
            self.toolView.alpha = 0.6;
            self.navView.alpha = 1.0;
            self.playOrPauseBtn.alpha = 1.0;
            
        }else{
            self.toolView.alpha = 0.0;
            self.navView.alpha = 0.0;
            self.playOrPauseBtn.alpha = 0.0;
            
        }
    } completion:^(BOOL finish){
        
    }];
}
#pragma mark autoDismissBottomView
-(void)autoDismissBottomView:(NSTimer *)timer{
    
    if (![self.player isPlaying]) {//暂停状态
        
    }else{
        if (self.navView.alpha==1.0) {
            [UIView animateWithDuration:0.5 animations:^{
                self.toolView.alpha = 0.0;
                self.navView.alpha = 0.0;
                self.playOrPauseBtn.alpha = 0.0;
                
            } completion:^(BOOL finish){
                
            }];
        }
    }
}
//时间显示转换
- (NSString *)stringWithTime:(NSTimeInterval)time
{
    NSInteger h = time / 3600;
    NSInteger m = time / 60;
    NSInteger s = (NSInteger)time % 60;
    
    NSString *stringtime = [NSString stringWithFormat:@"%02ld:%02ld:%02ld", h, m, s];
    
    return stringtime;
}
//处理滑块
- (void)progressValueChange:(LZHProgressSlider *)slider
{
    if (self.player.isPreparedToPlay) {
        NSTimeInterval duration = self.slider.sliderPercent* self.player.duration;
        // 设置当前播放时间
        self.player.currentPlaybackTime = duration;
        
        self.playOrPauseBtn.selected = NO;
        [self.player play];
        self.link.paused = NO;
    }
}
//更新方法
- (void)upadte
{
    NSTimeInterval current = self.player.currentPlaybackTime;
    NSTimeInterval total = self.player.duration;
    //如果用户在手动滑动滑块，则不对滑块的进度进行设置重绘
    if (!self.slider.isSliding) {
        self.slider.sliderPercent = current/total;
    }
    if (current!=self.lastTime) {
        [self.activity stopAnimating];
        if (self.navView.alpha==1.0) {
            self.playOrPauseBtn.alpha = 1.0;
        }else{
            self.playOrPauseBtn.alpha = 0.0;
        }
        // 更新播放时间
        self.currTimeLabel.text = [self stringWithTime:current];
        self.totalTimeLabel.text = [self stringWithTime:total];
        
    }else{
        [self.activity startAnimating];
        self.playOrPauseBtn.alpha = 0.0;
    }
    self.lastTime = current;
    //缓冲进度
    NSTimeInterval loadedTime = self.player.playableDuration;
    if (!self.slider.isSliding) {
        self.slider.progressPercent = loadedTime/total;
    }
    //播放结束
    if ([self.currTimeLabel.text isEqualToString:self.totalTimeLabel.text] && ![self.totalTimeLabel.text isEqualToString:@"00:00:00"]) {
        self.slider.sliderPercent = 0;
        self.lastTime = 0;
        self.playOrPauseBtn.selected = YES;
        //self.link.paused = YES;
         self.currTimeLabel.text = [self stringWithTime:0];
        [UIView animateWithDuration:0.5 animations:^{
            self.toolView.alpha = 0.6;
            self.navView.alpha = 1.0;
            self.playOrPauseBtn.alpha = 1.0;
        } completion:^(BOOL finish){
            
        }];
    }
    
}

#pragma mark - 自定义Button的代理***********************************************************
#pragma mark - 开始触摸
/*************************************************************************/
- (void)touchesBeganWithPoint:(CGPoint)point {
    //记录首次触摸坐标
    self.startPoint = point;
    //检测用户是触摸屏幕的左边还是右边，以此判断用户是要调节音量还是亮度，左边是亮度，右边是音量
    if (self.startPoint.x <= self.button.frame.size.width / 2.0) {
        //亮度
        self.startVB = [UIScreen mainScreen].brightness;
    } else {
        //音/量
        self.startVB = systemSlider.value;
    }
    //方向置为无
    self.direction = DirectionNone;
    //记录当前视频播放的进度
    NSTimeInterval current = self.player.currentPlaybackTime;
    NSTimeInterval total = self.player.duration;
    self.startVideoRate = current/total;
    
}
#pragma mark - 结束触摸
- (void)touchesEndWithPoint:(CGPoint)point {
    
    CGPoint panPoint = CGPointMake(point.x - self.startPoint.x, point.y - self.startPoint.y);
    if ((panPoint.x >= -5 && panPoint.x <= 5) && (panPoint.y >= -5 && panPoint.y <= 5)) {
        
        [self handleSingleTap:singleTap];
        return;
    }
    
    if (self.direction == DirectionLeftOrRight) {
        if (self.player.isPreparedToPlay) {
            NSTimeInterval duration = self.currentRate* self.player.duration;
            // 设置当前播放时间
            self.player.currentPlaybackTime = duration;
            [self.player play];
        }
    }
    else if (self.direction == DirectionUpOrDown){
        
        self.LZHVolumeBackView.hidden = YES;
    }
}

#pragma mark - 拖动
- (void)touchesMoveWithPoint:(CGPoint)point {
    //得出手指在Button上移动的距离
    CGPoint panPoint = CGPointMake(point.x - self.startPoint.x, point.y - self.startPoint.y);
    //分析出用户滑动的方向
    if (self.direction == DirectionNone) {
        if (panPoint.x >= 30 || panPoint.x <= -30) {
            //进度
            self.direction = DirectionLeftOrRight;
        } else if (panPoint.y >= 30 || panPoint.y <= -30) {
            //音量和亮度
            self.direction = DirectionUpOrDown;
        }
    }
    
    if (self.direction == DirectionNone) {
        return;
    } else if (self.direction == DirectionUpOrDown) {
        //音量和亮度
        if (self.startPoint.x <= self.button.frame.size.width / 2.0) {
            //调节亮度
            if (panPoint.y < 0) {
                //增加亮度
                [[UIScreen mainScreen] setBrightness:self.startVB + (-panPoint.y / 30.0 / 10)];
            } else {
                //减少亮度
                [[UIScreen mainScreen] setBrightness:self.startVB - (panPoint.y / 30.0 / 10)];
            }
            
        } else {
            //音量
            self.LZHVolumeBackView.hidden = NO;
            if (panPoint.y < 0) {
                //增大音量
                [systemSlider setValue:self.startVB + (-panPoint.y / 30.0 / 10) animated:YES];
                if (self.startVB + (-panPoint.y / 30 / 10) - systemSlider.value >= 0.1) {
                    [systemSlider setValue:0.1 animated:NO];
                    [systemSlider setValue:self.startVB + (-panPoint.y / 30.0 / 10) animated:YES];
                }
                
            } else {
                //减少音量
                [systemSlider setValue:self.startVB - (panPoint.y / 30.0 / 10) animated:YES];
            }
        }
    } else if (self.direction == DirectionLeftOrRight ) {
        //进度
        CGFloat rate = self.startVideoRate + (panPoint.x / 30.0 / 20.0);
        if (rate > 1) {
            rate = 1;
        } else if (rate < 0) {
            rate = 0;
        }
        self.currentRate = rate;
        self.slider.sliderPercent = self.currentRate;
    }
}
//重写set方法
- (void)setVideoModel:(XYVideoModel *)videoModel{
    
    _videoModel = videoModel;
    
    [self changeCurrentplayerItemWithVideoModel];
}
//切换当前播放的内容
- (void)changeCurrentplayerItemWithVideoModel
{
    //移除当前player的监听
    [self.player shutdown];
    [self.player.view removeFromSuperview];
    [self removeMovieNotificationObservers];
    // 关闭定时器
    [self.autoDismissTimer invalidate];
    self.autoDismissTimer = nil;
    
    //菊花转动 同时按钮要隐藏
    [self.activity startAnimating];
    self.playOrPauseBtn.alpha = 0;
    
    _player = [[IJKFFMoviePlayerController alloc] initWithContentURL:self.videoModel.url withOptions:nil];
    UIView *playerView = [self.player view];
    playerView.frame = self.bounds;
    playerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:playerView];
    [self insertSubview:playerView atIndex:1];
    [_player setScalingMode:IJKMPMovieScalingModeAspectFill];
    [self installMovieNotificationObservers];
    
    if (![self.player isPlaying]) {
        [self.player prepareToPlay];
    }
    self.videoTitle.text = self.videoModel.name;
    //self.playOrPauseBtn.enabled = NO;
    //由暂停状态切换时候 开启定时器，将暂停按钮状态设置为播放状态
    self.link.paused = NO;
    self.playOrPauseBtn.selected = NO;
    self.slider.enabled = NO;
}
- (void)loadStateDidChange:(NSNotification*)notification
{
    //    MPMovieLoadStateUnknown        = 0,
    //    MPMovieLoadStatePlayable       = 1 << 0,
    //    MPMovieLoadStatePlaythroughOK  = 1 << 1, // Playback will be automatically started in this state when shouldAutoplay is YES
    //    MPMovieLoadStateStalled        = 1 << 2, // Playback will be automatically paused in this state, if started
    
    IJKMPMovieLoadState loadState = _player.loadState;
    
    if ((loadState & IJKMPMovieLoadStatePlaythroughOK) != 0) {
        NSLog(@"loadStateDidChange: IJKMPMovieLoadStatePlaythroughOK: %d\n", (int)loadState);
    } else if ((loadState & IJKMPMovieLoadStateStalled) != 0) {
        NSLog(@"loadStateDidChange: IJKMPMovieLoadStateStalled: %d\n", (int)loadState);
    } else {
        NSLog(@"loadStateDidChange: ???: %d\n", (int)loadState);
    }
}

- (void)moviePlayBackDidFinish:(NSNotification*)notification
{
    //    MPMovieFinishReasonPlaybackEnded,
    //    MPMovieFinishReasonPlaybackError,
    //    MPMovieFinishReasonUserExited
    int reason = [[[notification userInfo] valueForKey:IJKMPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue];
    
    switch (reason)
    {
        case IJKMPMovieFinishReasonPlaybackEnded:
            NSLog(@"playbackStateDidChange: IJKMPMovieFinishReasonPlaybackEnded: %d\n", reason);
            break;
            
        case IJKMPMovieFinishReasonUserExited:
            NSLog(@"playbackStateDidChange: IJKMPMovieFinishReasonUserExited: %d\n", reason);
            break;
            
        case IJKMPMovieFinishReasonPlaybackError:{
            NSLog(@"playbackStateDidChange: IJKMPMovieFinishReasonPlaybackError: %d\n", reason);
            self.loadFailBtn.hidden = NO;
            self.link.paused = YES;
            [self.activity stopAnimating];
            break;
        }
        default:
            NSLog(@"playbackPlayBackDidFinish: ???: %d\n", reason);
            break;
    }
}

- (void)mediaIsPreparedToPlayDidChange:(NSNotification*)notification
{
    NSLog(@"mediaIsPreparedToPlayDidChange\n");
    self.slider.enabled = YES;
    self.loadFailBtn.hidden = YES;
    self.link.paused = NO;
    [self.activity stopAnimating];
    //5s dismiss bottomView
    if (self.autoDismissTimer==nil) {
        self.autoDismissTimer = [NSTimer timerWithTimeInterval:5.0 target:self selector:@selector(autoDismissBottomView:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self.autoDismissTimer forMode:NSDefaultRunLoopMode];
    }
}
- (void)moviePlayBackStateDidChange:(NSNotification*)notification
{
    //    MPMoviePlaybackStateStopped,
    //    MPMoviePlaybackStatePlaying,
    //    MPMoviePlaybackStatePaused,
    //    MPMoviePlaybackStateInterrupted,
    //    MPMoviePlaybackStateSeekingForward,
    //    MPMoviePlaybackStateSeekingBackward
    
    switch (_player.playbackState)
    {
        case IJKMPMoviePlaybackStateStopped: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: stoped", (int)_player.playbackState);
            break;
        }
        case IJKMPMoviePlaybackStatePlaying: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: playing", (int)_player.playbackState);
            break;
        }
        case IJKMPMoviePlaybackStatePaused: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: paused", (int)_player.playbackState);
            break;
        }
        case IJKMPMoviePlaybackStateInterrupted: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: interrupted", (int)_player.playbackState);
            break;
        }
        case IJKMPMoviePlaybackStateSeekingForward:
        case IJKMPMoviePlaybackStateSeekingBackward: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: seeking", (int)_player.playbackState);
            break;
        }
        default: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: unknown", (int)_player.playbackState);
            break;
        }
    }
}

#pragma mark Install Movie Notifications

/* Register observers for the various movie object notifications. */
-(void)installMovieNotificationObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadStateDidChange:)
                                                 name:IJKMPMoviePlayerLoadStateDidChangeNotification
                                               object:_player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackDidFinish:)
                                                 name:IJKMPMoviePlayerPlaybackDidFinishNotification
                                               object:_player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mediaIsPreparedToPlayDidChange:)
                                                 name:IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification
                                               object:_player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackStateDidChange:)
                                                 name:IJKMPMoviePlayerPlaybackStateDidChangeNotification
                                               object:_player];
    // add event handler, for this example, it is `volumeChange:` method
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(volumeChanged:) name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];

}

#pragma mark Remove Movie Notification Handlers

/* Remove the movie notification observers from the movie object. */
-(void)removeMovieNotificationObservers
{
    [[NSNotificationCenter defaultCenter]removeObserver:self name:IJKMPMoviePlayerLoadStateDidChangeNotification object:_player];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:IJKMPMoviePlayerPlaybackDidFinishNotification object:_player];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification object:_player];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:IJKMPMoviePlayerPlaybackStateDidChangeNotification object:_player];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
}
#pragma mark - 内存回收
- (void)deallocPlayer
{
    [self.player shutdown];
    [self.link invalidate];
    // 关闭定时器
    [self.autoDismissTimer invalidate];
    self.autoDismissTimer = nil;
    [self removeMovieNotificationObservers];
}
@end
