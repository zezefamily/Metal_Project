//
//  ZZShaderTypes.h
//  AppleMetalUseDemos
//
//  Created by wenmei on 2020/8/20.
//  Copyright © 2020 zezefamily. All rights reserved.
//

#ifndef ZZShaderTypes_h
#define ZZShaderTypes_h

// 缓存区索引值 共享与 shader 和 C 代码 为了确保Metal Shader缓存区索引能够匹配 Metal API Buffer 设置的集合调用
typedef enum ZZVertexInputIndex
{
    //顶点
    ZZVertexInputIndexVertices     = 0,
    //视图大小
    ZZVertexInputIndexViewportSize = 1,
} ZZVertexInputIndex;


//结构体: 顶点/颜色值
typedef struct
{
    // 像素空间的位置
    // 像素中心点(100,100)
    vector_float4 position;

    // RGBA颜色
    vector_float4 color;
} ZZVertex;


//颜色结构体
typedef struct {
    float red, green, blue, alpha;
} Color;

#endif /* ZZShaderTypes_h */
