//  ShaderTypes.h

#ifndef ShaderTypes_h
#define ShaderTypes_h

#ifdef __METAL_VERSION__
typedef metal::int32_t EnumBackingType;
#else
#import <Foundation/Foundation.h>
typedef NSInteger EnumBackingType;
#endif

#include <simd/simd.h>

enum VertexIndex {
    position = 0,
    texCoord = 1,
    normal   = 2,
    uniforms = 3
};

enum TextureIndex {
    colori = 0,
};

struct VertexMesh {
    float3 position [[ attribute(position) ]];
    float2 texCoord [[ attribute(texCoord) ]];
    float3 normal   [[ attribute(normal)   ]];
};

struct VertexOut {
    float4 position [[ position ]];
    float2 texCoord;
    float3 normal;
};

struct UniformEye {
    matrix_float4x4 projection;
    matrix_float4x4 viewModel;
};

struct UniformEyes {
    UniformEye eye[2];
};

#endif

