#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

kernel void camixKernel
(
 texture2d<float, access::read>   inTex  [[ texture(0) ]],
 texture2d<float, access::write>  outTex [[ texture(1) ]],
 texture2d<float>                 camTex [[ texture(3) ]],
 constant float&                  mix    [[ buffer(0)  ]],
 uint2 gid [[ thread_position_in_grid ]])
{
    float2 norm = float2(gid) / float2(outTex.get_width(),
                                       outTex.get_height());
    float2 camPos = float2(norm.x, norm.y);

    constexpr sampler samplr(filter::linear);
    float4 camPix = camTex.sample(samplr, camPos);
    float4 inPix = inTex.read(gid);
    float4 mixPix = camPix * mix + inPix * (1 - mix);
    outTex.write(mixPix, gid);
}
