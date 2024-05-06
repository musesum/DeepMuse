#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;
#define Range(x, min, max) (x<min ? min : (x>max ? max : x))

/// reaction diffusioin cellular automata rule
kernel void melt
(
 texture2d<half, access::read>  inTex   [[ texture(0) ]],
 texture2d<half, access::write> outTex  [[ texture(1) ]],
 constant float&                version [[ buffer(0) ]],
 constant float&                bits    [[ buffer(1) ]],
 uint2 gid [[thread_position_in_grid]])
{
    const uint xs = outTex.get_width();   // width
    const uint ys = outTex.get_height();  // height

    const uint2 ci(gid.x, gid.y);
    uint2 ni, si, ei, wi; // n s e w indexs

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

    /** get n s e w c */
    const half4 c = inTex.read(ci); // center
    const half4 n = inTex.read(ni); // north
    const half4 s = inTex.read(si); // south
    const half4 e = inTex.read(ei); // east
    const half4 w = inTex.read(wi); // west
    
    const float HiN = (n.a * 255) * exp2(8.) + (n.r * 255); // hi north
    const float LoN = (n.g * 255) * exp2(8.) + (n.b * 255); // lo north
    const float HiS = (s.a * 255) * exp2(8.) + (s.r * 255); // hi south
    const float LoS = (s.g * 255) * exp2(8.) + (s.b * 255); // lo south
    const float HiE = (e.a * 255) * exp2(8.) + (e.r * 255); // hi east
    const float LoE = (e.g * 255) * exp2(8.) + (e.b * 255); // lo east
    const float HiW = (w.a * 255) * exp2(8.) + (w.r * 255); // hi west
    const float LoW = (w.g * 255) * exp2(8.) + (w.b * 255); // lo west
    const float HiC = (c.a * 255) * exp2(8.) + (c.r * 255); // hi center
    const float LoC = (c.g * 255) * exp2(8.) + (c.b * 255); // lo cennter
    const float C = HiC * exp2(16.) + LoC;

    /** calculate */

    float r1 = (LoC + LoN + LoS + LoE + LoW) / 5;
    float r2 = ((C / exp2(10+version*4)) + HiN + HiS + HiE + HiW) / (68 - 56 * version);
    float d1 = (0xffff - r1) / exp2(9 - 4 * version);

    r1 = Range(r1+d1, 0, 0xffff);
    r2 = Range(r2   , 0, 0xffff);

    float fa = trunc(r2/exp2(8.)) / 255.;
    float fr = fmod(r2,     256.) / 255.;
    float fg = trunc(r1/exp2(8.)) / 255.;
    float fb = fmod(r1,     256.) / 255.;

    half4 outItem = half4(fr, fg, fb, fa);

    outTex.write(outItem, gid);
}
