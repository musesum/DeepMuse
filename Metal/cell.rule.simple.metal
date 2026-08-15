// cell.rule.simple.metal

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

// ---------------------------------------------------------------------------
// WinSky provenance: /Users/warren/Dev/WinSky/WinSky/pixel/Rule.cpp:920-944
// (Rule::simple), declared pixel/Rule.h:124. No dedicated parameter class
// (unlike Spiral/Circle/Floral) — the whole rule is a six-case switch keyed
// on one tree leaf.
//
// Parameters:
//   version   float, buffer(0). Selects the preset via int(version).
//             Source: `simpleVersion` (BudInt, path "PatternSimpleVersion",
//             Rule.cpp:33). Tree leaf `pattern.simple.version`, UI range
//             1..5, no explicit default -> resolves to range minimum, i.e. 1
//             (tree_demo.sky:1770; see Port/CallTree.md RuleDrift note for
//             the general "no `=` -> defaults to min" BudInt convention).
//             Code switch (Rule.cpp:927-935) implements cases 0..5; case 0
//             ("horizontal ramp into bit7") is present in source but
//             UNREACHABLE from the shipped default tree (UI range starts at
//             1) — ported here for literal fidelity (CallTree.md "RuleSimple
//             / Naming drift").
//
// Divergence notes:
//  - No neighbor or self-color reads at all in the source rule: output is a
//    pure function of (x,y) and six per-preset integer coefficients
//    (xc,yc,xp,yp,xo,yo via the `SetXYPO` macro, Rule.cpp:925). The only
//    grid read is the self high word `hc` inside the `NextR` macro
//    (Rule.cpp:92-95), reproduced below as HiC extracted from a self-only
//    `inTex` read.
//  - Trivially gather-safe / embarrassingly parallel — CallTree.md flags
//    RuleSimple as the recommended first rule to port among the eight
//    shapes/rules, to validate the HiC self-counter plumbing in isolation.
//  - No buffer(1) uniform struct needed for this shape; `version` alone is
//    sufficient, so this kernel works with today's CellNode binding
//    (buffer(0) only) with zero pipeline changes required.
// ---------------------------------------------------------------------------
kernel void simpleKernel
(
 texture2d<half, access::read>  inTex   [[ texture(0) ]],
 texture2d<half, access::write> outTex  [[ texture(1) ]],
 constant float&                version [[ buffer(0)  ]],
 uint2 gid [[thread_position_in_grid]])
{
    const uint xs = outTex.get_width();   // width
    const uint ys = outTex.get_height();  // height

    /** get self C (no neighbor reads in this rule) */
    const half4 C = inTex.read(gid);
    const uint HiC = (uint(C.a * 256.) << 8) + uint(C.r * 256.);

    {{
        // cell.rule.simple — Rule::simple, pixel/Rule.cpp:920-944
        int xc = 0, yc = 0, xp = 0, yp = 0, xo = 0, yo = 0;
        int versioni = int(version);
        switch (versioni)
        {
            //                xc    yc   xp  yp    xo      yo
            case 0: xc = 2;   yc = 0;   xp = 7; yp = 0; xo = 32;   yo = 32;   break; // horizontal ramp into bit7 (UI-unreachable, see header)
            case 1: xc = 255; yc = 0;   xp = 0; yp = 0; xo = 0;    yo = 0;    break; // horizontal ramp
            case 2: xc = 0;   yc = 255; xp = 0; yp = 0; xo = 0;    yo = 0;    break; // vertical ramp
            case 3: xc = 16;  yc = 16;  xp = 0; yp = 4; xo = 0;    yo = 0;    break; // 16x16 grid
            case 4: xc = 255; yc = 255; xp = 0; yp = 0; xo = -128; yo = -128; break; // pyramid
            default:
            case 5: xc = 8;   yc = 8;   xp = 0; yp = 5; xo = -128; yo = -128; break; // "whatever"
        }

        const int xi = int(gid.x);
        const int yi = int(gid.y);
        const int r1i = ( (abs(xo + (xi * xc) / int(xs)) << xp)
                         + (abs(yo + (yi * yc) / int(ys)) << yp) ) & 0xff;

        const uint r1 = uint(r1i);
        const uint r2 = 255 - r1;
        const uint r3 = HiC + (r1 & 0x3u);

        const float fa = float(r3 >> 8) / 256.;
        const float fr = float(r3 & 0xff) / 256.;
        const float fg = float(r2) / 256.;
        const float fb = float(r1) / 256.;

        half4 outItem = half4(fr, fg, fb, fa);
        outTex.write(outItem, gid);
    }}
}
