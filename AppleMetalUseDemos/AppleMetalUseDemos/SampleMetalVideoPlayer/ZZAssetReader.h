//
//  ZZAssetReader.h
//  AppleMetalUseDemos
//
//  Created by 泽泽 on 2020/8/31.
//  Copyright © 2020 zezefamily. All rights reserved.
//

#import <Foundation/Foundation.h>
@import AVFoundation;
NS_ASSUME_NONNULL_BEGIN

@interface ZZAssetReader : NSObject

- (instancetype)initWithURL:(NSURL *)URL;

- (CMSampleBufferRef)readBuffer;

@end

NS_ASSUME_NONNULL_END
