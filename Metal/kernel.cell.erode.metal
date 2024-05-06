#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

/// erode cellular automata rule
kernel void erode
(
 texture2d<half, access::read>  inTex   [[ texture(0) ]],
 texture2d<half, access::write> outTex  [[ texture(1) ]],
 constant float&                version [[ buffer(0) ]],
 uint2 gid [[thread_position_in_grid]])
{
    const uint2 ci(gid.x, gid.y);
    const half4 c = inTex.read(ci);
    const uint cf8  = uint(c.b * 255.) & 0xf8;
    
    int cand[8] = {0, 0, 0, 0, 0, 0, 0, 0};
    
    float interval = version*8 + 1.;
    float increment = interval / 2.;
    for (float i = -interval; i <= interval; i += increment) {
            //if (i == 0) { continue; }
        for (float j = -interval; j <= interval; j += increment) {
                //if (j==0) { continue; }
            uint2 texIndex(gid.x+i, gid.y+j);
            half4 item = inTex.read(texIndex);
            int candIndex = int(item.b*255.) & 0x7;
            cand[candIndex] += 1.;
        }
    }
    
    int j = 0;
    for (int k=0; k < 8; k++) {
        if (cand[j] < cand[k]) {
            j = k;
        }
    }
    
    half4 inItem = inTex.read(gid);
    
    uint ua = uint(inItem.a * 255.);
    uint ur = uint(inItem.r * 255.);
    uint ug = uint(inItem.g * 255.);
    uint ub = uint(inItem.b * 255.);
    uint HiC = (ua << 8) + ur;
    
        //float r1 = trunc(fb/8.)*8. + fmod(j, 8.); //r1 = (C & 0xf8) + (j & 7);
    uint r1 = cf8 + (j & 0x7);
    uint r2 = 256 - r1; 
    uint r3 = HiC + (r1 & 0x3); 
    
    ua = (r3 >> 8) & 0xFF;
    ur = r3 & 0xFF;
    ug = r2 & 0xFF;
    ub = r1 & 0xFF;
    
    float fa = float(ua)/255;
    float fr = float(ur)/255;
    float fg = float(ug)/255;
    float fb = float(ub)/255;
    
    half4 outItem = half4(fr, fg, fb, fa);
    
    outTex.write(outItem, gid);
}
