// Plato

#include <metal_stdlib>
#include "SpatialTypes.h"

using namespace metal;

struct Shading {
    float convex; //  depth multiplier of each subdivision
    float reflect;
    float alpha;
    float depth;
    float invert;
    float zoom;
};

// index ranged  0...1
struct FlatIn {
    float4 pos0  [[attribute(0)]]; // position at 0
    float4 pos1  [[attribute(1)]]; // position at 1
    float4 norm0 [[attribute(2)]]; // normal at 0
    float4 norm1 [[attribute(3)]]; // normal at 1
    float vertId;
    float faceId;   // shared by 3 vertices
    float harmonic; // depth of subdivision
    float phase;  // pad out 256 boundary
};

struct PlatoVertex {
    float4 position [[ position ]];
    float4 texCoord;
    float faceId;
    float harmonic;
};

// MARK: - vertex

vertex PlatoVertex platoVertex
(
 constant FlatIn* vertices [[ buffer(0) ]],
 constant float&  range01  [[ buffer(1) ]],
 constant Eyes&   eyes     [[ buffer(15) ]],
 ushort           ampId    [[ amplification_id]],
 uint32_t         vertexId [[ vertex_id ]]) {

    PlatoVertex platoVertex;
    UniformEye eye = eyes.eye[ampId];

    float3 pos0  = vertices[vertexId].pos0.xyz;
    float3 pos1  = vertices[vertexId].pos1.xyz;
    float3 norm0 = vertices[vertexId].norm0.xyz;
    float3 norm1 = vertices[vertexId].norm1.xyz;
    float4 pos   = float4((pos0  + (pos1 - pos0) * range01), 1);
    float4 norm  = float4((norm0 + (norm1-norm0) * range01), 0);

    float4 worldNorm = normalize(norm);
    float4 eyeDirection = normalize(pos);

    platoVertex.position = eye.projection * eye.viewModel * pos;
    platoVertex.texCoord = reflect(eyeDirection, worldNorm);
    platoVertex.faceId   = vertices[vertexId].faceId;
    platoVertex.harmonic = vertices[vertexId].harmonic;

    return platoVertex;
}

// MARK: - fragment

fragment half4 platoFragment
(
 PlatoVertex        platoVertex [[ stage_in   ]],
 constant Shading&  shading     [[ buffer(1)  ]],
 texturecube<half>  cubeTex     [[ texture(4) ]],
 texture2d  <half>  inTex       [[ texture(0) ]],
 texture2d  <half>  palTex      [[ texture(2) ]]) {{

    constexpr sampler samplr(filter::linear, address::repeat);

    float palMod = fmod(platoVertex.faceId, 256) / 256.0;
    float2 palPos = float2(palMod, 0.0);
    half4 palette = palTex.sample(samplr, palPos);

    float3 texCoord = float3(platoVertex.texCoord.x,
                             platoVertex.texCoord.y,
                             -platoVertex.texCoord.z);
    half4 cubeIndex = cubeTex.sample(samplr, texCoord);

    half4 sampled = inTex.sample(samplr, float2(cubeIndex.xy));
    float reflect = max(shading.reflect, 0.001);

    const half3 mix = half3((sampled * reflect) + palette * (1.0 - reflect));

    const float count = 6;
    float alpha    = shading.alpha; // x-axis
    float depth    = shading.depth;
    float harmonic = platoVertex.harmonic;
    float inverse  = (1-shading.invert) * count;
    float gradient = depth * abs(harmonic-inverse);
    half3 shaded   = mix * (1-gradient);
    return half4(shaded.xyz, 1 - alpha * gradient);
}}

/// texturecube has color information uploaded to it
/// vert.color is used for creating a shadow mixed with cube's color
fragment half4 platoCubeColorFragment
(
 PlatoVertex       platoVertex [[ stage_in   ]],
 texturecube<half> cubeTex     [[ texture(4) ]])
{
    float3 texCoord = float3(platoVertex.texCoord.x, 
                             platoVertex.texCoord.y,
                             -platoVertex.texCoord.z);

    constexpr sampler samplr(filter::linear, address::clamp_to_edge);
    half4 color = cubeTex.sample(samplr, texCoord);
    color.w = platoVertex.texCoord.w;
    return color;
}
