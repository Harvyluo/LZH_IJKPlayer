//
//  VideoPlayViewController.m
//  LZHPlayer
//
//  Created by lzh on 16/8/9.
//  Copyright © 2016年 lzh. All rights reserved.
//

#import "XYVideoPlayerView.h"
#import "XYVideoModel.h"

#import "Masonry.h"

#import "VideoPlayViewController.h"

@interface VideoPlayViewController ()<XYVideoPlayerViewDelegate>
{
    UIView *_headPlayerView;
}

@property (weak, nonatomic) IBOutlet UIView *videoBackView;
@property (weak, nonatomic) IBOutlet UIButton *btn1;

/** 视频播放视图 */
@property (nonatomic, strong) XYVideoPlayerView *playerView;

@end

@implementation VideoPlayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setUI];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}
//状态栏显示控制
- (BOOL)prefersStatusBarHidden {
    return YES;//隐藏为YES，显示为NO
}
- (void)setUI{
    
    // 创建视频播放控件
    _headPlayerView = [[UIView alloc]initWithFrame:CGRectMake(0, 0,  [UIScreen mainScreen].bounds.size.width,  [UIScreen mainScreen].bounds.size.width*9/16)];
    [self.view addSubview:_headPlayerView];
    
    self.playerView = [XYVideoPlayerView videoPlayerView];
    self.playerView.delegate = self;
    [_headPlayerView addSubview:self.playerView];
    self.playerView = self.playerView;
    
    XYVideoModel *model = [[XYVideoModel alloc]init];
    model.url = [NSURL URLWithString:@"http://bos.nj.bpc.baidu.com/tieba-smallvideo/11772_3c435014fb2dd9a5fd56a57cc369f6a.mp4"];
    model.name = @"video1";
    self.playerView.videoModel = model;
    //[self.playerView changeCurrentplayerItemWithVideoModel:model];
    
}
- (IBAction)btnClicked:(UIButton *)sender {
    
    if (sender.tag==100) {
        
        XYVideoModel *model = [[XYVideoModel alloc]init];
        model.url = [NSURL URLWithString:@"http://bos.nj.bpc.baidu.com/tieba-smallvideo/11772_3c435014fb2dd9a5fd56a57cc369f6a0.mp4"];
        model.name = @"video1";
        self.playerView.videoModel = model;
        
    }else if(sender.tag==101){
        
        XYVideoModel *model = [[XYVideoModel alloc]init];
        model.url = [NSURL URLWithString:@"http://bos.nj.bpc.baidu.com/tieba-smallvideo/11772_3c435014fb2dd9a5fd56a57cc369f6a0.mp4"];
        model.name = @"video2";
        self.playerView.videoModel = model;
    }
}
#pragma mark XYVideoPlayerViewDelegate
- (void)fullScreenWithPlayerView:(XYVideoPlayerView *)videoPlayerView
{
    if (self.playerView.isRotate) {
        [UIView animateWithDuration:0.3 animations:^{
            _headPlayerView.transform = CGAffineTransformRotate(self.videoBackView.transform, M_PI_2);
            _headPlayerView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
            self.playerView.frame = _headPlayerView.bounds;
            
        }];
        
    }else{
        
        [UIView animateWithDuration:0.3 animations:^{
            _headPlayerView.transform = CGAffineTransformIdentity;
            _headPlayerView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.width*9/16);
            self.playerView.frame = _headPlayerView.bounds;
        }];
        
    }
}
- (void)backToBeforeVC{
    
    if (!self.playerView.isRotate) {
    
        [self.navigationController popViewControllerAnimated:YES];
    }
}
- (void)dealloc{
    
    [self.playerView deallocPlayer];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
