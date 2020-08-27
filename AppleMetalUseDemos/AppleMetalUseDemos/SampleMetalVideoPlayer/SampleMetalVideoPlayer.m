//
//  SampleMetalVideoPlayer.m
//  AppleMetalUseDemos
//
//  Created by 泽泽 on 2020/8/27.
//  Copyright © 2020 zezefamily. All rights reserved.
//

#import "SampleMetalVideoPlayer.h"

@implementation SampleMetalVideoPlayer

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/


- (void)openSourceWithURL:(NSURL *)URL
{
    AVAsset *asset = [AVAsset assetWithURL:URL];
    NSError *error = nil;
    AVAssetReader *reader = [[AVAssetReader alloc]initWithAsset:asset error:&error];
    if(error){
        NSLog(@"AVAssetReader 初始化失败. error:%@",error);
        return;
    }
//    AVAssetReaderOutput *readOutput = [AVAssetReaderOutput ]
}
@end

