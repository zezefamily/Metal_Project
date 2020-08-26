//
//  ZZRender2.m
//  AppleMetalUseDemos
//
//  Created by wenmei on 2020/8/25.
//  Copyright © 2020 zezefamily. All rights reserved.
//

#import "ZZRender2.h"
#import "ZZShaderTypes.h"
@implementation ZZRender2
{
    id<MTLCommandQueue> _commandQueue;
    id<MTLDevice> _device;
    id<MTLRenderPipelineState> _renderPipelineState;
    //视口
    vector_uint2 _viewportSize;
    //顶点个数
    NSInteger _numVertices;
    //顶点缓存区
    id<MTLBuffer> _vertexBuffer;
    //纹理
    id<MTLTexture> _texTure;
}

- (instancetype)zzRender2_initWithMTKView:(MTKView *)mtkView
{
    if(self == [super init]){
        
        mtkView.colorPixelFormat = MTLPixelFormatBGRA8Unorm_sRGB;
        
        _device = mtkView.device;
        _commandQueue = [_device newCommandQueue];
        
        id<MTLLibrary> library = [_device newDefaultLibrary];
        id<MTLFunction> vertexFunc = [library newFunctionWithName:@"vertexFunc22"];
        id<MTLFunction> fragmentFunc = [library newFunctionWithName:@"fragmentFunc22"];
        
        MTLRenderPipelineDescriptor *pipelineDes = [[MTLRenderPipelineDescriptor alloc]init];
        pipelineDes.label = @"pipelineDes";
        pipelineDes.vertexFunction = vertexFunc;
        pipelineDes.fragmentFunction = fragmentFunc;
        pipelineDes.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat;
        NSError *error0;
        _renderPipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineDes error:&error0];
        if(error0){
            NSLog(@"_renderPipelineStatec 创建失败");
            return nil;
        }
        //初始化顶点
        [self setupVertex];
        //初始化纹理
        [self setupTexturePNG];
//        //构造一些顶点假数据
//        NSData *vertexData = [ZZRender2 generateVertexData];
//        _vertexBuffer = [_device newBufferWithBytes:vertexData.bytes length:vertexData.length options:MTLResourceStorageModeShared];
//        memcpy(_vertexBuffer.contents, vertexData.bytes, vertexData.length);
//        //计算顶点个数 = 顶点数据长度 / 单个顶点大小
//        _numVertices = vertexData.length / sizeof(ZZVertex2);
        
    }
    return self;
}

- (void)setupTexturePNG
{
    UIImage *image = [UIImage imageNamed:@"launchIcon"];
    MTLTextureDescriptor *textureDes = [[MTLTextureDescriptor alloc]init];
    textureDes.pixelFormat = MTLPixelFormatBGRA8Unorm;
    textureDes.width = image.size.width;
    textureDes.height = image.size.height;
    _texTure = [_device newTextureWithDescriptor:textureDes];
    //MLRegion结构用于标识纹理的特定区域。 demo使用图像数据填充整个纹理；因此，覆盖整个纹理的像素区域等于纹理的尺寸。
    //4. 创建MTLRegion 结构体  [纹理上传的范围]
    MTLRegion region = {
        { 0, 0, 0 },
        {image.size.width, image.size.height, 1}
    };
    Byte *imageData = [self loadImage:image];
    if(imageData != nil){
        [_texTure replaceRegion:region mipmapLevel:0 withBytes:imageData bytesPerRow:image.size.width * 4];
        free(imageData);
        imageData = NULL;
    }
}

-(void)setupVertex
{
    //1.根据顶点/纹理坐标建立一个MTLBuffer
    static const ZZVertex3 quadVertices[] = {
        //像素坐标,纹理坐标
        { {  10,  -10 },  { 1.f, 0.f } },
        { { -10,  -10 },  { 0.f, 0.f } },
        { { -10,   10 },  { 0.f, 1.f } },
        
        { {  10,  -10 },  { 1.f, 0.f } },
        { { -10,   10 },  { 0.f, 1.f } },
        { {  10,   10 },  { 1.f, 1.f } },
    };
    
    //2.创建我们的顶点缓冲区，并用我们的Qualsits数组初始化它
    _vertexBuffer = [_device newBufferWithBytes:quadVertices
                                     length:sizeof(quadVertices)
                                    options:MTLResourceStorageModeShared];
    //3.通过将字节长度除以每个顶点的大小来计算顶点的数目
    _numVertices = sizeof(quadVertices) / sizeof(ZZVertex3);
}


//从UIImage 中读取Byte 数据返回
- (Byte *)loadImage:(UIImage *)image {
    // 1.获取图片的CGImageRef
     CGImageRef spriteImage = image.CGImage;
     
     // 2.读取图片的大小
     size_t width = CGImageGetWidth(spriteImage);
     size_t height = CGImageGetHeight(spriteImage);
    
     //3.计算图片大小.rgba共4个byte
     Byte * spriteData = (Byte *) calloc(width * height * 4, sizeof(Byte));
     
     //4.创建画布
     CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4, CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
     
     //5.在CGContextRef上绘图
     CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
     
     //6.图片翻转过来
     CGRect rect = CGRectMake(0, 0, width, height);
     CGContextTranslateCTM(spriteContext, rect.origin.x, rect.origin.y);
     CGContextTranslateCTM(spriteContext, 0, rect.size.height);
     CGContextScaleCTM(spriteContext, 1.0, -1.0);
     CGContextTranslateCTM(spriteContext, -rect.origin.x, -rect.origin.y);
     CGContextDrawImage(spriteContext, rect, spriteImage);
     
     //7.释放spriteContext
     CGContextRelease(spriteContext);
     
     return spriteData;
}


- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size
{
    _viewportSize.x = size.width;
    _viewportSize.y = size.height;
}

- (void)drawInMTKView:(MTKView *)view
{
    id<MTLCommandBuffer> _commandBuffer = [_commandQueue commandBuffer];
    _commandBuffer.label = @"_commandBuffer";
    MTLRenderPassDescriptor *renderPassDes = view.currentRenderPassDescriptor;
    if(renderPassDes != nil){
        id<MTLRenderCommandEncoder> renderCommandEnconder = [_commandBuffer renderCommandEncoderWithDescriptor:renderPassDes];
        renderCommandEnconder.label = @"renderCommandEnconder";
        [renderCommandEnconder setViewport:(MTLViewport){0.0, 0.0, _viewportSize.x, _viewportSize.y, -1.0, 1.0 }];
        [renderCommandEnconder setRenderPipelineState:_renderPipelineState];
        [renderCommandEnconder setVertexBuffer:_vertexBuffer offset:0 atIndex:ZZVertexInputIndexVertices22];
        [renderCommandEnconder setVertexBytes:&_viewportSize length:sizeof(_viewportSize) atIndex:ZZVertexInputIndexViewportSize22];
        [renderCommandEnconder setFragmentTexture:_texTure atIndex:ZZTextureIndexBaseColor];
        [renderCommandEnconder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:_numVertices];
        [renderCommandEnconder endEncoding];
        [_commandBuffer presentDrawable:view.currentDrawable];
    }
    [_commandBuffer commit];
}

//顶点数据
+ (nonnull NSData *)generateVertexData
{
    //1.正方形 = 三角形+三角形
    const ZZVertex2 quadVertices[] =
    {
        // Pixel 位置, RGBA 颜色
        { { -20,   20 },    { 1, 0, 0, 1 } },
        { {  20,   20 },    { 1, 0, 0, 1 } },
        { { -20,  -20 },    { 1, 0, 0, 1 } },
        
        { {  20,  -20 },    { 0, 0, 1, 1 } },
        { { -20,  -20 },    { 0, 0, 1, 1 } },
        { {  20,   20 },    { 0, 0, 1, 1 } },
    };
    //行/列 数量
    const NSUInteger NUM_COLUMNS = 25;
    const NSUInteger NUM_ROWS = 15;
    //顶点个数
    const NSUInteger NUM_VERTICES_PER_QUAD = sizeof(quadVertices) / sizeof(ZZVertex2);
    //四边形间距
    const float QUAD_SPACING = 50.0;
    //数据大小 = 单个四边形大小 * 行 * 列
    NSUInteger dataSize = sizeof(quadVertices) * NUM_COLUMNS * NUM_ROWS;
    
    //2. 开辟空间
    NSMutableData *vertexData = [[NSMutableData alloc] initWithLength:dataSize];
    //当前四边形
    ZZVertex2 * currentQuad = vertexData.mutableBytes;
    
    
    //3.获取顶点坐标(循环计算)
    //行
    for(NSUInteger row = 0; row < NUM_ROWS; row++)
    {
        //列
        for(NSUInteger column = 0; column < NUM_COLUMNS; column++)
        {
            //A.左上角的位置
            vector_float2 upperLeftPosition;
            
            //B.计算X,Y 位置.注意坐标系基于2D笛卡尔坐标系,中心点(0,0),所以会出现负数位置
            upperLeftPosition.x = ((-((float)NUM_COLUMNS) / 2.0) + column) * QUAD_SPACING + QUAD_SPACING/2.0;
            
            upperLeftPosition.y = ((-((float)NUM_ROWS) / 2.0) + row) * QUAD_SPACING + QUAD_SPACING/2.0;
            
            //C.将quadVertices数据复制到currentQuad
            memcpy(currentQuad, &quadVertices, sizeof(quadVertices));
            
            //D.遍历currentQuad中的数据
            for (NSUInteger vertexInQuad = 0; vertexInQuad < NUM_VERTICES_PER_QUAD; vertexInQuad++)
            {
                //修改vertexInQuad中的position
                currentQuad[vertexInQuad].position += upperLeftPosition;
            }
            
            //E.更新索引
            currentQuad += 6;
        }
    }
    
    return vertexData;
    
}

@end
