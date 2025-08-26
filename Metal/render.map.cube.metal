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

// MARK: - Vertex

vertex CubeVertex cubeVertex
(
 constant FlatIn* vertices [[ buffer(0) ]],
 constant Eyes&   eyes     [[ buffer(15) ]],
 ushort           ampId    [[ amplification_id]],
 uint32_t         vertexId [[ vertex_id ]])
{
    CubeVertex vertexOut;
    UniformEye eye = eyes.eye[ampId]; // works with eye[1], eye[0]

    float4 position = vertices[vertexId].position;
    
    vertexOut.position = (eye.projection *
                          eye.viewModel *
                          position);

    vertexOut.texCoord = position;

    return vertexOut;
}

// MARK: - Fragment via index texture `cudex`

fragment FragmentOut cubeIndexFragment_
(
 CubeVertex         cubeVertex [[ stage_in   ]],
 texture2d<half>    inTex      [[ texture(0) ]],
 texturecube<half>  cudex      [[ texture(1) ]],
 constant float2&   mixcube    [[ buffer(0)  ]],
 texture2d<half>    displace   [[ texture(3) ]],
 constant Eyes&     eyes       [[ buffer(15) ]],
 ushort             ampId      [[ amplification_id ]])
{
    constexpr sampler samplr(filter::linear, address::clamp_to_edge);

    float3 texCoord = float3(cubeVertex.texCoord.x,
                             cubeVertex.texCoord.y,
                             -cubeVertex.texCoord.z);
    
    // Sample index first to get inCoord
    half4 index = cudex.sample(samplr, texCoord);
    float2 inCoord = float2(index.xy);
    
    // Sample displacement value at inCoord
    float displacement = float(displace.sample(samplr, inCoord).r);

    // Now use displaced z value for cube lookup
    float3 displaceCoord = float3(cubeVertex.texCoord.x,
                                  cubeVertex.texCoord.y,
                                  -cubeVertex.texCoord.z - displacement);

    half4 newIndex = cudex.sample(samplr, displaceCoord);
    float2 displacedInCoord = float2(newIndex.xy);
    half4 sample = inTex.sample(samplr, displacedInCoord);

    FragmentOut out;
    out.color = half4(sample.xyz, mixcube.x);

    // --------------------------------------------
    UniformEye eye = eyes.eye[ampId];
    float4 displacedPosition = cubeVertex.texCoord;
    displacedPosition.z -= displacement;
    float4 projected = eye.projection * eye.viewModel * displacedPosition;
    out.depth = projected.z / projected.w; // Metal NDC depth;
    return out;
}
fragment half4 cubeIndexFragment
(
 CubeVertex         cubeVertex [[ stage_in   ]],
 texture2d<half>    inTex      [[ texture(0) ]],
 texturecube<half>  cudex      [[ texture(1) ]],
 constant float2&   mixcube    [[ buffer(0)  ]],
 texture2d<half>    displace   [[ texture(3) ]])
{
    constexpr sampler samplr(filter::linear, address::clamp_to_edge);

    float3 texCoord = float3(cubeVertex.texCoord.x,
                             cubeVertex.texCoord.y,
                             -cubeVertex.texCoord.z);

    // Sample index first to get inCoord
    half4 index = cudex.sample(samplr, texCoord);
    float2 inCoord = float2(index.xy);

    // Sample displacement value at inCoord
    float displacement = float(displace.sample(samplr, inCoord).r);

    // Now use displaced z value for cube lookup
    float3 displaceCoord = float3(cubeVertex.texCoord.x,
                                  cubeVertex.texCoord.y,
                                  -cubeVertex.texCoord.z - displacement);

    half4 newIndex = cudex.sample(samplr, displaceCoord);
    float2 displacedInCoord = float2(newIndex.xy);
    half4 sample = inTex.sample(samplr, displacedInCoord);

    return half4(sample.xyz, mixcube.x);
}

// MARK: - fragment color

fragment half4 cubeColorFragment
(
 CubeVertex         cubeVertex  [[ stage_in   ]],
 texturecube<half>  colorTex    [[ texture(1) ]]) {

    constexpr sampler samplr(filter::linear,
                             address::repeat);

    float3 texCoord = float3(cubeVertex.texCoord.x,
                             cubeVertex.texCoord.y,
                             -cubeVertex.texCoord.z);

    return colorTex.sample(samplr, texCoord);
}

