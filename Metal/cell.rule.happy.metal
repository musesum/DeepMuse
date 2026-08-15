#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

// ============================================================================
// cell.rule.happy.metal  —  happyKernel
// ----------------------------------------------------------------------------
// Source of truth : WinSky  pixel/Rule.cpp:827-880  (Rule::happy)
//                   v1 helper Rule::swap  pixel/Rule.cpp:681-701  (NOT PORTED)
//                   GoVect constants       pixel/Univ.h:12-16
//                   NextR macro            pixel/Rule.cpp:92-95
//                   neighbour macros       pixel/Univ_def.h
//
// Variant / version map (selected by buffer(0) `version` == happyVersion):
//   v2  (version 2, DEFAULT) : cardinal directional combine.
//         r1 = (n & GoDown) + (s & GoUp) + (e & GoLeft) + (w & GoRight)
//         GoDown=17 GoUp=34 GoLeft=68 GoRight=136  (each < 256, low byte only)
//   v3  (version 3)          : 8-neighbour bit-OR combine, one bit per neighbour.
//         r1 = (n&1)+(ne&2)+(e&4)+(se&8)+(s&16)+(sw&32)+(w&64)+(nw&128)
//   Both write via NextR (.b=r1, .g=255-r1, HiC=hc+(r1&3)).
//
// Parameters (from CallTree.md §2):
//   happyVersion  range 2..3  default 2   (WinSky "CellHappyVersion",
//                 tree_demo.sky:1900)  -> carried on buffer(0) `version`.
//   happyShift    range 1..8  default 8   -> DROPPED: its only consumer is v1,
//                 which is omitted here (see below).
//
// OMITTED VARIANT — v1  (TODO(port)):
//   Rule::happy v1 (Rule.cpp:834-851) is NOT portable as a single gather kernel.
//   It calls Rule::swap, which walks the whole grid in raster order MUTATING
//   *prev in place, swapping a cell with an arbitrary (dx,dy)-offset neighbour
//   and marking both with a per-pass "claimed" bit (|0x10000). It is in-place,
//   order-dependent, and non-local — a GPU port needs an atomic compare-and-swap
//   scatter or a multi-pass stochastic sorting network, not one gather pass.
//   v1 also zeroes bits 8-31 each pass (*next = llc), so its non-.b channels are
//   0, unlike the NextR convention. The shipped tree range (2..3) never selects
//   v1, so it is deferred. If a v1 visual reformulation is later added, write
//   .g/.r/.a = 0 (not the NextR derivation) to match its *next = llc semantics.
//   This kernel maps any version < 3 to v2 and version >= 3 to v3.
//
// Metal fidelity divergence (CallTree.md §4):
//   v2/v3 are direct NextR->packed-RGBA gather translations (no divergence).
//   Scaling convention: reads x255 (+0.5 round) / writes /255 (matches ave/slide).
// ============================================================================

kernel void happyKernel
(
 texture2d<half, access::read>  inTex   [[ texture(0) ]],
 texture2d<half, access::write> outTex  [[ texture(1) ]],
 constant float&                version [[ buffer(0)  ]],   // happyVersion 2..3 (default 2)
 uint2 gid [[thread_position_in_grid]])
{
    const uint  xs = outTex.get_width();
    const uint  ys = outTex.get_height();
    const uint2 ci(gid.x, gid.y);

    uint2 ni, si, ei, wi;       // n s e w
    uint2 nwi, nei, sei, swi;   // nw ne se sw

    /** setup 8-neighbour toroidal indices */ {
#define ew(ex,ey, wx,wy) ei=uint2(ex,ey); wi=uint2(wx,wy);
#define ns(nx,ny, sx,sy) ni=uint2(nx,ny); si=uint2(sx,sy);
#define nwsw(nwx,nwy, swx,swy) nwi=uint2(nwx,nwy); swi=uint2(swx,swy);
#define nese(nex,ney, sex,sey) nei=uint2(nex,ney); sei=uint2(sex,sey);
        if (gid.x == 0) {
            ew(1, gid.y, xs-1, gid.y)
            if (gid.y == 0) {
                ns  (   0, ys-1,    0,1)
                nwsw(xs-1, ys-1, xs-1,1)
                nese(   1, ys-1,    1,1)
            } else if (gid.y == ys-1) {
                ns  (   0, ys-2,    0,0)
                nwsw(xs-1, ys-2, xs-1,0)
                nese(   1, ys-2,    1,0)
            } else {
                ns  (   0, gid.y-1,    0, gid.y+1)
                nwsw(xs-1, gid.y-1, xs-1, gid.y+1)
                nese(   1, gid.y-1,    1, gid.y+1)
            }
        } else if (gid.x == xs-1) {
            ew(0, gid.y, xs-2, gid.y)
            if (gid.y == 0) {
                ns  (xs-1, ys-1, xs-1,1)
                nwsw(xs-2, ys-1, xs-2,1)
                nese(   0, ys-1,    0,1)
            } else if (gid.y == ys-1) {
                ns  (xs-1, ys-2, xs-1,0)
                nwsw(xs-2, ys-2, xs-2,0)
                nese(   0, ys-2,    0,0)
            } else {
                ns  (xs-1,gid.y-1, xs-1,gid.y+1)
                nwsw(xs-2,gid.y-1, xs-2,gid.y+1)
                nese(   0,gid.y-1,    0,gid.y+1)
            }
        } else {
            ew(gid.x+1, gid.y, gid.x-1, gid.y)
            if (gid.y == 0) {
                ns  (gid.x,   ys-1, gid.x,  1)
                nwsw(gid.x-1, ys-1, gid.x-1,1)
                nese(gid.x+1, ys-1, gid.x+1,1)
            } else if (gid.y == ys-1) {
                ns  (gid.x,   ys-2, gid.x,   0)
                nwsw(gid.x-1, ys-2, gid.x-1, 0)
                nese(gid.x+1, ys-2, gid.x+1, 0)
            } else {
                ns  (gid.x,   gid.y-1, gid.x,   gid.y+1)
                nwsw(gid.x-1, gid.y-1, gid.x-1, gid.y+1)
                nese(gid.x+1, gid.y-1, gid.x+1, gid.y+1)
            }
        }
    }

    const half4 C  = inTex.read(ci);
    const uint  nB  = uint(inTex.read(ni ).b * 255. + 0.5);
    const uint  sB  = uint(inTex.read(si ).b * 255. + 0.5);
    const uint  eB  = uint(inTex.read(ei ).b * 255. + 0.5);
    const uint  wB  = uint(inTex.read(wi ).b * 255. + 0.5);
    const uint  nwB = uint(inTex.read(nwi).b * 255. + 0.5);
    const uint  neB = uint(inTex.read(nei).b * 255. + 0.5);
    const uint  seB = uint(inTex.read(sei).b * 255. + 0.5);
    const uint  swB = uint(inTex.read(swi).b * 255. + 0.5);

    const uint HiC = (uint(C.a * 255. + 0.5) << 8) + uint(C.r * 255. + 0.5);

    int v = int(version);   // happyVersion (2 or 3); v1 omitted -> v<3 maps to v2
    uint r1;
    if (v >= 3) {
        // v3: 8-neighbour bit-OR combine  (Rule.cpp:867-877)
        r1 = (nB  &   1u) + (neB &   2u) + (eB  &   4u) + (seB &   8u)
           + (sB  &  16u) + (swB &  32u) + (wB  &  64u) + (nwB & 128u);
    } else {
        // v2: cardinal directional combine  (Rule.cpp:858-863)
        const uint GoDown = 17u, GoUp = 34u, GoLeft = 68u, GoRight = 136u;
        r1 = (nB & GoDown) + (sB & GoUp) + (eB & GoLeft) + (wB & GoRight);
    }

    // NextR pack
    uint r2 = 255u - r1;
    uint r3 = HiC + (r1 & 3u);
    float fa = float((r3 >> 8) & 0xffu) / 255.;
    float fr = float( r3       & 0xffu) / 255.;
    float fg = float(r2) / 255.;
    float fb = float(r1) / 255.;
    outTex.write(half4(fr, fg, fb, fa), ci);
}
