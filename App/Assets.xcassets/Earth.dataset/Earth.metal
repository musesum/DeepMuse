
#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float3 position  [[attribute(0)]];
    float3 normal    [[attribute(1)]];
    float2 texCoords [[attribute(2)]];
};

struct VertexOut {
    float4 position [[position]];
    float3 viewNormal;
    float2 texCoords;
};

struct PoseConstants {
    float4x4 projectionMatrix;
    float4x4 viewMatrix;
};

struct EarthConstants {
    float4x4 modelMatrix;
};

[[vertex]]
VertexOut vertex_earth(VertexIn in [[stage_in]],
                       constant PoseConstants &pose [[buffer(1)]],
                       constant EarthConstants &earth [[buffer(2)]])
{
    VertexOut out;
    out.position = pose.projectionMatrix * pose.viewMatrix * earth.modelMatrix * float4(in.position, 1.0f);
    out.viewNormal = (pose.viewMatrix * earth.modelMatrix * float4(in.normal, 0.0f)).xyz;
    out.texCoords = in.texCoords;
    out.texCoords.x = 1.0f - out.texCoords.x; // Flip uvs horizontally to match Model I/O
    return out;
}

[[fragment]]
float4 fragment_earth(VertexOut in [[stage_in]],
                      texture2d<float> texture [[texture(0)]])
{
    constexpr sampler earthSampler(coord::normalized,
                                   filter::linear,
                                   mip_filter::none,
                                   address::repeat);
    
    //float3 N = normalize(in.viewNormal);
    float4 color = texture.sample(earthSampler, in.texCoords);
    return color;
}
