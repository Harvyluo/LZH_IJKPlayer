//
//  XYVideoPlayerView.h
//  SmartClassRoom
//
//  Created by Nowind on 16/4/8.
//  Copyright © 2016年 newcloudnet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
@class XYVideoPlayerView;
@class XYVideoModel;

@protocol XYVideoPlayerViewDelegate <NSObject>
//全屏切换
- (void)fullScreenWithPlayerView:(XYVideoPlayerView *)videoPlayerView;
//返回
- (void)backToBeforeVC;

@end

@interface XYVideoPlayerView : UIView

//视频模型 包括视频的链接和标题
@property(nonatomic, strong) XYVideoModel *videoModel;

@property (assign, nonatomic) BOOL isRotate; //是否全屏

@property (nonatomic, weak) id<XYVideoPlayerViewDelegate>delegate;

//初始化方法
+ (instancetype)videoPlayerView;
//内存回收
- (void)deallocPlayer;

@end
