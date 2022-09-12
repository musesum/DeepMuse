#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

/// fredkin cellular automata rule
kernel void fred(texture2d<half, access::read_write> inTex  [[texture(0)]],
                 texture2d<half, access::read_write> outTex [[texture(1)]],
                 constant float &version [[buffer(0)]],
                 uint2 gid [[thread_position_in_grid]]) {

    const uint xs = outTex.get_width();   // width
    const uint ys = outTex.get_height();  // height// height
    const uint2 ci(gid.x, gid.y);

    uint2 ni, si, ei, wi;       // n s e w indexs
    uint2 nwi, nei, sei, swi;   // nw ne se sw indexes

    /** setup indexes for n s e w nw ne se sw C */ {
        
        // x boundaries
        if (gid.x == 0) {
            ei = uint2(   1, gid.y);
            wi = uint2(xs-1, gid.y);
            // y boundaries
            if (gid.y == 0) {
                ni = uint2(    0, ys-1);
                si = uint2(    0,    1);
                nwi = uint2(xs-1, ys-1);
                swi = uint2(xs-1,    1);
                nei = uint2(   1, ys-1);
                sei = uint2(   1,    1);
            } else if (gid.y == ys-1) {
                ni = uint2(    0, ys-2);
                si = uint2(    0,    0);
                nwi = uint2(xs-1, ys-2);
                swi = uint2(xs-1,    0);
                nei = uint2(   1, ys-2);
                sei = uint2(   1,    0);
            } else {
                ni = uint2(    0, gid.y-1);
                si = uint2(    0, gid.y+1);
                nwi = uint2(xs-1, gid.y-1);
                swi = uint2(xs-1, gid.y+1);
                nei = uint2(   1, gid.y-1);
                sei = uint2(   1, gid.y+1);
            }
        } else if (gid.x == xs-1) {
            ei = uint2(   0, gid.y);
            wi = uint2(xs-2, gid.y);
            // y boundaries
            if (gid.y == 0) {
                ni  = uint2(xs-1, ys-1);
                si  = uint2(xs-1,    1);
                nwi = uint2(xs-2, ys-1);
                swi = uint2(xs-2,    1);
                nei = uint2(   0, ys-1);
                sei = uint2(   0,    1);
            } else if (gid.y == ys-1) {
                ni  = uint2(xs-1, ys-2);
                si  = uint2(xs-1,    0);
                nwi = uint2(xs-2, ys-2);
                swi = uint2(xs-2,    0);
                nei = uint2(   0, ys-2);
                sei = uint2(   0,    0);
            } else {
                ni  = uint2(xs-1, gid.y-1);
                si  = uint2(xs-1, gid.y+1);
                nwi = uint2(xs-2, gid.y-1);
                swi = uint2(xs-2, gid.y+1);
                nei = uint2(   0, gid.y-1);
                sei = uint2(   0, gid.y+1);
            }
        } else {
            ei = uint2(gid.x+1, gid.y);
            wi = uint2(gid.x-1, gid.y);
            // y boundaries
            if (gid.y == 0) {
                ni  = uint2(gid.x,   ys-1);
                si  = uint2(gid.x,      1);
                nwi = uint2(gid.x-1, ys-1);
                swi = uint2(gid.x-1,    1);
                nei = uint2(gid.x+1, ys-1);
                sei = uint2(gid.x+1,    1);
            } else if (gid.y == ys-1) {
                ni  = uint2(gid.x,   ys-2);
                si  = uint2(gid.x,      0);
                nwi = uint2(gid.x-1, ys-2);
                swi = uint2(gid.x-1,    0);
                nei = uint2(gid.x+1, ys-2);
                sei = uint2(gid.x+1,    0);
            } else {
                ni  = uint2(gid.x,   gid.y-1);
                si  = uint2(gid.x,   gid.y+1);
                nwi = uint2(gid.x-1, gid.y-1);
                swi = uint2(gid.x-1, gid.y+1);
                nei = uint2(gid.x+1, gid.y-1);
                sei = uint2(gid.x+1, gid.y+1);
            }
        }
    }

    /** get n s e w nw ne se sw C */ 
    const half4 C = inTex.read(ci);
    const uint c = uint(inTex.read(ci).b * 256.);
    const uint n = uint(inTex.read(ni).b * 256.);
    const uint s = uint(inTex.read(si).b * 256.);
    const uint e = uint(inTex.read(ei).b * 256.);
    const uint w = uint(inTex.read(wi).b * 256.);
    const uint nw = uint(inTex.read(nwi).b * 256.);
    const uint ne = uint(inTex.read(nei).b * 256.);
    const uint se = uint(inTex.read(sei).b * 256.);
    const uint sw = uint(inTex.read(swi).b * 256.);

    const uint HiC = (uint(C.a * 256.) << 8) + uint(C.r * 256.);

    int versioni = int(version); // * 4

    uint r1 = 0;
#define sum(n) ((c<<1) + ((c>>1) + n ) & 1) & 0xff;
    switch (versioni) {
        case 0: r1 = sum( n  + e  + s  + w); break;
        case 1: r1 = sum( nw + ne + se + sw); break;
        case 2: r1 = sum( n  + e  + s  + w + c); break;
        case 3: r1 = sum( nw + ne + se + sw + c); break;
        case 4: r1 = sum( n  + e  + s  + w + nw + ne + se + sw); break;
    }

    r1 = r1 + (r1<<6);
    uint r2 = 255 - r1;
    uint r3 = HiC + (r1 & 0x03);

    float fa = float(r3 >> 8) / 256.;
    float fr = float(r3 & 0xff) / 256.;
    float fg = float(r2) / 256.;
    float fb = float(r1) / 256.;
    half4 outItem = half4(fr, fg, fb, fa);
    outTex.write(outItem, gid);

}
