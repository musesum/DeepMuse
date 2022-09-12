#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

/// slide bitplanes cellular automata rule
kernel void slide(texture2d<float, access::read> inTex  [[texture(0)]],
                  texture2d<float, access::write> outTex [[texture(1)]],
                  constant float &version [[buffer(0)]],
                  uint2 gid [[thread_position_in_grid]]) {


    const uint xs = outTex.get_width();   // width
    const uint ys = outTex.get_height();  // height
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
    const float4 C = inTex.read(ci);
    //const uint cb = uint(C.b * 255.);
    //const uint cg = uint(C.g * 255.);
    const uint cr = uint(C.r * 255.);
    const uint ca = uint(C.a * 255.);
    //const float c = inTex.read(ci).b;
    const uint n = uint(inTex.read(ni).b * 255.);
    const uint s = uint(inTex.read(si).b * 255.);
    const uint e = uint(inTex.read(ei).b * 255.);
    const uint w = uint(inTex.read(wi).b * 255.);
    
    const uint nw = uint(inTex.read(nwi).b * 255.);
    const uint ne = uint(inTex.read(nei).b * 255.);
    const uint se = uint(inTex.read(sei).b * 255.);
    const uint sw = uint(inTex.read(swi).b * 255.);
    const uint HiC = (ca << 8) + cr;
    
    uint cells[8] = { n, s, e, w, nw, se, sw, ne };
    
    // each even/odd pair reverses order
    //   index binary          000 001 010  011  100  101  110 111
    //   cell position          n   s   e    w    nw   se   sw  ne
    //
    //  offset  = offset xor i = slide position
    //  0   000 = 000 001 010  011  100  101  110 111 =  n   s   e    w    nw   se   sw  ne
    //  1   001 = 001 000 011  010  101  100  111 110 =  s   n   w    e    se   nw   ne  sw
    //  2   010 = 010 011 000  001  110  111  100 101 =  e   w   n    s    sw   ne   nw  se
    //  3   011 = 011 010 001  000  111  110  101 100 =  w   e   s    n    ne   sw   se  nw
    //  4   100 = 100 101 110  111  000  001  010 011 =  nw  se  sw   ne   n    s    e   w
    //  5   101 = 101 100 111  110  001  000  011 010 =  se  nw  ne   sw   s    n    w   e
    //  6   110 = 110 111 100  101  010  011  000 001 =  sw  ne  nw   se   e    w    n   s
    //  7   111 = 111 110 101  100  011  010  001 000 =  ne  sw  se   nw   w    e    s   n
    
    
    uint r = 0;
    uint offset = uint(version); // * 7
    for (int i=0, j=1; i<8; i++, j <<= 1) {
        int k = (i^offset);
        r += cells[k] & j;
    }
    uint r1 = r;
    uint r2 = 256 - r1;
    uint r3 = HiC;// + fmod(r1, 7);
    
    float fa = float(r3 >> 8)   / 255.; // trunc(r3/255.) / 255.;
    float fr = float(r3 & 0xff) / 255.; //mod(r3, 255.) / 255.;
    float fg = float(r2) / 255.;
    float fb = float(r1) / 255.;
    
    float4 outItem = float4(fr, fg, fb, fa);
    
    outTex.write(outItem, gid);
}
