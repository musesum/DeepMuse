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

// --- add under your structs ---

struct FragmentOut2 {
    half4 color0 [[color(0)]];
    half4 color1 [[color(1)]];
    float depth  [[depth(any)]];
};

inline float3 dirFromFaceUV(uint face, float2 uv01) {
    float2 a = fma(uv01, 2.0, -1.0); // [0,1] → [-1,1]
    switch (face) { // 0:left,1:right,2:top,3:bot,4:front,5:back
    case 0: return normalize(float3(-1,  a.y,  a.x));  // -X
    case 1: return normalize(float3( 1,  a.y, -a.x));  // +X
    case 2: return normalize(float3( a.x,  1, -a.y));  // +Y
    case 3: return normalize(float3( a.x, -1,  a.y));  // -Y
    case 4: return normalize(float3( a.x,  a.y,  1));  // +Z
    default:return normalize(float3(-a.x,  a.y, -1));  // -Z
    }
}

// bake: full‑screen quad → cube direction for a given face
vertex CubeVertex cubeBakeVertex(uint vid [[vertex_id]],
                                 constant uint& face [[buffer(10)]]) {
    const float2 pos[6] = { {-1,-1},{+1,-1},{-1,+1}, {-1,+1},{+1,-1},{+1,+1} };
    const float2 tex[6] = { { 0, 0},{ 1, 0},{ 0, 1}, { 0, 1},{ 1, 0},{ 1, 1} };

    CubeVertex out;
    out.position = float4(pos[vid], 0, 1);
    float3 dir = dirFromFaceUV(face, tex[vid]);
    out.texCoord = float4(dir, 1); // reuse existing path
    return out;
}

// --- new MRT variant (keep your original `cubeIndexFragment` as-is) ---
fragment FragmentOut2 cubeIndexFragment_mrt
(
 CubeVertex         in         [[ stage_in   ]],
 texture2d<half>    inTex      [[ texture(0) ]],
 texturecube<half>  cudex      [[ texture(1) ]],
 constant float2&   mixcube    [[ buffer(0)  ]])
{
    constexpr sampler samplr(filter::linear, address::clamp_to_edge);

    // same sampling as your single‑target path
    float3 texCoord = float3(in.texCoord.x, in.texCoord.y, -in.texCoord.z);
    half2 index  = cudex.sample(samplr, texCoord).xy;
    half4 col = inTex.sample(samplr, float2(index));

    FragmentOut2 out;
    out.color0 = half4(col.xyz, half(mixcube.x));     // normal output
    out.color1 = col;                                 // baked face (RGBA)
    out.depth  = 0.0;
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
 CubeVertex         cubeVertex [[ stage_in   ]],
 texture2d<half>    inTex      [[ texture(0) ]],
 texturecube<half>  cudex      [[ texture(1) ]],
 constant float2&   mixcube    [[ buffer(0)  ]])
{
    float3 texCoord = float3(cubeVertex.texCoord.x,
                             cubeVertex.texCoord.y,
                             -cubeVertex.texCoord.z);

    constexpr sampler samplr(filter::linear, address::clamp_to_edge);

    half4 index = cudex.sample(samplr,texCoord);
    float2 inCoord = float2(index.xy);
    half4 sampled = inTex.sample(samplr, inCoord);
    float mix = mixcube.x;
    //float alpha = mixcube.y;
    return half4(sampled.xyz, mix);
}

// MARK: - Compute bake from indirection map (cudex) to a single face
// Bind cudex as a 2D-array view of the cube (one slice per face).
// Dispatch per face with a 2D grid matching the output texture size.
kernel void bakeFaceFromIndex2DArray
(
 texture2d<half>                               inTex    [[ texture(0) ]],
 texture2d_array<half>                         cudexArr [[ texture(1) ]],
 texture2d<half, access::write>                outTex   [[ texture(2) ]],
 constant uint&                                 face    [[ buffer(0)  ]],
 uint2                                          gid     [[ thread_position_in_grid ]]
)
{
    if (gid.x >= outTex.get_width() || gid.y >= outTex.get_height()) return;
    if (gid.x >= cudexArr.get_width() || gid.y >= cudexArr.get_height()) return;

    // Read UV from indirection map for this pixel/face
    half4 idx = cudexArr.read(gid, face);
    float2 uv = float2(idx.xy);

    constexpr sampler s(filter::linear, address::clamp_to_edge);

    // Sample source and write out
    half4 col = inTex.sample(s, uv);
    outTex.write(col, gid);
}
