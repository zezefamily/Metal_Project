//
//  ViewController.m
//  AppleMetalUseDemos
//
//  Created by wenmei on 2020/8/19.
//  Copyright © 2020 zezefamily. All rights reserved.
//

#import "ViewController.h"
#import "Demo00/Render/ZZRender.h"
#import "Demo11/ZZRender1.h"
#import "Demo22/ZZRender2.h"
#import "MetalCaptureController.h"
#import "SampleMetalVideoPlayer.h"
@interface ViewController ()<UIImagePickerControllerDelegate,UINavigationControllerDelegate>
{
    MTKView *_mtkView;
    ZZRender *_render;
    ZZRender1 *_render1;
    ZZRender2 *_render2;
    SampleMetalVideoPlayer *_metalVideoPlayer;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
//    _mtkView = [[MTKView alloc]initWithFrame:self.view.bounds device:MTLCreateSystemDefaultDevice()];
//    [self.view addSubview:_mtkView];
//    if(_mtkView.device == nil){
//        NSLog(@"device create failed !!!");
//        return;
//    }
////    _render = [[ZZRender alloc]initMatalWithMKView:_mtkView];
////    _mtkView.delegate = _render;
////    _render1 = [[ZZRender1 alloc]initWithMKView:_mtkView];
////    _mtkView.delegate = _render1;
//    _render2 = [[ZZRender2 alloc]zzRender2_initWithMTKView:_mtkView];
//    _mtkView.delegate = _render2;
//    [_render2 mtkView:_mtkView drawableSizeWillChange:_mtkView.drawableSize];
    //16:9
    //self.view.frame.size.height :
    CGFloat width = self.view.frame.size.height/16 * 9;
    CGFloat height = self.view.frame.size.height;
    _metalVideoPlayer = [[SampleMetalVideoPlayer alloc]initWithFrame:CGRectMake(self.view.frame.size.width/2 - width/2, 0, width, height)];
    [self.view addSubview:_metalVideoPlayer];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.frame = CGRectMake(0, 0, 100, 100);
    [btn setTitle:@"测试" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(btnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}

- (void)btnClick
{
//    MetalCaptureController *vc = [[MetalCaptureController alloc]init];
//    [self presentViewController:vc animated:YES completion:nil];
//    [self showImagePicker];
    NSURL *pathURL = [[NSBundle mainBundle]URLForResource:@"video" withExtension:@"mp4"];
    [_metalVideoPlayer openSourceWithURL:pathURL];
}

- (void)showImagePicker
{
    UIImagePickerController *imgPickerVC = [[UIImagePickerController alloc]init];
    imgPickerVC.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    imgPickerVC.delegate  = self;
    [self presentViewController:imgPickerVC animated:YES completion:nil];
    
}



@end
