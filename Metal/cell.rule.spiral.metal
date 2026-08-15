// cell.rule.spiral.metal

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

// ---------------------------------------------------------------------------
// WinSky provenance: /Users/warren/Dev/WinSky/WinSky/pixel/Rule.cpp:459-488
// (Rule::spiral), pixel/Spiral.h, pixel/Spiral.cpp:4-12 (tree paths),
// tree_demo.sky:1794-1808 (ranges/defaults).
//
// Parameters (SpiralUniforms struct, buffer(1) — NOT bound by CellNode
// today; see Port/B2.shapes.notes.md "required CellNode binding extension").
// All fields are `float`; booleans are stored as 0.0/1.0 and tested `>0.5`.
//   cone1On        bool-as-float, default 1                tree_demo.sky:1802
//   cone1Scale     range 5...40, no explicit default -> 5   tree_demo.sky:1803
//   cone1Strength  range 50...400, default 100              tree_demo.sky:1804
//   circleOn       bool-as-float, default 1                 tree_demo.sky:1807
//   circleRays     range 1...9, default 1                   tree_demo.sky:1808
//
// Divergence notes:
//  - Pure procedural distance/angle field from grid center, summed with a
//    self `hc` feedback term through NextR; NO neighbor reads at all
//    (Port/CallTree.md "RuleSpiral" — gather-safe, "trivially portable").
//  - `_hypot(xx,yy)` (Rule.cpp:477) -> metal::length(float2(xx,yy)) below
//    (this Metal SDK has no free `hypot` overload; `length` is the
//    equivalent Euclidean-norm builtin, exact for this value range).
//  - `atan2(xx,yy)+PI` (Rule.cpp:478) is ported with the SAME argument
//    order as source (x-value first, y-value second) rather than swapped to
//    the conventional atan2(y,x) reading — literal port, not a bugfix. `PI`
//    itself is WinSky's `#define PI 3.14159265358979323846`
//    (main/Defs.h:20), reproduced below as `kPI` rather than relying on any
//    Metal built-in constant, for exact-literal fidelity.
//  - SEAM FIX (2026-07-11, intentional divergence): source Rule.cpp:481
//    `ScaleTo(rAngle,0,2π)*circleRays` sawtooths a DIRECTIONAL angle — it
//    breaks at the atan2 branch cut (disjoint line from center to top) and
//    cannot tile the torus (canvas repeat/shift exposes seams on all 4 texture
//    edges: only fields EVEN in both dx and dy tile with a centered anchor;
//    a directional spoke sweep is odd). Replaced with a QUARTER-FOLDED angle
//    `atan2(|dx|,|dy|) ∈ [0, π/2]`: even in both axes, so no branch cut, no
//    edge seams, and continuity holds for ANY rays value (the flo `0_24`
//    rangei scales without rounding, so fractional rays arrive live).
//    Visual divergence: rays render as 4-fold mirrored fans (`rays` bands per
//    quadrant) instead of WinSky's full-sweep spokes — the only spoke form
//    that tiles. The ring term length(dx,dy) is already even → tiles as-is.
//    `scaleTo` retained above for provenance reference.
//  - `Rule.h:85`'s `circleVersion` BudInt (path "PatternCircleVersion")
//    belongs textually to the Rule class but is consumed by neither
//    `Rule::spiral` nor (per Port/CallTree.md) `Rule::circle` — it has no
//    live effect anywhere and is not ported to either kernel. This kernel's
//    `version` (buffer(0)) parameter has no live source counterpart for
//    spiral either; it is retained ONLY for signature-baseline compliance
//    (every `cell.rule.*.metal` kernel takes the same 4-parameter shape) and
//    is functionally inert here.
// ---------------------------------------------------------------------------

struct SpiralUniforms
{
    float cone1On;
    float cone1Scale;
    float cone1Strength;
    float circleOn;
    float circleRays;
};
// sizeof(SpiralUniforms) == 20 bytes (5 x float32, naturally 4-byte aligned,
// no inter-field padding). Field order above IS the required byte layout —
// match it exactly in any Swift-side mirror struct.

constant float kPI = 3.14159265358979323846f; // WinSky main/Defs.h:20

static inline float scaleTo(float rValue, float rLow, float rHigh)
{
    // Rule.cpp:431-438 (Rule.cpp file-scope `ScaleTo`)
    rValue = clamp(rValue, rLow, rHigh);
    float fRange = rHigh - rLow;
    return trunc(((rValue - rLow) / fRange) * 255.0);
}

kernel void spiralKernel
(
 texture2d<half, access::read>  inTex   [[ texture(0) ]],
 texture2d<half, access::write> outTex  [[ texture(1) ]],
 constant float&                version [[ buffer(0)  ]],   // reserved: no live variant selector in source Rule::spiral; kept for signature-baseline compliance
 constant SpiralUniforms&       u       [[ buffer(1)  ]],
 uint2 gid [[thread_position_in_grid]])
{
    (void)version;

    const uint xs = outTex.get_width();   // width
    const uint ys = outTex.get_height();  // height

    /** get self C (no neighbor reads in this rule) */
    const half4 C = inTex.read(gid);
    const uint HiC = (uint(C.a * 256.) << 8) + uint(C.r * 256.);

    {{
        // cell.rule.spiral — Rule::spiral, pixel/Rule.cpp:459-488
        const float x2 = float(xs) * 0.5;
        const float y2 = float(ys) * 0.5;
        const float xx = float(gid.x) - x2;
        const float yy = float(gid.y) - y2;

        const float fDist  = length(float2(xx, yy));
        float rValue = 0.0;

        if (u.cone1On  > 0.5) rValue += sin(fDist / 1000.0 * u.cone1Scale) * u.cone1Strength;
        if (u.circleOn > 0.5) {
            // quarter-folded angle: even in both axes → no atan2 branch cut,
            // tiles the torus, continuous for any rays value (header note)
            const float aq = atan2(abs(xx), abs(yy)); // 0 … π/2
            rValue += trunc(aq / (kPI * 0.5) * 256.0 * u.circleRays);
        }

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
