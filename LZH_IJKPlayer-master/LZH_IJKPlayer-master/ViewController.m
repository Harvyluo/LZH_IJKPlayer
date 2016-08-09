//
//  ViewController.m
//  LZH_IJKPlayer-master
//
//  Created by lzh on 16/8/9.
//  Copyright © 2016年 lzh. All rights reserved.
//

#import "ViewController.h"

#import "VideoPlayViewController.h"

@interface ViewController ()

@property (nonatomic, strong) UIButton *enterBtn;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.enterBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.enterBtn.frame = CGRectMake(100, 100, 100, 80);
    [self.enterBtn setTitle:@"跳转播放" forState:UIControlStateNormal];
    [self.enterBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [self.enterBtn addTarget:self action:@selector(enterBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.enterBtn];
}

- (void)enterBtnClicked:(id)sender {
    
    VideoPlayViewController *vc = [[VideoPlayViewController alloc]init];
    [self.navigationController pushViewController:vc animated:YES];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end
