#include <metal_stdlib>
#include "ShaderTypes.h"

using namespace metal;

vertex VertexOut vertexEarth
(
 VertexCube           in       [[ stage_in ]],
 ushort               ampId    [[ amplification_id ]],
 constant UniformEyes &uniEyes [[ buffer(uniforms) ]])
{
    VertexOut out;

    UniformEye eye = uniEyes.eye[ampId];
    float4 position = float4(in.position, 1.0);

    out.position = (eye.projection *
                    eye.viewModel *
                    position);

    out.normal = (eye.viewModel *
                  float4(in.normal, 0.0f)).xyz;

    out.texCoord = in.texCoord;
    out.texCoord.x = 1.0f - out.texCoord.x; // Flip uvs horizontally to match Model I/O
    return out;
}

fragment float4 fragmentEarth
(
 VertexOut       out [[ stage_in ]],
 texture2d<half> tex [[ texture(colori) ]])
{
    constexpr sampler samplr(filter::linear,
                             address::repeat);

    half4 color = tex.sample(samplr, out.texCoord);
    return float4(color);
}
