// Cubemap

#include <metal_stdlib>
#include "SpatialTypes.h"

using namespace metal;

struct CubemapVertexOut {
    float4 position [[ position ]];
    float4 texCoord;
};

struct VertexIn {
    float4 position [[ attribute(0) ]];
};


// MARK: - Vertex

vertex CubemapVertexOut vertexCubemap
(
 constant VertexIn*        in       [[ buffer(0) ]],
 constant UniformEyes&     eyes     [[ buffer(3) ]],
 ushort                    ampId    [[ amplification_id]],
 uint32_t                  vertId   [[ vertex_id ]])
{
    CubemapVertexOut out;
    UniformEye eye = eyes.eye[ampId]; // works with eye[1], eye[0]

    float4 position = in[vertId].position;

    out.position = (eye.projection *
                    eye.viewModel *
                    position);

    out.texCoord = position;

    return out;
}

// MARK: - Fragment via index texture

fragment half4 fragmentCubeIndex
(
 CubemapVertexOut   vertOut [[ stage_in   ]],
 texturecube<half>  cubeTex [[ texture(0) ]],
 texture2d<half>    inTex   [[ texture(1) ]],
 constant float2&   repeat  [[ buffer(1)  ]],
 constant float2&   mirror  [[ buffer(2)  ]])
{
    float3 texCoord = float3(vertOut.texCoord.x,
                             vertOut.texCoord.y,
                             -vertOut.texCoord.z);

    constexpr sampler samplr(filter::linear,
                             address::repeat);

    half4 index = cubeTex.sample(samplr,texCoord);
    float2 inCoord = float2(index.xy);

    float2 mod;
    float2 reps = max(0.005, 1. - repeat);

    if (mirror.x < -0.5) {
        mod.x = fmod(inCoord.x, reps.x);
    } else {
        // mirror repeati x
        mod.x = fmod(inCoord.x, reps.x * (1 + mirror.x));
        if (mod.x > reps.x) {
            mod.x = ((reps.x * (1 + mirror.x) - mod.x)
                     / fmax(0.0001, mirror.x));
        }
    }
    if (mirror.y < -0.5) {
        mod.y = fmod(inCoord.y, reps.y);
    } else {
        mod.y = fmod(inCoord.y, reps.y * (1 + mirror.y));
        if (mod.y > reps.y) {
            mod.y = ((reps.y * (1 + mirror.y) - mod.y)
                     / fmax(0.0001, mirror.y));
        }
    }
    return inTex.sample(samplr, mod / reps);
}

// MARK: - fragment color

fragment half4 fragmentCubeColor
(
 CubemapVertexOut   out [[ stage_in   ]],
 texturecube<half>  tex [[ texture(0) ]])
{
    constexpr sampler samplr(filter::linear,
                             address::repeat);

    float3 texCoord = float3(out.texCoord.x, out.texCoord.y, -out.texCoord.z);

    return tex.sample(samplr, texCoord);
}
