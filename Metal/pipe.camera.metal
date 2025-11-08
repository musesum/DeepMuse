#include <metal_stdlib>
#include <simd/simd.h>
using namespace metal;

kernel void cameraKernel_
(
 texture2d<float>                inTex  [[ texture(0) ]],
 texture2d<float, access::write> outTex [[ texture(1) ]],
 uint2 gid [[ thread_position_in_grid ]])
{
    // Normalize gid to [0, 1] space
    float2 norm = float2(gid) / float2(outTex.get_width(),
                                       outTex.get_height());

    constexpr sampler samplr(filter::linear);
    float4 inPix = inTex.sample(samplr, norm.xy);
    outTex.write(inPix, gid);
}


kernel void cameraKernel
(
 texture2d<float>                inTex  [[ texture(0) ]],
 texture2d<float, access::write> outTex [[ texture(1) ]],
 uint2 gid [[ thread_position_in_grid ]])
{
    // Compute normalized destination coordinates using pixel centers
    float2 outSize = float2(outTex.get_width(), outTex.get_height());
    float2 norm = (float2(gid) + 0.5) / outSize;

    // Input texture size and aspect ratios
    float2 inSize = float2(inTex.get_width(), inTex.get_height());
    float inAspect  = inSize.x / inSize.y;
    float outAspect = outSize.x / outSize.y;

    // Aspect-fill: scale by the larger factor so input covers output; center-crop
    float2 outPx = norm * outSize;

    float2 inPx;
    if (outAspect > inAspect) {
        // Output is wider -> scale by width, crop vertically
        float scale = outSize.x / inSize.x;
        float scaledH = inSize.y * scale;
        float cropY = (scaledH - outSize.y) * 0.5;
        inPx = float2(outPx.x, outPx.y + cropY) / scale;
    } else {
        // Output is taller or equal -> scale by height, crop horizontally
        float scale = outSize.y / inSize.y;
        float scaledW = inSize.x * scale;
        float cropX = (scaledW - outSize.x) * 0.5;
        inPx = float2(outPx.x + cropX, outPx.y) / scale;
    }

    float2 uv = inPx / inSize;

    constexpr sampler samplr(filter::linear, address::clamp_to_edge);
    float4 inPix = inTex.sample(samplr, uv);
    outTex.write(inPix, gid);
}
