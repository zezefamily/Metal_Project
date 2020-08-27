//
//  MetalCaptureController.m
//  AppleMetalUseDemos
//
//  Created by 泽泽 on 2020/8/27.
//  Copyright © 2020 zezefamily. All rights reserved.
//

#import "MetalCaptureController.h"
@import MetalKit;
@import MetalPerformanceShaders;
@import AVFoundation;
@import CoreVideo;
@interface MetalCaptureController ()<AVCaptureVideoDataOutputSampleBufferDelegate,MTKViewDelegate>
@property (nonatomic,strong) MTKView *mtkView;
@property (nonatomic,strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic,strong) id<MTLDevice> device;

//纹理缓冲区
@property (nonatomic,assign) CVMetalTextureCacheRef textureCache;

@property (nonatomic,strong) AVCaptureSession *captureSession;
@property (nonatomic,strong) AVCaptureDeviceInput *videoInput;
@property (nonatomic,strong) AVCaptureVideoDataOutput *videoDataOutput;

//纹理
@property (nonatomic, strong) id<MTLTexture> texture;

@end

@implementation MetalCaptureController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self loadRender];
    [self loadCapture];
    
}

- (void)loadRender
{
    self.mtkView = [[MTKView alloc]initWithFrame:self.view.bounds device:MTLCreateSystemDefaultDevice()];
    [self.view addSubview:self.mtkView];
//    self.mtkView.colorPixelFormat = MTLPixelFormatRGBA8Unorm;
    self.device = self.mtkView.device;
    self.commandQueue = [self.device newCommandQueue];
    self.mtkView.delegate = self;
    //注意: 在初始化MTKView 的基本操作以外. 还需要多下面2行代码.
    /*
     1. 设置MTKView 的drawable 纹理是可读写的(默认是只读);
     2. 创建CVMetalTextureCacheRef _textureCache; 这是Core Video的Metal纹理缓存
     */
    //允许读写操作
    self.mtkView.framebufferOnly = NO;
    /*
    CVMetalTextureCacheCreate(CFAllocatorRef  allocator,
    CFDictionaryRef cacheAttributes,
    id <MTLDevice>  metalDevice,
    CFDictionaryRef  textureAttributes,
    CVMetalTextureCacheRef * CV_NONNULL cacheOut )
    功能: 创建纹理缓存区
    参数1: allocator 内存分配器.默认即可.NULL
    参数2: cacheAttributes 缓存区行为字典.默认为NULL
    参数3: metalDevice
    参数4: textureAttributes 缓存创建纹理选项的字典. 使用默认选项NULL
    参数5: cacheOut 返回时，包含新创建的纹理缓存。
    */
    CVMetalTextureCacheCreate(NULL, NULL, self.device, NULL, &_textureCache);
}
- (void)loadCapture
{
    //初始化会话
    self.captureSession = [[AVCaptureSession alloc]init];
    self.captureSession.sessionPreset = AVCaptureSessionPreset640x480;
    //获取摄像头设备
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *videoDevice = nil;
    for(AVCaptureDevice *device in devices){
        if(device.position == AVCaptureDevicePositionBack){
            videoDevice = device;
        }
    }
    //初始化输入对象
    self.videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:nil];
    if([self.captureSession canAddInput:self.videoInput]){
        [self.captureSession addInput:self.videoInput];
    }
    //初始化输出设备
    dispatch_queue_t queue = dispatch_queue_create("capture_queue", DISPATCH_QUEUE_SERIAL);
    self.videoDataOutput = [[AVCaptureVideoDataOutput alloc]init];
    [self.videoDataOutput setSampleBufferDelegate:self queue:queue];
    if([self.captureSession canAddOutput:self.videoDataOutput]){
        [self.captureSession addOutput:self.videoDataOutput];
    }
    /*设置视频帧延迟到底时是否丢弃数据.
    YES: 处理现有帧的调度队列在captureOutput:didOutputSampleBuffer:FromConnection:Delegate方法中被阻止时，对象会立即丢弃捕获的帧。
    NO: 在丢弃新帧之前，允许委托有更多的时间处理旧帧，但这样可能会内存增加.
    */
    self.videoDataOutput.alwaysDiscardsLateVideoFrames = NO;
    self.videoDataOutput.videoSettings = @{
        (id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA)
    };
    //建立连接
    AVCaptureConnection *connection = [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    //设置方向
    [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
//    AVCaptureVideoPreviewLayer
    //开始捕获
    [self.captureSession startRunning];
    
}
#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    //1.从sampleBuffer 获取视频像素缓存区对象
    CVPixelBufferRef pixelBufferRef = CMSampleBufferGetImageBuffer(sampleBuffer);
    //宽高
    size_t width = CVPixelBufferGetWidth(pixelBufferRef);
    size_t height = CVPixelBufferGetHeight(pixelBufferRef);
    /*根据视频像素缓存区 创建 Metal 纹理缓存区
    CVReturn CVMetalTextureCacheCreateTextureFromImage(CFAllocatorRef allocator,                         CVMetalTextureCacheRef textureCache,
    CVImageBufferRef sourceImage,
    CFDictionaryRef textureAttributes,
    MTLPixelFormat pixelFormat,
    size_t width,
    size_t height,
    size_t planeIndex,
    CVMetalTextureRef  *textureOut);
    
    功能: 从现有图像缓冲区创建核心视频Metal纹理缓冲区。
    参数1: allocator 内存分配器,默认kCFAllocatorDefault
    参数2: textureCache 纹理缓存区对象
    参数3: sourceImage 视频图像缓冲区
    参数4: textureAttributes 纹理参数字典.默认为NULL
    参数5: pixelFormat 图像缓存区数据的Metal 像素格式常量.注意如果MTLPixelFormatBGRA8Unorm和摄像头采集时设置的颜色格式不一致，则会出现图像异常的情况；
    参数6: width,纹理图像的宽度（像素）
    参数7: height,纹理图像的高度（像素）
    参数8: planeIndex.如果图像缓冲区是平面的，则为映射纹理数据的平面索引。对于非平面图像缓冲区忽略。
    参数9: textureOut,返回时，返回创建的Metal纹理缓冲区。
    
    // Mapping a BGRA buffer:
    CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCache, pixelBuffer, NULL, MTLPixelFormatBGRA8Unorm, width, height, 0, &outTexture);
    
    // Mapping the luma plane of a 420v buffer:
    CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCache, pixelBuffer, NULL, MTLPixelFormatR8Unorm, width, height, 0, &outTexture);
    
    // Mapping the chroma plane of a 420v buffer as a source texture:
    CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCache, pixelBuffer, NULL, MTLPixelFormatRG8Unorm width/2, height/2, 1, &outTexture);
    
    // Mapping a yuvs buffer as a source texture (note: yuvs/f and 2vuy are unpacked and resampled -- not colorspace converted)
    CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCache, pixelBuffer, NULL, MTLPixelFormatGBGR422, width, height, 1, &outTexture);
    */
    CVMetalTextureRef tmpTexture = NULL;
    CVReturn status = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.textureCache, pixelBufferRef, NULL, MTLPixelFormatBGRA8Unorm, width, height, 0, &tmpTexture);
    if(status == kCVReturnSuccess){
        self.mtkView.drawableSize = CGSizeMake(width, height);
        self.texture = CVMetalTextureGetTexture(tmpTexture);
        CFRelease(tmpTexture);
    }
}

#pragma mark - MTKViewDelegate
- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size
{
    
}
- (void)drawInMTKView:(MTKView *)view
{
    if(self.texture){
        id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
        //获取mtkView 当前可绘制 目标对象
        id<MTLTexture> drawingTexture = view.currentDrawable.texture;
        //设置个滤镜 MetalPerformanceShaders
        MPSImageGaussianBlur *filter = [[MPSImageGaussianBlur alloc]initWithDevice:self.mtkView.device sigma:1];
        [filter encodeToCommandBuffer:commandBuffer sourceTexture:self.texture destinationTexture:drawingTexture];
        [commandBuffer presentDrawable:view.currentDrawable];
        [commandBuffer commit];
        self.texture = NULL;
    }
}

@end
