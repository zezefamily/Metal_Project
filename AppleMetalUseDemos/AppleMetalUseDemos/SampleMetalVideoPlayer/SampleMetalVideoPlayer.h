//
//  SampleMetalVideoPlayer.h
//  AppleMetalUseDemos
//
//  Created by 泽泽 on 2020/8/27.
//  Copyright © 2020 zezefamily. All rights reserved.
//

#import <UIKit/UIKit.h>
@import AVFoundation;
@import MetalKit;

NS_ASSUME_NONNULL_BEGIN

@interface SampleMetalVideoPlayer : UIView
- (void)openSourceWithURL:(NSURL *)URL;
@end

NS_ASSUME_NONNULL_END
