#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

// for an cubemap that indexes a 2D texture, find the texture coordinate from a
kernel void drawCube
(
 constant float3 &direction [[ buffer(0) ]], // Direction vector from camera to fingertip
 texturecube<half> cubeTex [[ texture(0) ]], // Cubemap texture
 device half4 *texIndex [[ buffer(1) ]], // Output color buffer
 uint id [[ thread_position_in_grid ]]) // Thread ID
{
    if (id == 0) { // Assuming single-threaded execution for simplicity
                   // Sample the cubemap with the direction vector
        half4 sampledColor = cubeTex.sample(sampler(mip_filter::linear,
                                                    mag_filter::linear,
                                                    min_filter::linear),
                                            direction);

        // Write the sampled color to the output buffer
        texIndex[0] = sampledColor;
    }
}

//kernel void draw_
//(
// texture2d<half, access::read>  inTex   [[ texture(0) ]],
// texture2d<half, access::write> outTex  [[ texture(1) ]],
// constant float2&               draw    [[ buffer(0) ]],
// uint2 gid [[thread_position_in_grid]])
//{
//    
//    int xs = outTex.get_width();   // width
//    int ys = outTex.get_height();  // height
//
//    int x = (gid.x + xs + int((draw.x-0.5) * 256.)) % xs;
//    int y = (gid.y + ys + int((0.5-draw.y) * 256.)) % ys;
//
//    half4 item = inTex.read(uint2(x, y));
//
//    outTex.write(item, gid);
//}
//
//fragment half4 fragmentCubeIndex_
//(
// VertexOut          vertOut [[ stage_in   ]],
// texturecube<half>  cubeTex [[ texture(0) ]],
// texture2d<half>    inTex   [[ texture(1) ]],
// constant float2&   repeat  [[ buffer(1)  ]],
// constant float2&   mirror  [[ buffer(2)  ]])
//{
//    float3 texCoord = float3(vertOut.texCoord.x,
//                             vertOut.texCoord.y,
//                             -vertOut.texCoord.z);
//
//    constexpr sampler samplr(filter::linear,
//                             address::repeat);
//
//    half4 index = cubeTex.sample(samplr,texCoord);
//    float2 inCoord = float2(index.xy);
//
//    float2 mod;
//    float2 reps = max(0.005, 1. - repeat);
//
//    if (mirror.x < -0.5) {
//        mod.x = fmod(inCoord.x, reps.x);
//    } else {
//        // mirror repeati x
//        mod.x = fmod(inCoord.x, reps.x * (1 + mirror.x));
//        if (mod.x > reps.x) {
//            mod.x = ((reps.x * (1 + mirror.x) - mod.x)
//                     / fmax(0.0001, mirror.x));
//        }
//    }
//    if (mirror.y < -0.5) {
//        mod.y = fmod(inCoord.y, reps.y);
//    } else {
//        mod.y = fmod(inCoord.y, reps.y * (1 + mirror.y));
//        if (mod.y > reps.y) {
//            mod.y = ((reps.y * (1 + mirror.y) - mod.y)
//                     / fmax(0.0001, mirror.y));
//        }
//    }
//    float2 modCoord = mod / reps;
//    return inTex.sample(samplr, modCoord);
//}
//
