#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

/// find position on cubemap that indexes a 2D texture
/// find the position of a brush and return the sampled color
///
///    direction : vector from camera to fingertip
///    cubeTex   : index cube
///    texIndex  : output color buffer
///    gid       : postion in thread
///
kernel void sampleCube
(
 constant float3&   direction   [[ buffer(0)  ]],
 device half4*      texIndex    [[ buffer(1)  ]],
 texturecube<half>  cubeTex     [[ texture(4) ]],
 uint gid [[ thread_position_in_grid ]]) {{
    if (gid == 0) { // Assuming single-threaded execution for simplicity

        constexpr sampler samplr(mip_filter::linear,
                                 mag_filter::linear,
                                 min_filter::linear);

        half4 sampledColor = cubeTex.sample(samplr, direction);
        texIndex[0] = sampledColor;
    }
}}
