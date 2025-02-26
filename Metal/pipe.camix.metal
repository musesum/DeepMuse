#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

kernel void camixKernel
(
 texture2d<float, access::read>   inTex  [[ texture(0) ]],
 texture2d<float, access::write>  outTex [[ texture(1) ]],
 texture2d<float>                 camTex [[ texture(3) ]],
 constant float&                  mix    [[ buffer(0)  ]],
 constant float4&                 frame  [[ buffer(1)  ]],
 uint2 gid [[ thread_position_in_grid ]])
{
    float x = frame.x; // x offset 0...n
    float y = frame.y; // y offset 0...n
    float w = frame.z; // width 0...n
    float h = frame.w; // height 0...n

    float ww = w - 2*x; // in fill width 0...n
    float wf = ww / w;  // in fill fraction of total 0...1
    float xn = x / ww;  // normalize x offset

    float hh = h - 2*y; // in height 0...n - 2y
    float hf = hh / h;  // in height factor < 0...1
    float yn = y / hh;  // normalized y offset

    float2 norm = float2(gid) / float2(outTex.get_width(),
                                       outTex.get_height());
    float2 camPos = (x > y
                     ? float2(norm.x * wf + xn, norm.y * hf + yn)
                     : float2(norm.x * hf + yn, norm.y * wf + xn));

    constexpr sampler samplr(filter::linear);
    float4 camPix = camTex.sample(samplr, camPos);
    float4 inPix = inTex.read(gid);
    float4 mixPix = camPix * mix + inPix * (1 - mix);
    outTex.write(mixPix, gid);
}
