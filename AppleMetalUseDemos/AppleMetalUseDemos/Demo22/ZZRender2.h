//
//  ZZRender2.h
//  AppleMetalUseDemos
//
//  Created by wenmei on 2020/8/25.
//  Copyright © 2020 zezefamily. All rights reserved.
//

#import <Foundation/Foundation.h>
@import MetalKit;
NS_ASSUME_NONNULL_BEGIN

@interface ZZRender2 : NSObject<MTKViewDelegate>

- (instancetype)zzRender2_initWithMTKView:(MTKView *)mtkView;

@end

NS_ASSUME_NONNULL_END
