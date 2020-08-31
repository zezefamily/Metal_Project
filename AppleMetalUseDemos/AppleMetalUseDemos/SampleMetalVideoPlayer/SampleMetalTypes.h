//
//  SampleMetalTypes.h
//  AppleMetalUseDemos
//
//  Created by 泽泽 on 2020/8/31.
//  Copyright © 2020 zezefamily. All rights reserved.
//

#ifndef SampleMetalTypes_h
#define SampleMetalTypes_h
#include <simd/simd.h>
typedef struct {
    //顶点坐标(x,y,z,w)
    vector_float4 position;
    //纹理坐标(x,y)
    vector_float2 textureCoordinate;
}SampleVertex;

//转化矩阵
typedef struct {
    //三维矩阵
    matrix_float3x3 matrix;
    //偏移
    vector_float3 offset;
}SampleConvertMatrix;

//顶点函数输入索引
typedef enum  SampleVertexInputIndex {
    SampleVertexInputIndexVertices = 0,
}SampleVertexInputIndex;

//片元函数缓冲区索引
typedef enum SampleFragmentBufferIndex {
    SampleFragmentBufferIndexMatrix = 0,
}SampleFragmentBufferIndex;

//片元函数纹理索引
typedef enum SampleFragmentTextureIndex {
    //Y纹理
    SampleFragmentTextureIndexTextureY = 0,
    //UV纹理
    SampleFragmentTextureIndexTextureUV = 1,
}SampleFragmentTextureIndex;


#endif /* SampleMetalTypes_h */
