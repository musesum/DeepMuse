// cell.rule.floral.metal

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

// ---------------------------------------------------------------------------
// WinSky provenance: /Users/warren/Dev/WinSky/WinSky/pixel/Rule.cpp:523-599
// (Rule::floral), pixel/Floral.h, pixel/Floral.cpp:4-65 (ctor + ::random),
// tree_demo.sky:1810-1850 (ranges/defaults).
//
// Parameters (FloralUniforms struct, buffer(1) — NOT bound by CellNode
// today; see Port/B2.shapes.notes.md "required CellNode binding extension").
// All fields are `float`; booleans are stored as 0.0/1.0 and tested `>0.5`.
//   (reroll trigger field removed 2026-07-11 — Refactor.h; struct begins
//    at cone1On, 22 floats total)
//   cone1On         bool-as-float, default 1               tree_demo.sky:1818
//   cone1Scale      range 5...40, no explicit default -> 5  tree_demo.sky:1819
//   cone1Strength   range 50...400, no explicit default -> 50 tree_demo.sky:1820
//   cone2On         bool-as-float, default 1                tree_demo.sky:1823
//   cone2Scale      range 5...40, no explicit default -> 5   tree_demo.sky:1824
//   cone2Strength   range 50...400, default 100              tree_demo.sky:1825
//   circleOn        bool-as-float, default 1                 tree_demo.sky:1828
//   circleRays      range 1...24, default 1                  tree_demo.sky:1829
//   columnOn        bool-as-float, default 1                 tree_demo.sky:1832
//   columnNum       range 1...8, no explicit default -> 1     tree_demo.sky:1833
//   columnRays      range 2...9, no explicit default -> 2     tree_demo.sky:1834
//                   NOTE: real, UI-bound tree leaf, but `Rule::floral` never
//                   reads it (only columnNum feeds the field, Rule.cpp:573)
//                   — kept for struct/Swift-layout completeness, unread by
//                   this kernel, matching source behavior exactly.
//   columnStrength  range 6...306, default 306                tree_demo.sky:1835
//   petal1On        bool-as-float, default 1                  tree_demo.sky:1838
//   petal1Num       range 1...14, no explicit default -> 1     tree_demo.sky:1839
//   petal1Spiralz   range -50...50, no explicit default -> -50 tree_demo.sky:1840
//   petal1Petalz    range 0...50, no explicit default -> 0     tree_demo.sky:1841
//   petal1Strength  range 400...1000, default 800              tree_demo.sky:1842
//   petal2On        bool-as-float, default 1                   tree_demo.sky:1845
//   petal2Num       range 1...7, no explicit default -> 1       tree_demo.sky:1846
//   petal2Spiralz   range -50...50, no explicit default -> -50  tree_demo.sky:1847
//   petal2Petalz    range 0...50, no explicit default -> 0      tree_demo.sky:1848
//   petal2Strength  range 400...1000, default 800               tree_demo.sky:1849
//
// Dropped (deliberately NOT ported): `petal1.strong 4..10=8` /
// `petal2.strong 4..10=80` (tree_demo.sky:1843,1850) — tree leaves with no
// corresponding `Floral` class member / no code consumer anywhere
// (Port/CallTree.md "Dead tree params").
//
// Divergence notes:
//  - SEAM FIX (2026-07-11, intentional divergence, matches cell.rule.spiral):
//    source `rAngle = atan2(xx,yy)+π` is DIRECTIONAL — every angular term
//    (circle-ray sawtooth, column sin, petal1/petal2 sin) breaks at the atan2
//    branch cut (line from center to top; sin terms only stay continuous for
//    INTEGER num, and flo `0_14` rangei scales without rounding), and a
//    directional angle cannot tile the torus (canvas repeat/shift exposes
//    seams on all 4 texture edges — only fields EVEN in both dx and dy tile
//    with a centered anchor). All four angular sites now use the
//    QUARTER-FOLDED angle `aq = atan2(|dx|,|dy|) ∈ [0, π/2]`: even in both
//    axes → no branch cut, no edge seams, continuous for ANY fractional
//    param. Visual divergence: petals/rays/columns render 4-fold mirrored.
//  - `_hypot(xx,yy)` -> metal::length(float2(xx,yy)) below (this Metal SDK
//    has no free `hypot` overload; `length` is the equivalent Euclidean-norm
//    builtin, exact for this value range).
//  - Field math is gather-safe, same class as spiral/circle: up to four
//    terms (cone1, cone2, circleOn-rays, columnOn-rays) summed into
//    `rValue`, plus ONE of petal1/petal2 into `rPetalValue`. Both `if`
//    blocks in the source are unconditional writes, not else-if
//    (Rule.cpp:575-593) — when both petal1On and petal2On are true, petal2
//    always wins (its block runs second and overwrites, does not
//    accumulate). Ported literally with the same overwrite order below.
//  - Self `hc` feedback through NextR only; NO neighbor reads at all.
//  - Source reroll side-effect (`flor.random()`, Rule.cpp:525-526) retired
//    2026-07-11 with Refactor.h: this kernel renders DETERMINISTICALLY from
//    whatever FloralUniforms it is handed. Historical analysis of the
//    host-side reroll design lives in Port/B2.shapes.notes.md.
//  - Dead code NOT ported: `Rule::flora` (singular, no "l" — distinct
//    symbol, Rule.cpp:601-679, declared Rule.h:127) builds a fully-random
//    cone/circle/column/petal set and renders the same field shape as
//    `floral`, but has ZERO callers anywhere in the source tree (grep for
//    `.flora(`, `::flora`, `rule.flora` returns only its own definition —
//    Port/CallTree.md confirms).
// ---------------------------------------------------------------------------

struct FloralUniforms
{
    // reroll-trigger field removed 2026-07-11 (Refactor.h)
    float cone1On;
    float cone1Scale;
    float cone1Strength;
    float cone2On;
    float cone2Scale;
    float cone2Strength;
    float circleOn;
    float circleRays;
    float columnOn;
    float columnNum;
    float columnRays;      // unread by Rule::floral; kept for layout parity
    float columnStrength;
    float petal1On;
    float petal1Num;
    float petal1Spiralz;
    float petal1Petalz;
    float petal1Strength;
    float petal2On;
    float petal2Num;
    float petal2Spiralz;
    float petal2Petalz;
    float petal2Strength;
};
// sizeof(FloralUniforms) == 88 bytes (22 x float32, naturally 4-byte
// aligned, no inter-field padding). Field order above IS the required byte
// layout — match it exactly in any Swift-side mirror struct.

constant float kPI = 3.14159265358979323846f; // WinSky main/Defs.h:20

static inline float scaleTo(float rValue, float rLow, float rHigh)
{
    // Rule.cpp:431-438 (Rule.cpp file-scope `ScaleTo`)
    rValue = clamp(rValue, rLow, rHigh);
    float fRange = rHigh - rLow;
    return trunc(((rValue - rLow) / fRange) * 255.0);
}

kernel void floralKernel
(
 texture2d<half, access::read>  inTex   [[ texture(0) ]],
 texture2d<half, access::write> outTex  [[ texture(1) ]],
 constant float&                version [[ buffer(0)  ]],   // reserved: no live variant selector in source Rule::floral; kept for signature-baseline compliance
 constant FloralUniforms&       u       [[ buffer(1)  ]],
 uint2 gid [[thread_position_in_grid]])
{
    (void)version;

    const uint xs = outTex.get_width();   // width
    const uint ys = outTex.get_height();  // height

    /** get self C (no neighbor reads in this rule) */
    const half4 C = inTex.read(gid);
    const uint HiC = (uint(C.a * 256.) << 8) + uint(C.r * 256.);

    {{
        // cell.rule.floral — Rule::floral, pixel/Rule.cpp:523-599
        const float x2 = float(xs) * 0.5;
        const float y2 = float(ys) * 0.5;
        const float xx = float(gid.x) - x2;
        const float yy = float(gid.y) - y2;

        const float fDist  = length(float2(xx, yy));
        // quarter-folded angle: even in both axes → no atan2 branch cut,
        // tiles the torus, continuous for fractional params (header note)
        const float aq = atan2(abs(xx), abs(yy)); // 0 … π/2
        float rValue = 0.0;

        if (u.cone1On  > 0.5) rValue += sin(fDist / 1000.0 * u.cone1Scale)  * u.cone1Strength;
        if (u.cone2On  > 0.5) rValue += sin(fDist / 1000.0 * u.cone2Scale)  * u.cone2Strength;
        if (u.circleOn > 0.5) rValue += trunc(aq / (kPI * 0.5) * 256.0 * u.circleRays);
        if (u.columnOn > 0.5) rValue += sin(aq * u.columnNum) * u.columnStrength;

        float rPetalValue = 0.0;
        if (u.petal1On > 0.5)
        {
            rPetalValue = sin( (aq * u.petal1Num) + (fDist / 1000.0 * u.petal1Spiralz) )
                          * (u.petal1Strength / 1000.0);
            rPetalValue = scaleTo(rPetalValue, -1.0, 1.0) + (fDist / 10.0 * u.petal1Petalz);
        }
        if (u.petal2On > 0.5)
        {
            // unconditional overwrite, not accumulation — petal2 wins ties, matches Rule.cpp:585-593
            rPetalValue = sin( (aq * u.petal2Num) + (fDist / 1000.0 * u.petal2Spiralz) )
                          * (u.petal2Strength / 1000.0);
            rPetalValue = scaleTo(rPetalValue, -1.0, 1.0) + (fDist / 10.0 * u.petal2Petalz);
        }

        const uint r1 = uint(int(rValue + rPetalValue) & 0xff);
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
