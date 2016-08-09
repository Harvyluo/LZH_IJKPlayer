//
//  ZYLButton.h
//  IJKPlayerDemo
//
//  Created by lzh on 16/7/22.
//  Copyright © 2016年 lzh. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LZHButtonDelegate <NSObject>

/**
 * 开始触摸
 */
- (void)touchesBeganWithPoint:(CGPoint)point;

/**
 * 结束触摸
 */
- (void)touchesEndWithPoint:(CGPoint)point;

/**
 * 移动手指
 */
- (void)touchesMoveWithPoint:(CGPoint)point;

@end

@interface LZHButton : UIButton

/**
 * 传递点击事件的代理
 */
@property (weak, nonatomic) id <LZHButtonDelegate> touchDelegate;

@end
