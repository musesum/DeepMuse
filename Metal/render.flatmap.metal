// Flatmap

#include <metal_stdlib>
#include "SpatialTypes.h"

using namespace metal;

struct VertexFlat {
    float4 position [[ position ]];
    float2 texCoord;
};

struct FlatmapVertex {
    float2 position;
    float2 texCoord; // 2D texture coordinate
};

// MARK: - vertex
vertex VertexFlat vertexFlatmap
(
 constant FlatmapVertex*     vertIn    [[ buffer(0) ]],
 constant float2&       viewSize  [[ buffer(1) ]],
 constant float4&       clipFrame [[ buffer(2) ]],
 constant UniformEyes&  eyes      [[ buffer(3) ]],
 //ushort                 ampId     [[ amplification_id]],
 uint                   vertId    [[ vertex_id ]])
{
    VertexFlat vertOut;

    float2 pos = vertIn[vertId].position.xy; // distance from origin
    float2 tex = vertIn[vertId].texCoord.xy;

    vertOut.position.xy = pos / (viewSize / 2.0); //(-1, -1) to (1, 1)
    vertOut.position.z = 0.0;
    vertOut.position.w = 1.0;
    vertOut.texCoord = (tex + clipFrame.xy) * clipFrame.zw;
    return vertOut;
}

// MARK: - fragment
fragment half4 fragmentFlatmap
(
 VertexFlat       vertOut [[ stage_in   ]],
 texture2d<half>  tex     [[ texture(0) ]],
 constant float2& repeat  [[ buffer(1)  ]],
 constant float2& mirror  [[ buffer(2)  ]])
{
    float2 texCoord = vertOut.texCoord;
    float2 mod;
    float2 reps = max(0.005, 1. - repeat);

    if (mirror.x < -0.5) {
        mod.x = fmod(texCoord.x, reps.x);
    } else {
        // mirror repeati x
        mod.x = fmod(texCoord.x, reps.x * (1 + mirror.x));
        if (mod.x > reps.x) {
            mod.x = ((reps.x * (1+mirror.x) - mod.x)
                     / fmax(0.0001, mirror.x));
        }
    }
    if (mirror.y < -0.5) {
        mod.y = fmod(texCoord.y, reps.y);
    } else {
        mod.y = fmod(texCoord.y, reps.y * (1 + mirror.y));
        if (mod.y > reps.y) {
            mod.y = ((reps.y * (1+mirror.y) - mod.y)
                     / fmax(0.0001, mirror.y));
        }
    }
    constexpr sampler samplr(filter::linear,
                             address::repeat);

    float2 modCoord = mod / reps;
    return tex.sample(samplr, modCoord);
}

