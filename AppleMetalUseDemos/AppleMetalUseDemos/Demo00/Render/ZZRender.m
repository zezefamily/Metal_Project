//
//  ZZRender.m
//  AppleMetalUseDemos
//
//  Created by wenmei on 2020/8/19.
//  Copyright © 2020 zezefamily. All rights reserved.
//
//颜色结构体
typedef struct {
    float red, green, blue, alpha;
} Color;



#import "ZZRender.h"

@implementation ZZRender
{
    id<MTLDevice> _device;
    id<MTLCommandQueue> _commandQueue;
}

- (instancetype)initMatalWithMKView:(MTKView *)view
{
    if(self == [super init]){
        _device = view.device;
        _commandQueue = [_device newCommandQueue];
    }
    return self;
}

//设置颜色
- (Color)makeFancyColor
{
    //1. 增加颜色/减小颜色的 标记
    static BOOL       growing = YES;
    //2.颜色通道值(0~3)
    static NSUInteger primaryChannel = 0;
    //3.颜色通道数组colorChannels(颜色值)
    static float      colorChannels[] = {1.0, 0.0, 0.0, 1.0};
    //4.颜色调整步长
    const float DynamicColorRate = 0.015;
    
    //5.判断
    if(growing)
    {
        //动态信道索引 (1,2,3,0)通道间切换
        NSUInteger dynamicChannelIndex = (primaryChannel+1)%3;
        
        //修改对应通道的颜色值 调整0.015
        colorChannels[dynamicChannelIndex] += DynamicColorRate;
        
        //当颜色通道对应的颜色值 = 1.0
        if(colorChannels[dynamicChannelIndex] >= 1.0)
        {
            //设置为NO
            growing = NO;
            
            //将颜色通道修改为动态颜色通道
            primaryChannel = dynamicChannelIndex;
        }
    }
    else
    {
        //获取动态颜色通道
        NSUInteger dynamicChannelIndex = (primaryChannel+2)%3;
        
        //将当前颜色的值 减去0.015
        colorChannels[dynamicChannelIndex] -= DynamicColorRate;
        
        //当颜色值小于等于0.0
        if(colorChannels[dynamicChannelIndex] <= 0.0)
        {
            //又调整为颜色增加
            growing = YES;
        }
    }
    
    //创建颜色
    Color color;
    //修改颜色的RGBA的值
    color.red   = colorChannels[0];
    color.green = colorChannels[1];
    color.blue  = colorChannels[2];
    color.alpha = colorChannels[3];
    
    //返回颜色
    return color;
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{}

- (void)drawInMTKView:(nonnull MTKView *)view
{
    Color color = [self makeFancyColor];
    //设置clearColor
    view.clearColor = MTLClearColorMake(color.red, color.green, color.blue, color.alpha);
    //使用MTLCommandQueue 创建对象并且加入到MTCommandBuffer对象中去.
    //为当前渲染的每个渲染传递创建一个新的命令缓冲区
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"commandBuffer";
    //从视图绘制中,获得渲染描述符
    MTLRenderPassDescriptor *renderPassDes = view.currentRenderPassDescriptor;
    if(renderPassDes != nil){
        //通过渲染描述符renderPassDescriptor创建MTLRenderCommandEncoder 对象
        //相当于openGL中的progrem
        id<MTLCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDes];
        commandEncoder.label = @"commandEncoder";
        //我们可以使用MTLRenderCommandEncoder 来绘制对象,但是这个demo我们仅仅创建编码器就可以了,我们并没有让Metal去执行我们绘制的东西,这个时候表示我们的任务已经完成.
        //即可结束MTLRenderCommandEncoder 工作
        [commandEncoder endEncoding];
        /*
         当编码器结束之后,命令缓存区就会接受到2个命令.
         1) present
         2) commit
         因为GPU是不会直接绘制到屏幕上,因此你不给出去指令.是不会有任何内容渲染到屏幕上.
        */
        //添加一个最后的命令来显示清除的可绘制的屏幕
        [commandBuffer presentDrawable:view.currentDrawable];
    }
    //在这里完成渲染并将命令缓冲区提交给GPU
    [commandBuffer commit];
}

@end
