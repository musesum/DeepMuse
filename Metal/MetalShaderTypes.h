
#ifndef MetalShaderTypes_h
#define MetalShaderTypes_h

#include <simd/simd.h>

typedef struct {
    vector_float2 position;
    vector_float2 texCoord; // 2D texture coordinate
} MetVertex;

#endif
