//
//  SampleMetal.metal
//  AppleMetalUseDemos
//
//  Created by 泽泽 on 2020/8/31.
//  Copyright © 2020 zezefamily. All rights reserved.
//

#include <metal_stdlib>
#import "SampleMetalTypes.h"
using namespace metal;


typedef struct {
    float4 clipSpacePosition [[position]];
    float2 textureCoordinate;
}SampleRasterizerData;

//参数:
//0.内建参数-顶点标识符vertexID(vertex_id)
//1.顶点数据vertexArray(SampleVertexInputIndexVertices)
vertex SampleRasterizerData sampleVertexShader (uint vertexID [[vertex_id]],constant SampleVertex *vertexArray [[buffer(SampleVertexInputIndexVertices)]])
{
    SampleRasterizerData output;
    //顶点坐标
    output.clipSpacePosition = vertexArray[vertexID].position;
    //纹理坐标
    output.textureCoordinate = vertexArray[vertexID].textureCoordinate;
    return output;
}

//参数：
//0.顶点函数传入的顶点数据input(stage_in)
//1.Y纹理数据textureY(SampleFragmentTextureIndexTextureY)
//2.UV纹理数据textureUV(SampleFragmentTextureIndexTextureUV)
//3.转换矩阵convertMatrix(SampleFragmentBufferIndexMatrix)
fragment float4 sampleFragmentShader (SampleRasterizerData input [[stage_in]],
                                      texture2d<float>textureY [[texture(SampleFragmentTextureIndexTextureY)]],
                                      texture2d<float>textureUV [[texture(SampleFragmentTextureIndexTextureUV)]],
                                      constant SampleConvertMatrix *convertMatrix [[buffer(SampleFragmentBufferIndexMatrix)]])
{
    //获取采样器
    constexpr sampler textureSampler (mag_filter::linear,min_filter::linear);
    //读取YUV颜色值
    float3 yuv = float3(textureY.sample(textureSampler, input.textureCoordinate).r,textureUV.sample(textureSampler, input.textureCoordinate).rg);
    //YUV -> RGBA
    float3 rgb = convertMatrix->matrix * (yuv + convertMatrix->offset);
    //
    return float4(rgb,1.0);
}
