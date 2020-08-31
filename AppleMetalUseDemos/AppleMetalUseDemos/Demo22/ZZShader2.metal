//
//  ZZShader2.metal
//  AppleMetalUseDemos
//
//  Created by wenmei on 2020/8/25.
//  Copyright © 2020 zezefamily. All rights reserved.
//

#include <metal_stdlib>
#import "../ZZShaderTypes.h"
using namespace metal;

typedef struct {
    //空间顶点信息
    float4 clipSpacePosition [[position]];
    //颜色
    float4 color;
}RasterizerData;
typedef struct {
    //空间顶点信息
    float4 clipSpacePosition [[position]];
    //纹理坐标
    float2 textureCoordinate;
}RasterizerData1;


//vertex RasterizerData vertexFunc22 (uint vertexID [[vertex_id]],constant ZZVertex2 *vertices [[buffer(ZZVertexInputIndexVertices22)]],constant vector_uint2 *viewportSizePointer [[buffer(ZZVertexInputIndexViewportSize22)]])
//{
//    RasterizerData output;
//    //颜色值原样输出
//    output.color = vertices[vertexID].color;
//    //顶点标准化转换
//    float2 pixelSpacePosition = vertices[vertexID].position.xy;
//    vector_float2 viewPortSize = vector_float2(*viewportSizePointer);
//    output.clipSpacePosition.xy = pixelSpacePosition/(viewPortSize/2.0);
//    return output;
//}

vertex RasterizerData1 vertexFunc22 (uint vertexID [[vertex_id]],constant ZZVertex3 *vertices [[buffer(ZZVertexInputIndexVertices22)]],constant vector_uint2 *viewportSizePointer [[buffer(ZZVertexInputIndexViewportSize22)]])
{
    RasterizerData1 output;
    //颜色值原样输出
    output.textureCoordinate = vertices[vertexID].textureCoordinate;
    output.clipSpacePosition = float4(vertices[vertexID].position.xy,0,1);
    //顶点标准化转换
//    float2 pixelSpacePosition = vertices[vertexID].position.xy;
//    vector_float2 viewPortSize = vector_float2(*viewportSizePointer);
//    output.clipSpacePosition.xy = pixelSpacePosition/(viewPortSize/2.0);
    return output;
}

fragment float4 fragmentFunc22(RasterizerData1 data [[stage_in]],texture2d<half> colorTexture [[texture(ZZTextureIndexBaseColor)]])
{
    constexpr sampler textureSampler(mag_filter::linear,min_filter::linear);
    const half4 colorSampler = colorTexture.sample(textureSampler, data.textureCoordinate);
    return float4(colorSampler);
}

//fragment float4 fragmentFunc22(RasterizerData data [[stage_in]])
//{
//    return data.color;
//}
