//
//  ZZRender1.m
//  AppleMetalUseDemos
//
//  Created by wenmei on 2020/8/20.
//  Copyright © 2020 zezefamily. All rights reserved.
//

#import "ZZRender1.h"
#import "ZZShaderTypes.h"

@implementation ZZRender1
{
    id<MTLCommandQueue> _commandQueue;
    id<MTLDevice> _device;
    id<MTLRenderPipelineState> _pipelineState;
    //当前视图大小,这样我们才可以在渲染通道使用这个视图
    vector_uint2 _viewportSize;
}

- (instancetype)initWithMKView:(MTKView *)view
{
    if(self == [super init]){
        //获取GPU
        _device = view.device;
        //开辟命令队列
        _commandQueue = [_device newCommandQueue];
        //创建MTLRenderPipelineState
        //1.载入
//        NSError *error0 = nil;
//        NSString *path = [[NSBundle mainBundle]pathForResource:@"ZZShader" ofType:@"metal"];
//        id<MTLLibrary> library = [_device newLibraryWithFile:path error:&error0];
        id<MTLLibrary> library = [_device newDefaultLibrary];
//        NSAssert(error0, @"着色器文件载入失败");
        id<MTLFunction> vertexFunc = [library newFunctionWithName:@"vertexShader"];
        id<MTLFunction> fragmentFunc = [library newFunctionWithName:@"fragmentShader"];
        //管线描述符
        MTLRenderPipelineDescriptor *pipelineDes = [[MTLRenderPipelineDescriptor alloc]init];
        pipelineDes.label = @"pipelineDes";
        pipelineDes.vertexFunction = vertexFunc;
        pipelineDes.fragmentFunction = fragmentFunc;
        //一组存储颜色数据的组件
        pipelineDes.colorAttachments[0].pixelFormat = view.colorPixelFormat;
        //管线状态
        NSError *error1 = nil;
        _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineDes error:&error1];
        if(error1 != nil){
            NSAssert(error1, @"管线状态对象创建失败");
        }
    }
    return self;
}

- (void)drawInMTKView:(MTKView *)view
{
    Color color = [self makeFancyColor];
    //1. 顶点数据/颜色数据
    ZZVertex triangleVertices[] =
    {
        //顶点,    RGBA 颜色值
        { {  0.5, -0.25, 0.0, 1.0 }, { color.red, color.green, color.blue, 1 } },
        { { -0.5, -0.25, 0.0, 1.0 }, { color.green, color.red, color.blue, 1 } },
        { { -0.0f, 0.25, 0.0, 1.0 }, { color.blue, color.green, color.red, 1 } },
    };
    //从当前队列中读取一个缓冲区
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"commandBuffer";
    //创建/获取 渲染过程描述符
    MTLRenderPassDescriptor  *renderPassDes = view.currentRenderPassDescriptor;
    if(renderPassDes != nil){
        //通过描述符 创建渲染编码器
        id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDes];
        encoder.label = @"renderEncoder";
        //设置视口大小
        MTLViewport viewPort = {
            0.0,0.0,_viewportSize.x,_viewportSize.y,-1.0,1.0
        };
        [encoder setViewport:viewPort];
        //绑定管线state
        [encoder setRenderPipelineState:_pipelineState];
        //添加顶点数据
        [encoder setVertexBytes:triangleVertices length:sizeof(triangleVertices) atIndex:ZZVertexInputIndexVertices];
        [encoder setVertexBytes:&_viewportSize length:sizeof(_viewportSize) atIndex:ZZVertexInputIndexViewportSize];
        //准备绘制
        [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
        //结束编码器
        [encoder endEncoding];
        //present
        [commandBuffer presentDrawable:view.currentDrawable];
    }
    //提价buffer
    [commandBuffer commit];
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size
{
    _viewportSize.x = size.width;
    _viewportSize.y = size.height;
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

@end
