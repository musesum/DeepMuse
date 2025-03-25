// Flatmap

#include <metal_stdlib>
#include "SpatialTypes.h"

using namespace metal;

struct FlatIn {
    float2 position;
    float2 texCoord; // 2D texture coordinate
};
struct FlatVertex {
    float4 position [[ position ]];
    float2 texCoord;
};
// MARK: - vertex
vertex FlatVertex flatVertex
(
 constant FlatIn* flatIn    [[ buffer(0) ]],
 constant float2& drawSize  [[ buffer(1) ]],
 constant float4& clipRect  [[ buffer(2) ]],
 uint vertexId [[ vertex_id ]]
 )
{
    FlatVertex flatOut;

    // Extract position and texture coordinates
    float2 pos = flatIn[vertexId].position.xy;
    float2 tex = flatIn[vertexId].texCoord.xy;

    // Normalize position: map from range (-drawSize.x/2, drawSize.x/2) to (-1, 1)
    flatOut.position.xy = pos / (drawSize / 2.0);
    flatOut.position.z = 0.0;
    flatOut.position.w = 1.0;

    // Scale texture coordinates using `clipRect.zw` (width and height)
    float2 scaledTex = tex * float2(clipRect.z, clipRect.w);

    // Apply translation using `clipRect.xy` (offsets)
    flatOut.texCoord = scaledTex + float2(clipRect.x, clipRect.y);

    return flatOut;
}

// MARK: - vertex
vertex FlatVertex flatVertex_
(
 constant FlatIn* flatIn      [[ buffer(0) ]],
 constant float2& drawSize    [[ buffer(1) ]],
 constant float4& clipRect    [[ buffer(2) ]],
 constant float& displaceFact [[ buffer(3) ]], // new uniform for strength
 texture2d<float> displaceTex [[ texture(1) ]], // new displacement texture
 uint vertexId                [[ vertex_id ]]
 )
{
    FlatVertex flatOut;

    // Extract position and texture coordinates
    float2 pos = flatIn[vertexId].position;
    float2 tex = flatIn[vertexId].texCoord;

    // Set up a sampler for the displacement texture
    constexpr sampler samplr(filter::linear, address::clamp_to_edge);

    // Sample the displacement map. Here, we use the red channel as the displacement value.
    float displacement = displaceTex.sample(samplr, tex).r;

    // Use the displacement value to adjust the vertex position along the z-axis
    float zOffset = displacement * displaceFact;

    // Normalize position: map from (-drawSize/2, drawSize/2) to (-1, 1)
    flatOut.position.xy = pos / (drawSize / 2.0);
    flatOut.position.z = zOffset; // displaced z position
    flatOut.position.w = 1.0;

    // Scale texture coordinates using clipRect.zw (width and height)
    float2 scaledTex = tex * float2(clipRect.z, clipRect.w);

    // Apply translation using clipRect.xy (offsets)
    flatOut.texCoord = scaledTex + float2(clipRect.x, clipRect.y);

    return flatOut;
}

// MARK: - fragment
fragment half4 flatFragment
(
 FlatVertex       flatOut [[ stage_in   ]],
 texture2d<half>  inTex   [[ texture(0) ]])
{
    float2 texCoord = flatOut.texCoord;

    constexpr sampler samplr(filter::linear, address::clamp_to_edge);
    return inTex.sample(samplr, texCoord);
}

