#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

/// timeTunnel cellular automata rule
kernel void tunl(texture2d<half, access::read_write> inTex  [[texture(0)]],
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
    }/** get n s e w nw ne se sw C */
    const uint c  = uint(inTex.read(ci).b * 255);
    const uint n  = uint(inTex.read(ni).b * 255);
    const uint e  = uint(inTex.read(ei).b * 255);
    const uint s  = uint(inTex.read(si).b * 255);
    const uint w  = uint(inTex.read(wi).b * 255);
    const uint nw = uint(inTex.read(nwi).b * 255);
    const uint ne = uint(inTex.read(nei).b * 255);
    const uint se = uint(inTex.read(sei).b * 255);
    const uint sw = uint(inTex.read(swi).b * 255);

    const half4 inItem = inTex.read(gid);

    uint ua = uint(inItem.a*255);
    uint ur = uint(inItem.r*255);
    uint ug = uint(inItem.g*255);
    uint ub = uint(inItem.b*255);

    uint HiC = (ua << 8) + ur;
    uint LoC = (ug << 8) + ub;
    uint LoC2 = (LoC << 1); // center left 1;
    uint LoC1 = (LoC >> 1) & 1; //replace bit 0 with bit 1
    uint cc = (c&1);

    uint nsew0 = (n&1)  + (s&1)  + (e&1)  + (w&1);
    uint nsew1 = (nw&1) + (ne&1) + (se&1) + (sw&1);
    uint nsew2 = nsew0 + nsew1;
    uint nsewc0 = nsew0 + cc;
    uint nsewc1 = nsew1 + cc;
    uint nsewc2 = nsew2 + cc;

    /** calculate */
    
    uint parity;
    switch (uint(version)) {
        case 0: parity = ((nsew0  == 0) ? 0 : (nsew0  == 5) ? 0 : 1); break;
        case 1: parity = ((nsew1  == 0) ? 0 : (nsew1  == 5) ? 0 : 1); break;
        case 2: parity = ((nsew2  == 0) ? 0 : (nsew2  == 9) ? 0 : 1); break;
        case 3: parity = ((nsewc0 == 0) ? 0 : (nsewc0 == 5) ? 0 : 1); break;
        case 4: parity = ((nsewc1 == 0) ? 0 : (nsewc1 == 5) ? 0 : 1); break;
        case 5: parity = ((nsewc2 == 0) ? 0 : (nsewc2 == 9) ? 0 : 1); break;
    }
    uint r1 = (parity ^ LoC1) | LoC2;
    uint r2 = 256 - r1;
    uint r3 = HiC + (r1 & 3);

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

/// this is kinda interesting
kernel void tunlMistake(texture2d<half, access::read_write> inTex  [[texture(0)]],
                        texture2d<half, access::read_write> outTex [[texture(1)]],
                        constant float &version [[buffer(0)]],
                        uint2 gid [[thread_position_in_grid]]) {

    uint xs = outTex.get_width();   // width
    uint ys = outTex.get_height();  // height// height
    if (gid.x >= xs || gid.y >= ys) { return; } // discard out of bounds

    const uint2 ni(gid.x, gid.y - 1);
    const uint2 si(gid.x, gid.y + 1);
    const uint2 wi(gid.x - 1, gid.y);
    const uint2 ei(gid.x + 1, gid.y);
    const uint2 ci(gid.x,     gid.y);

    const int N = int(inTex.read(ni).g * 255);
    const int S = int(inTex.read(si).g * 255);
    const int W = int(inTex.read(wi).g * 255);
    const int E = int(inTex.read(ei).g * 255);
    const int C = int(inTex.read(ci).g * 255);

    half4 inItem = inTex.read(gid);

    int ua = int(inItem.a*255);
    int ur = int(inItem.r*255);
    int ug = int(inItem.g*255);
    int ub = int(inItem.b*255);

    int HiC = (ua << 8) + ur;
    int LoC = (ug << 8) + ub;
    int LoC2 = (LoC << 1); // center left 1;
    int LoC1 = (LoC >> 1) & 1; //replace bit 0 with bit 1

        // next two lines replaces buf.map0[N&1+S&1+E&1+W&1+C&1] for int32_t map0[6]  = { 0, 1, 1, 1, 1, 0 };
    int mapsum = N&1 + S&1 + E&1 + W&1 + C&1;
    int parity = mapsum == 0 ? 0 : mapsum == 5 ? 0 : 1;

    int r1 = (parity ^ LoC1) | LoC2;
    int r2 = 256-r1;
    int r3 = HiC + (r1 & 0x80);

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

