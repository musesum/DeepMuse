// cell.rule.circle.metal

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

// ---------------------------------------------------------------------------
// WinSky provenance: /Users/warren/Dev/WinSky/WinSky/pixel/Rule.cpp:490-521
// (Rule::circle), pixel/Circle.h, pixel/Circle.cpp:4-13 (tree paths),
// tree_demo.sky:1776-1792 (ranges/defaults).
//
// Parameters (CircleUniforms struct, buffer(1) — NOT bound by CellNode
// today; see Port/B2.shapes.notes.md "required CellNode binding extension").
// All fields are `float`; booleans are stored as 0.0/1.0 and tested `>0.5`.
//   cone1On        bool-as-float, default 1                tree_demo.sky:1785
//   cone1Scale     range 5...40, no explicit default -> 5   tree_demo.sky:1786
//   cone1Strength  range 50...400, default 200              tree_demo.sky:1787
//   cone2On        bool-as-float, default 1                 tree_demo.sky:1790
//   cone2Scale     range 5...40, no explicit default -> 5   tree_demo.sky:1791
//   cone2Strength  range 50...400, default 100              tree_demo.sky:1792
//
// Divergence notes:
//  - Despite the shape's name, RuleCircle has NO ray/ScaleTo("circle") term
//    at all: `Circle` (pixel/Circle.h) declares only cone1*/cone2*, no
//    circleOn/circleRays pair (those live on Spiral and Floral instead, per
//    Port/CallTree.md "RuleCircle"). The entire field is two independent
//    decaying sin("cone") terms summed.
//  - `_hypot(xx,yy)` -> metal::length(float2(xx,yy)) below (this Metal SDK
//    has no free `hypot` overload; `length` is the equivalent Euclidean-norm
//    builtin, exact for this value range).
//  - Source Rule.cpp:509-510 computes `rAngle=atan2(xx,yy)+PI` and an
//    always-zero `rPetalValue` every cell even though neither is used by
//    RuleCircle's r1 formula (Rule.cpp:517: `rValue+rPetalValue` with
//    rPetalValue never assigned) — a dead computation in the source itself.
//    NOT reproduced here (both terms provably unused); this is a
//    non-behavior-changing simplification, not a functional divergence.
//  - `Rule.h:85`'s `circleVersion` BudInt (path "PatternCircleVersion", tree
//    range `pattern.circle.version 1..5`, tree_demo.sky:1779) is a fully
//    wired, UI-adjustable tree leaf that `Rule::circle` never reads —
//    confirmed dead by grep (Port/CallTree.md "Naming/dead-parameter
//    drift"). Deliberately NOT ported. This kernel's `version` (buffer(0))
//    parameter is retained ONLY for signature-baseline compliance (every
//    `cell.rule.*.metal` kernel takes the same 4-parameter shape) and is
//    functionally inert here — do not wire circleVersion's dead UI leaf
//    back onto it.
//  - Pure procedural distance field + self `hc` feedback through NextR; NO
//    neighbor reads at all (Port/CallTree.md "RuleCircle" — gather-safe,
//    "trivially portable", identical shape to spiral).
// ---------------------------------------------------------------------------

struct CircleUniforms
{
    float cone1On;
    float cone1Scale;
    float cone1Strength;
    float cone2On;
    float cone2Scale;
    float cone2Strength;
};
// sizeof(CircleUniforms) == 24 bytes (6 x float32, naturally 4-byte aligned,
// no inter-field padding). Field order above IS the required byte layout —
// match it exactly in any Swift-side mirror struct.

kernel void circleKernel
(
 texture2d<half, access::read>  inTex   [[ texture(0) ]],
 texture2d<half, access::write> outTex  [[ texture(1) ]],
 constant float&                version [[ buffer(0)  ]],   // reserved: dead circleVersion deliberately NOT ported (see header); kept for signature-baseline compliance
 constant CircleUniforms&       u       [[ buffer(1)  ]],
 uint2 gid [[thread_position_in_grid]])
{
    (void)version;

    const uint xs = outTex.get_width();   // width
    const uint ys = outTex.get_height();  // height

    /** get self C (no neighbor reads in this rule) */
    const half4 C = inTex.read(gid);
    const uint HiC = (uint(C.a * 256.) << 8) + uint(C.r * 256.);

    {{
        // cell.rule.circle — Rule::circle, pixel/Rule.cpp:490-521
        const float x2 = float(xs) * 0.5;
        const float y2 = float(ys) * 0.5;
        const float xx = float(gid.x) - x2;
        const float yy = float(gid.y) - y2;

        const float fDist = length(float2(xx, yy));
        float rValue = 0.0;

        if (u.cone1On > 0.5) rValue += sin(fDist / 1000.0 * u.cone1Scale) * u.cone1Strength;
        if (u.cone2On > 0.5) rValue += sin(fDist / 1000.0 * u.cone2Scale) * u.cone2Strength;

        const uint r1 = uint(int(rValue) & 0xff);
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
