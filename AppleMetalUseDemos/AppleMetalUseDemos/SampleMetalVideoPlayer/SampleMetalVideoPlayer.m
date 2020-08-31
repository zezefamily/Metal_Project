//
//  SampleMetalVideoPlayer.m
//  AppleMetalUseDemos
//
//  Created by 泽泽 on 2020/8/27.
//  Copyright © 2020 zezefamily. All rights reserved.
//

#import "SampleMetalVideoPlayer.h"
@import MetalPerformanceShaders;
#import "ZZAssetReader.h"
#import "SampleMetalTypes.h"
@interface SampleMetalVideoPlayer ()<MTKViewDelegate>
{
    CADisplayLink *_displayLink;
    NSUInteger _numVertices;
}
//mtkView
@property (nonatomic,strong) MTKView *mtkView;
//命令队列
@property (nonatomic,strong) id<MTLCommandQueue> commandQueue;
//GPU设备
@property (nonatomic,strong) id<MTLDevice> device;
//纹理缓冲区
@property (nonatomic,assign) CVMetalTextureCacheRef textureCache;
//viewportSize 视口大小
@property (nonatomic, assign) vector_uint2 viewportSize;
//顶点缓冲区
@property (nonatomic,strong) id<MTLBuffer> vertices;
//YUV->RGB转换矩阵
@property (nonatomic,strong) id<MTLBuffer> convertMatrix;
//渲染管线
@property (nonatomic,strong) id<MTLRenderPipelineState> renderPipelineState;
//ZZAssetReader
@property (nonatomic,strong) ZZAssetReader *assetReader;
@end
@implementation SampleMetalVideoPlayer

- (instancetype)initWithFrame:(CGRect)frame
{
    if(self == [super initWithFrame:frame]){
//        self.backgroundColor = [UIColor lightGrayColor];
        [self setupMTKit];
        [self setupVertex];
        [self setupMatrix];
    }
    return self;
}

// 设置YUV->RGB转换的矩阵
- (void)setupMatrix
{
    //1.转化矩阵 (固定参数,根据需求而定 SDTV/FULL_RANGE_HDTV)
    // BT.601, which is the standard for SDTV.
//    matrix_float3x3 kColorConversion601DefaultMatrix = (matrix_float3x3){
//        (simd_float3){1.164,  1.164, 1.164},
//        (simd_float3){0.0, -0.392, 2.017},
//        (simd_float3){1.596, -0.813,   0.0},
//    };
    // BT.601 full range
    matrix_float3x3 kColorConversion601FullRangeMatrix = (matrix_float3x3){
        (simd_float3){1.0,    1.0,    1.0},
        (simd_float3){0.0,    -0.343, 1.765},
        (simd_float3){1.4,    -0.711, 0.0},
    };
    // BT.709, which is the standard for HDTV.
//    matrix_float3x3 kColorConversion709DefaultMatrix[] = {
//        (simd_float3){1.164,  1.164, 1.164},
//        (simd_float3){0.0, -0.213, 2.112},
//        (simd_float3){1.793, -0.533,   0.0},
//    };
    //偏移量(固定参数)跟矩阵一一对应关系 601FullRange
    vector_float3 kColorConversion601FullRangeOffset = (vector_float3){ -(16.0/255.0), -0.5, -0.5};
    //创建转换矩阵
    SampleConvertMatrix matrix;
    matrix.matrix = kColorConversion601FullRangeMatrix;
    matrix.offset = kColorConversion601FullRangeOffset;
    self.convertMatrix = [self.mtkView.device newBufferWithBytes:&matrix length:sizeof(SampleConvertMatrix) options:MTLResourceStorageModeShared];
}
- (void)setupAsset
{
    NSURL *url = [[NSBundle mainBundle]URLForResource:@"video" withExtension:@"mp4"];
    self.assetReader = [[ZZAssetReader alloc]initWithURL:url];
    
}

- (void)setupVertex
{
    static const SampleVertex quadVertices[] =
    {   // 顶点坐标，分别是x、y、z、w；    纹理坐标，x、y；
        { {  1.0, -1.0, 0.0, 1.0 },  { 1.f, 1.f } },
        { { -1.0, -1.0, 0.0, 1.0 },  { 0.f, 1.f } },
        { { -1.0,  1.0, 0.0, 1.0 },  { 0.f, 0.f } },
        
        { {  1.0, -1.0, 0.0, 1.0 },  { 1.f, 1.f } },
        { { -1.0,  1.0, 0.0, 1.0 },  { 0.f, 0.f } },
        { {  1.0,  1.0, 0.0, 1.0 },  { 1.f, 0.f } },
    };
    self.vertices = [self.mtkView.device newBufferWithBytes:quadVertices length:sizeof(quadVertices) options:MTLResourceStorageModeShared];
    _numVertices = sizeof(quadVertices) / sizeof(SampleVertex);
}

- (void)setupMTKit
{
    //视图
    self.mtkView = [[MTKView alloc]initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height) device:MTLCreateSystemDefaultDevice()];
    self.mtkView.delegate = self;
//    self.mtkView.framebufferOnly = NO;
    [self addSubview:self.mtkView];
    //获取视口size
    self.viewportSize = (vector_uint2){self.mtkView.drawableSize.width,self.mtkView.drawableSize.height};
    //commandQueue
    self.commandQueue = [self.mtkView.device newCommandQueue];
    //renderPipelineState
    id<MTLLibrary> library = [self.mtkView.device newDefaultLibrary];
    id<MTLFunction> vertexFunc = [library newFunctionWithName:@"sampleVertexShader"];
    id<MTLFunction> fragmentFunc = [library newFunctionWithName:@"sampleFragmentShader"];
    MTLRenderPipelineDescriptor *pipelineDes = [[MTLRenderPipelineDescriptor alloc]init];
    pipelineDes.vertexFunction = vertexFunc;
    pipelineDes.fragmentFunction = fragmentFunc;
    pipelineDes.colorAttachments[0].pixelFormat = self.mtkView.colorPixelFormat;
    self.renderPipelineState = [self.mtkView.device newRenderPipelineStateWithDescriptor:pipelineDes error:NULL];
    //创建纹理缓冲区
    CVMetalTextureCacheCreate(NULL, NULL, self.mtkView.device, NULL, &_textureCache);
    
}

- (void)openSourceWithURL:(NSURL *)URL
{
    self.assetReader = [[ZZAssetReader alloc]initWithURL:URL];
}

- (void)drawInMTKView:(MTKView *)view
{
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    MTLRenderPassDescriptor *renderPassDes = view.currentRenderPassDescriptor;
    //从assetReader中读取帧
    CMSampleBufferRef sampleBuffer = [self.assetReader readBuffer];
    if(sampleBuffer && renderPassDes){
        renderPassDes.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.5, 0.5, 1.0);
        id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDes];
        //设置视口
        [renderEncoder setViewport:(MTLViewport){0.0,0.0,self.viewportSize.x,self.viewportSize.y,-1.0,1.0}];
        //设置管线
        [renderEncoder setRenderPipelineState:self.renderPipelineState];
        //传入顶点
        [renderEncoder setVertexBuffer:self.vertices offset:0 atIndex:SampleVertexInputIndexVertices];
        //传入纹理
        [self setupTextureWithEncoder:renderEncoder buffer:sampleBuffer];
        //传入矩阵
        [renderEncoder setFragmentBuffer:self.convertMatrix offset:0 atIndex:SampleFragmentBufferIndexMatrix];
        //绘制
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:_numVertices];
        //end
        [renderEncoder endEncoding];
        //present
        [commandBuffer presentDrawable:view.currentDrawable];
    }
    [commandBuffer commit];
}
- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size
{
    self.viewportSize = (vector_uint2){size.width,size.height};
}

- (void)setupTextureWithEncoder:(id<MTLRenderCommandEncoder>)encoder buffer:(CMSampleBufferRef)sampleBuffer
{
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    id<MTLTexture> textureY = nil;
    id<MTLTexture> textureUV = nil;
    
    //获取Y纹理
    {
        size_t width = CVPixelBufferGetWidthOfPlane(pixelBuffer,0);
        size_t height = CVPixelBufferGetHeightOfPlane(pixelBuffer,0);
        //像素格式
        MTLPixelFormat pixelFormat = MTLPixelFormatR8Unorm;
        //创建Metal纹理
        CVMetalTextureRef texture = NULL;
        CVReturn status = CVMetalTextureCacheCreateTextureFromImage(NULL, self.textureCache, pixelBuffer, NULL, pixelFormat, width, height, 0, &texture);
        if(status == kCVReturnSuccess){
            //转成metal纹理
            textureY = CVMetalTextureGetTexture(texture);
            CFRelease(texture);
        }
    }
    //获取UV纹理
    {
        size_t width = CVPixelBufferGetWidthOfPlane(pixelBuffer,1);
        size_t height = CVPixelBufferGetHeightOfPlane(pixelBuffer,1);
        //像素格式
        MTLPixelFormat pixelFormat = MTLPixelFormatRG8Unorm;
        //创建Metal纹理
        CVMetalTextureRef texture = NULL;
        CVReturn status = CVMetalTextureCacheCreateTextureFromImage(NULL, self.textureCache, pixelBuffer, NULL, pixelFormat, width, height, 1, &texture);
        if(status == kCVReturnSuccess){
            //转成metal纹理
            textureUV = CVMetalTextureGetTexture(texture);
            CFRelease(texture);
        }
    }
    //判断是否读取成功
    if(textureY != nil && textureUV != nil){
        [encoder setFragmentTexture:textureY atIndex:SampleFragmentTextureIndexTextureY];
        [encoder setFragmentTexture:textureUV atIndex:SampleFragmentTextureIndexTextureUV];
    }

    CFRelease(sampleBuffer);
}


@end

