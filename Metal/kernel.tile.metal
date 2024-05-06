// pipe.tile.metal

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

kernel void tile
(
 texture2d<half>                inTex  [[ texture(0) ]],
 texture2d<half, access::write> outTex [[ texture(1) ]],
 constant float2&               repeat [[ buffer(0)  ]],
 constant float2&               mirror [[ buffer(1)  ]],
 uint2 gid [[thread_position_in_grid]])
{
    constexpr sampler samplr(coord::normalized,
                             filter::nearest,
                             address::repeat);

    const float xs = outTex.get_width();   // width
    const float ys = outTex.get_height();  // height// height

    float2 gidf = float2(gid.x/xs,gid.y/ys);
    float2 mod;
    float2 rep = max(0.005, 1. - repeat);

    if (mirror.x < -0.5) {
        mod.x = fmod(gidf.x, rep.x);
    } else {
        // mirror rep x
        mod.x = fmod(gidf.x, rep.x * (1 + mirror.x));
        if (mod.x > rep.x) {
            mod.x = ((rep.x * (1 + mirror.x) - mod.x)
                     / fmax(0.0001, mirror.x));
        }
    }
    if (mirror.y < -0.5) {
        mod.y = fmod(gidf.y, rep.y);
    } else {
        mod.y = fmod(gidf.y, rep.y * (1 + mirror.y));
        if (mod.y > rep.y) {
            mod.y = ((rep.y * (1 + mirror.y) - mod.y)
                      / fmax(0.0001, mirror.y));
        }
    }

    float2 modNorm = mod / rep;
    half4 item = inTex.sample(samplr, modNorm);
    outTex.write(item, gid);

}

