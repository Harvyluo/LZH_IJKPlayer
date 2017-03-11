# LZH_IJKPlayer
LZH_IJKPlayer
1、先看Demo

  将箭头所指的两个文件夹添加到你的工程中。ijkplayer已经打包成framework了，就是图中的IJKMediaFramework
  当然以下几个依赖包，肯定是要你重新手动添加的啦。相信大家知道在哪里添加，我就不一一赘述啦。

    

     2、如何使用？再看DEMO

    我把视频播放的视图添加在下面这个控制器中。

    

   打开.m文件，需要实现的跟视频相关的代码如下。

    //初始化视频播放控制器  

    self.playerView = [XYVideoPlayerView videoPlayerView];

    self.playerView.delegate = self;

    [_headPlayerView addSubview:self.playerView];

    self.playerView = self.playerView;

   //视频的Model，将视频地址和视频文件的名称作为Model

    XYVideoModel *model = [[XYVideoModel alloc]init];

    model.url = [NSURL URLWithString:@"http://bos.nj.bpc.baidu.com/tieba-smallvideo/11772_3c435014fb2dd9a5fd56a57cc369f6a.mp4"];

    model.name = @"video1";

    self.playerView.videoModel = model;

 

//点击全屏按钮的代理事件   

- (void)fullScreenWithPlayerView:(XYVideoPlayerView *)videoPlayerView

{

    if (self.playerView.isRotate) {

        [UIView animateWithDuration:0.3 animations:^{

            _headPlayerView.transform = CGAffineTransformRotate(_headPlayerView.transform, M_PI_2);

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

//点击返回按钮的代理事件   

- (void)backToBeforeVC{

    

    if (!self.playerView.isRotate) {

    

        [self.navigationController popViewControllerAnimated:YES];

    }

}

//控制器销毁时必须要实现的方法。 

- (void)dealloc{

    

    [self.playerView deallocPlayer];

}

     3、说明

     播放器实现了左半边屏幕上下滑动调节亮度，右半边屏幕，上下滑动调节音量，左右滑动是快进和快退。

     Github源码地址：https://github.com/Harvyluo/LZH_IJKPlayer

   以上就是该播放器的集成过程，使用中有什么问题，可以加官方群。群号：156760711 （LZH_IJKPlayer交流群）
