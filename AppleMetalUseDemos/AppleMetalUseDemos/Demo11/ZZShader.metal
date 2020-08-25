//
//  ZZShader.metal
//  AppleMetalUseDemos
//
//  Created by wenmei on 2020/8/20.
//  Copyright © 2020 zezefamily. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;
#import "../ZZShaderTypes.h"

// 顶点着色器输出和片段着色器输入
//结构体
typedef struct
{
    //处理空间的顶点信息
    float4 clipSpacePosition [[position]];
    //颜色
    float4 color;

} RasterizerData;

vertex RasterizerData vertexShader(uint vertexID [[vertex_id]],
constant ZZVertex *vertices [[buffer(ZZVertexInputIndexVertices)]],
constant vector_uint2 *viewportSizePointer [[buffer(ZZVertexInputIndexViewportSize)]])
{
    //定义out
    RasterizerData out;
    out.clipSpacePosition = vertices[vertexID].position;
    out.color = vertices[vertexID].color;
    return out;
}

//中间还经历了图元装配，光栅化...

fragment float4 fragmentShader(RasterizerData in [[stage_in]])
{
    //返回输入的片元颜色
    return in.color;
}

