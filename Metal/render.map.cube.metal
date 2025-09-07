// Cubemap

#include <metal_stdlib>
#include "SpatialTypes.h"

using namespace metal;

struct FlatIn {
    float4 position [[ attribute(0) ]];
};

struct CubeVertex {
    float4 position [[ position ]];
    float4 texCoord;
};

struct FragmentOut {
    half4 color [[color(0)]];
    float depth [[depth(any)]];
};

inline float3 facing(uint face, uint vid) {

    const float2 tex[6] = { { -1, -1},{ 1, -1},{ -1, 1}, { -1, 1},{ 1, -1},{ 1, 1} };
    float2 a = tex[vid];
    switch (face) { // 0:left,1:right,2:top,3:bot,4:front,5:back
    case 0: return float3(-1,  a.y,  a.x); // -X yo
    case 2: return float3( 1,  a.y, -a.x); // +X yo
    case 1: return float3( a.x,  1, -a.y); // +Y top
    case 3: return float3( a.x, -1,  a.y); // -Y bot
    case 4: return float3( a.x,  a.y,  1); // +Z oy
    default:return float3(-a.x,  a.y, -1); // -Z oy
    }
}

// bake: full‑screen quad → cube direction for a given face
vertex CubeVertex cubeBoxVertex
(
 uint            vid  [[ vertex_id  ]],
 constant uint&  face [[ buffer(10) ]]) {

    const float2 pos[6] = { {-1,-1},{+1,-1},{-1,+1}, {-1,+1},{+1,-1},{+1,+1} };

    CubeVertex out;
    out.position = float4(pos[vid], 0, 1);
    out.texCoord = float4(facing(face, vid), 0);
    return out;
}

// MARK: - Vertex

vertex CubeVertex cubeVertex
(
 constant FlatIn* vertices [[ buffer(0) ]],
 constant Eyes&   eyes     [[ buffer(15) ]],
 ushort           ampId    [[ amplification_id]],
 uint32_t         vertexId [[ vertex_id ]])
{
    CubeVertex out;
    UniformEye eye = eyes.eye[ampId]; // works with eye[1], eye[0]

    float4 position = vertices[vertexId].position;

    out.position = (eye.projection *
                    eye.viewModel *
                    position);

    out.texCoord = position;

    return out;
}

// MARK: - Fragment via index texture `cudex`
fragment half4 cubeIndexFragment
(
 CubeVertex         in      [[ stage_in   ]],
 texture2d<half>    inTex   [[ texture(0) ]],
 texturecube<half>  cudex   [[ texture(1) ]],
 constant float2&   mixcube [[ buffer(0)  ]])
{
    float3 texCoord = float3(in.texCoord.x,
                             in.texCoord.y,
                             -in.texCoord.z);

    constexpr sampler s(filter::linear, address::clamp_to_edge);
    half4 index = cudex.sample(s,texCoord);
    float2 inCoord = float2(index.xy);
    half4 sampled = inTex.sample(s, inCoord);
    float mix = mixcube.x;
    float alpha = mixcube.y;
    return half4(sampled.xyz, mix * alpha);
}
