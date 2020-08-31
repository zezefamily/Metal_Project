//
//  ZZAssetReader.m
//  AppleMetalUseDemos
//
//  Created by 泽泽 on 2020/8/31.
//  Copyright © 2020 zezefamily. All rights reserved.
//

#import "ZZAssetReader.h"

@implementation ZZAssetReader
{
    //轨道
    AVAssetReaderTrackOutput *_readerVideoTrackOutput;
    //AVAssetReader
    AVAssetReader *_assetReader;
    NSURL *_videoURL;
}

- (instancetype)initWithURL:(NSURL *)URL
{
    if(self == [super init]){
        _videoURL = URL;
        [self loadAsset];
    }
    return self;
}

- (void)loadAsset
{
    NSDictionary *inputOptions = @{ AVURLAssetPreferPreciseDurationAndTimingKey : @YES };
    AVURLAsset *inputAsset = [[AVURLAsset alloc]initWithURL:_videoURL options:inputOptions];
    
    __weak typeof(self) weakSelf = self;
    //异步载入Asset资源，成功后再进行处理
    [inputAsset loadValuesAsynchronouslyForKeys:@[@"tracks"] completionHandler:^{
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSError *error = nil;
            AVKeyValueStatus tracksStatus = [inputAsset statusOfValueForKey:@"tracks" error:&error];
            if(tracksStatus != AVKeyValueStatusLoaded){
                NSLog(@"error:%@",error);
                return;
            }
            [weakSelf processWithAsset:inputAsset];
        });
    }];
    
}

- (void)processWithAsset:(AVAsset *)asset
{
    @synchronized (self) {
        NSError *error = nil;
        _assetReader = [AVAssetReader assetReaderWithAsset:asset error:&error];
        if(error){
            NSLog(@"error:%@",error);
            return;
        }
        NSDictionary *settings = @{(id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)};
        _readerVideoTrackOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:[[asset tracksWithMediaType:AVMediaTypeVideo]firstObject] outputSettings:settings];
        _readerVideoTrackOutput.alwaysCopiesSampleData = NO;
        [_assetReader addOutput:_readerVideoTrackOutput];
        if([_assetReader startReading] == NO){
            NSLog(@"Error reading from file at URL:%@",asset);
        }
    }
}

- (CMSampleBufferRef)readBuffer
{
    @synchronized (self) {
        CMSampleBufferRef sampleBufferRef = nil;
        if(_readerVideoTrackOutput){
            sampleBufferRef = [_readerVideoTrackOutput copyNextSampleBuffer];
        }
        if(_assetReader && _assetReader.status ==  AVAssetReaderStatusCompleted){
            NSLog(@"customInit");
            _readerVideoTrackOutput = nil;
            _assetReader = nil;
            [self loadAsset];
        }
        return sampleBufferRef;
    }
}

@end
