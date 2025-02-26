#include <metal_stdlib>
#include <simd/simd.h>
using namespace metal;

kernel void cameraKernel
(
 texture2d<float>                inTex     [[ texture(0) ]],
 texture2d<float, access::write> outTex    [[ texture(1) ]],
 uint2 gid [[ thread_position_in_grid ]])
{
    // Normalize gid to [0, 1] space
    float2 norm = float2(gid) / float2(outTex.get_width(),
                                       outTex.get_height());

    constexpr sampler samplr(filter::linear);
    float4 inPix = inTex.sample(samplr, norm.xy);
    outTex.write(inPix, gid);
}
