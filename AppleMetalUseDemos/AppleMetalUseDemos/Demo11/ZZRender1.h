//
//  ZZRender1.h
//  AppleMetalUseDemos
//
//  Created by wenmei on 2020/8/20.
//  Copyright © 2020 zezefamily. All rights reserved.
//

#import <Foundation/Foundation.h>
@import MetalKit;
NS_ASSUME_NONNULL_BEGIN

@interface ZZRender1 : NSObject <MTKViewDelegate>

- (instancetype)initWithMKView:(MTKView *)view;

@end

NS_ASSUME_NONNULL_END
