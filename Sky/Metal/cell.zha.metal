#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

/// zhabatinski cellular automata rule
kernel void zha(texture2d<half, access::read_write> inTex  [[texture(0)]],
                texture2d<half, access::read_write> outTex [[texture(1)]],
                constant float &version [[buffer(0)]],
                constant float &bits    [[buffer(1)]],
                uint2 gid [[thread_position_in_grid]]) {

    // 2:7 3:11 4:7 5:11?
    // const float version = 4.0/7.0;
    // int32_t threshold = version >> 1;                   // zmap threshold
    // int32_t annealing = ((version&1) << 1) + threshold;  // zmap annealing

    const int thresholds[7] = { 0b0000,  0b0001,  0b0001,  0b0010,  0b0101,  0b0110,  0b0111 };
    const int annealers[7]  = { 0b0010,  0b0001,  0b0011,  0b0010,  0b0111,  0b0110,  0b1001 };
    const int versioni = int(version*6);
    const int threshold = thresholds[versioni];
    const int annealing = annealers[versioni];

    const int bitsi = uint(bits);
    // bits/repeat 2:7 3:11 4:19
    //#define bits 1               // 0        1       2       3
    const int shift = bitsi+1;       // 1        2       3       4
    const int mask = (1 << bitsi)-1; // '0001   '0011    '0111   '1111

    const uint xs = outTex.get_width();   // width
    const uint ys = outTex.get_height();  // height// height

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
    }/** get N S E W NW NE SE SW  */
    const uint N  = uint(inTex.read(ni).b * 255);
    const uint E  = uint(inTex.read(ei).b * 255);
    const uint S  = uint(inTex.read(si).b * 255);
    const uint W  = uint(inTex.read(wi).b * 255);
    const uint NW = uint(inTex.read(nwi).b * 255);
    const uint NE = uint(inTex.read(nei).b * 255);
    const uint SE = uint(inTex.read(sei).b * 255);
    const uint SW = uint(inTex.read(swi).b * 255);

    const half4 inItem = inTex.read(gid);

    // convert 0...1 to 0..<256 index
    uint ua = uint(inItem.a*255);
    uint ur = uint(inItem.r*255);
    uint ug = uint(inItem.g*255);
    uint ub = uint(inItem.b*255);

    uint HiC = (ua << 8) + ur;
    uint LoC = (ug << 8) + ub;

    /** calculate */
    
    int alarm  = (LoC >> shift) & 1;
    int time   = (LoC >> 1) & mask;
    int newself = time==0 ? 1 : 0;

    if (time > 0) time --;
    if (LoC & alarm & 1) {
        time = mask; // reset countdown
    }

    int32_t sum = ((N&1)  + (S&1)  + (E&1)  + (W&1) +
                   (NW&1) + (NE&1) + (SE&1) + (SW&1));
    
    alarm = ((sum  > threshold) &&   // threshold
             (sum != annealing));    // annealed

    int r1 = (alarm << shift) | (time << 1) | newself;
    uint r2 = 256 - r1;
    uint r3 = HiC + (r1 & 0x80);

    /** write result to output */
    ua = (r3 >> 8) & 0xFF;
    ur = r3 & 0xFF;
    ug = r2 & 0xFF;
    ub = r1 & 0xFF;

    const float fa = float(ua)/255;
    const float fr = float(ur)/255;
    const float fg = float(ug)/255;
    const float fb = float(ub)/255;

    const half4 outItem = half4(fr, fg, fb, fa);

    outTex.write(outItem, gid);
}
