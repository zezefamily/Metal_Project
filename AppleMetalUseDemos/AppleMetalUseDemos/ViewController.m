//
//  ViewController.m
//  AppleMetalUseDemos
//
//  Created by wenmei on 2020/8/19.
//  Copyright © 2020 zezefamily. All rights reserved.
//

#import "ViewController.h"
#import "Demo00/Render/ZZRender.h"

@interface ViewController ()
{
    MTKView *_mtkView;
    ZZRender *_render;
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
    _render = [[ZZRender alloc]initMatalWithMKView:_mtkView];
    _mtkView.delegate = _render;
}


@end
