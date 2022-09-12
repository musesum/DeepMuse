#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

/// average cellular automata rule
kernel void ave(texture2d<half, access::read_write> inTex  [[texture(0)]],
                texture2d<half, access::read_write> outTex [[texture(1)]],
                constant float &version [[buffer(0)]],
                uint2 gid [[thread_position_in_grid]]) {

    const uint xs = outTex.get_width();   // width
    const uint ys = outTex.get_height();  // height
    const uint2 ci(gid.x, gid.y);
    uint2 ni, si, ei, wi;       // n s e w indexs

    /** setup indexes for n s e w */ {

        // x boundaries
        if (gid.x == 0) {
            ei = uint2(   1, gid.y);
            wi = uint2(xs-1, gid.y);
            // y boundaries
            if (gid.y == 0) {
                ni = uint2(    0, ys-1);
                si = uint2(    0,    1);
            } else if (gid.y == ys-1) {
                ni = uint2(    0, ys-2);
                si = uint2(    0,    0);
            } else {
                ni = uint2(    0, gid.y-1);
                si = uint2(    0, gid.y+1);
            }
        } else if (gid.x == xs-1) {
            ei = uint2(   0, gid.y);
            wi = uint2(xs-2, gid.y);
            // y boundaries
            if (gid.y == 0) {
                ni  = uint2(xs-1, ys-1);
                si  = uint2(xs-1,    1);
            } else if (gid.y == ys-1) {
                ni  = uint2(xs-1, ys-2);
                si  = uint2(xs-1,    0);
            } else {
                ni  = uint2(xs-1, gid.y-1);
                si  = uint2(xs-1, gid.y+1);
            }
        } else {
            ei = uint2(gid.x+1, gid.y);
            wi = uint2(gid.x-1, gid.y);
            // y boundaries
            if (gid.y == 0) {
                ni  = uint2(gid.x,   ys-1);
                si  = uint2(gid.x,      1);
            } else if (gid.y == ys-1) {
                ni  = uint2(gid.x,   ys-2);
                si  = uint2(gid.x,      0);
            } else {
                ni  = uint2(gid.x,   gid.y-1);
                si  = uint2(gid.x,   gid.y+1);
            }
        }
    }

    /** get n s e w c C */
    const half4 C = inTex.read(ci);
    const float c = C.b;
    const float n = inTex.read(ni).b;
    const float s = inTex.read(si).b;
    const float e = inTex.read(ei).b;
    const float w = inTex.read(wi).b;

    const float HiC = (C.a * 255 * 256. + C.r * 255);

    /** calculate */

    // average of the sum of averages
    float r1 = ((n + s + e + w + c)/5);
    r1 *= 255. * (0.95 + version/10.);
    float r2 = 256. - r1;
    float r3 = HiC + float(uint(r1) & 0x80);

    float fa = trunc(r3/256.) / 255.;
    float fr = fmod(r3, 256.) / 255.;
    float fg = r2 / 255.;
    float fb = r1 / 255.;

    half4 outItem = half4(fr, fg, fb, fa);
    outTex.write(outItem, gid);
}

kernel void ave3(texture2d<half, access::read_write> inTex  [[texture(0)]],
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
                ni = uint2(gid.x, ys-1);
                si = uint2(gid.x,    1);
                nwi = uint2(xs-1, ys-1);
                swi = uint2(xs-1,    1);
                nei = uint2(   1, ys-1);
                sei = uint2(   1,    1);
            } else if (gid.y == ys-1) {
                ni = uint2(gid.x, ys-2);
                si = uint2(gid.x,    0);
                nwi = uint2(xs-1, ys-2);
                swi = uint2(xs-1,    0);
                nei = uint2(   1, ys-2);
                sei = uint2(   1,    0);
            } else {
                ni = uint2(gid.x, gid.y-1);
                si = uint2(gid.x, gid.y+1);
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
                ni = uint2(gid.x, ys-1);
                si = uint2(gid.x,    1);
                nwi = uint2(xs-1, ys-1);
                swi = uint2(xs-1,    1);
                nei = uint2(   0, ys-1);
                sei = uint2(   0,    1);
            } else if (gid.y == ys-1) {
                ni = uint2(gid.x, ys-2);
                si = uint2(gid.x,    0);
                nwi = uint2(xs-2, ys-2);
                swi = uint2(xs-2,    0);
                nei = uint2(   0, ys-2);
                sei = uint2(   0,    0);
            } else {
                ni = uint2(gid.x, gid.y-1);
                si = uint2(gid.x, gid.y+1);
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

    const half4 C = inTex.read(ci);
    const float c = C.b;
    const float n = inTex.read(ni).b;
    const float s = inTex.read(si).b;
    const float e = inTex.read(ei).b;
    const float w = inTex.read(wi).b;

    const float nw = inTex.read(nwi).b;
    const float ne = inTex.read(nei).b;
    const float se = inTex.read(sei).b;
    const float sw = inTex.read(swi).b;

    const float HiC = (C.a * 255 * 256. + C.r * 255);

        // sum up delta values of each quadrant
    float ul = fabs(nw-n)+fabs(n-c)+fabs(c-w)+fabs(w-nw); // upper left quad
    float ur = fabs(n-ne)+fabs(ne-e)+fabs(e-c)+fabs(c-n); // upper right quad
    float lr = fabs(e-se)+fabs(se-s)+fabs(s-c)+fabs(c-e); // lower right quad
    float ll = fabs(s-sw)+fabs(sw-w)+fabs(w-c)+fabs(c-s); // lower left quad

    float mx = max(max(ul, ur), max(lr, ll)); // max delta values
    float sum = 0;
    float div = 0;
    // sum of the average of each quadrant, which matches the maximum variation
    if (ul==mx) {sum += (nw+n+w+c)/4; div++;}
    if (ur==mx) {sum += (n+ne+e+c)/4; div++;}
    if (lr==mx) {sum += (e+se+s+c)/4; div++;}
    if (ll==mx) {sum += (s+sw+w+c)/4; div++;}

    // average of the sum of averages

    float r1c = (sum/div);
    float r1a = ((n + s + e + w + c)/5);
    float r1b = ((nw + ne + se + sw + c)/5);
    float r1 = 0;
    float veri = 2; //version * 3;
    if      (veri > 2.) { r1 = (3.-veri) * r1c + (veri-2.) * r1a; }
    else if (veri > 1.) { r1 = (2.-veri) * r1b + (veri-1.) * r1c; }
    else                { r1 = (1.-veri) * r1a + (veri   ) * r1b; }

    r1 *= 255. * (0.95 + version/10.);
    float r2 = 256. - r1;
    float r3 = HiC + float(uint(r1) & 0x80);

    float fa = trunc(r3/256.) / 255.;
    float fr = fmod(r3, 256.) / 255.;
    float fg = r2 / 255.;
    float fb = r1 / 255.;

    half4 outItem = half4(fr, fg, fb, fa);

    outTex.write(outItem, gid);
}
