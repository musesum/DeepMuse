#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

kernel void camix(texture2d<float, access::read>   inTex  [[ texture(0) ]],
                  texture2d<float, access::write>  outTex [[ texture(1) ]],
                  texture2d<float>                 camTex [[ texture(2) ]],

                  constant uint   &face  [[ buffer(0)]], // front or back
                  constant float  &mix   [[ buffer(1)]], // mix real/fake
                  constant float4 &frame [[ buffer(2)]], // 1080p ?

                  uint2 gid [[ thread_position_in_grid ]],
                  sampler samplr [[sampler(0)]]) {

    float x(frame[0]);   // x offset 0...n
    float y(frame[1]);   // y offset 0...n

    float w(frame[2]);   // in total width 0...n
    float ww = w - 2*x;  // in fill width 0...n
    float wf = ww/w;     // in fill fraction of total 0...1
    float xx = x/ww;     // in offset 0...1

    float h(frame[3]);   // in height 0...n
    float hh = h - 2*y;  // in height 0...n - 2y
    float hf = hh/h;     // in height factor < 0...1
    float yy = y/hh;     // in y offset 0...1

    float outx = gid.x / float(outTex.get_width()); // output x 0...1
    float outy = gid.y / float(outTex.get_height()); // output y 0...1
    float clipx = x>y ? (outx * wf + xx) : (outx * hf + yy); // x position inside input
    float clipy = x>y ? (outy * hf + yy) : (outy * wf + xx); // y position inside input

    float2 camOut;
    typedef enum  { frontPhone=0, frontPad, backPhone, backPad } CameraType;
    
    switch (face) {
        case frontPhone:
        case frontPad:   camOut.x = 1- clipx; camOut.y = clipy; break; // front facing mirror
        case backPhone:
        case backPad:    camOut.x =    clipx; camOut.y = clipy; break; // back facing
    }

    float4 camItem = camTex.sample(samplr, camOut);
    float4 inItem = inTex.read(gid);
    float4 mixItem = float4(camItem.r * mix + inItem.r * (1. - mix),
                            camItem.g * mix + inItem.g * (1. - mix),
                            camItem.b * mix + inItem.b * (1. - mix),
                            camItem.a * mix + inItem.a * (1. - mix));
    
    outTex.write(mixItem, gid);
}
