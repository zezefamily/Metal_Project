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
@interface ViewController ()
{
    MTKView *_mtkView;
    ZZRender *_render;
    ZZRender1 *_render1;
    ZZRender2 *_render2;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _mtkView = [[MTKView alloc]initWithFrame:self.view.bounds device:MTLCreateSystemDefaultDevice()];
    [self.view addSubview:_mtkView];
    if(_mtkView.device == nil){
        NSLog(@"device create failed !!!");
        return;
    }
//    _render = [[ZZRender alloc]initMatalWithMKView:_mtkView];
//    _mtkView.delegate = _render;
//    _render1 = [[ZZRender1 alloc]initWithMKView:_mtkView];
//    _mtkView.delegate = _render1;
    _render2 = [[ZZRender2 alloc]zzRender2_initWithMTKView:_mtkView];
    _mtkView.delegate = _render2;
    
    [_render2 mtkView:_mtkView drawableSizeWillChange:_mtkView.drawableSize];
}


@end
