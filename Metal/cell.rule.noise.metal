#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

// ============================================================================
// cell.rule.noise.metal  —  noiseKernel
// ----------------------------------------------------------------------------
// Source of truth : WinSky  pixel/Rule.cpp:946-958  (Rule::noise)
//                   Rand32 macro  pixel/Rule.cpp:10  (rand()|(rand()<<16))
//
// Behaviour (source): a single `count` is seeded once from Rand32%prob and
//   decremented in strict raster order; each time it goes negative the cell is
//   re-randomised  *next = (c & 0xffffff00) + (rand()&0xff)  and count reseeds.
//   Otherwise  *next = c  (identity). BOTH branches keep the upper 24 bits of c
//   verbatim (bypasses NextR); only the low byte .b changes on a fired cell.
//   prob = 1 << noiseBits.
//
// Variant / version map:
//   Noise has NO version variants; its only knob is noiseBits. buffer(0)
//   `version` is REPURPOSED as noiseBits.
//     version(=noiseBits) 1 -> prob 2 ... 8 -> prob 256.
//
// Parameters (from CallTree.md §2):
//   noiseBits  range 1..8  default 1  (WinSky "PatternNoiseBits",
//              tree_demo.sky:1755)  -> carried on buffer(0) `version`.
//
// Metal fidelity divergence (CallTree.md §4):
//   1. The raster-order run-length RNG is SEQUENTIAL by construction and cannot
//      be reproduced bit-for-bit on the GPU. This port uses an INDEPENDENT
//      per-cell probability test  P(fire) = 1/prob  (statistically equivalent
//      density, not identical per-frame output).
//   2. Non-.b channels (.g/.r/.a) are copied VERBATIM from the input, matching
//      the source's NextR bypass on both branches.
//   3. RESOLVED (port): a per-frame `frame` uniform is now bound at buffer(1)
//      by CellNode.computeShader and folded into BOTH the fire-mask hash and the
//      random-byte hash, so the pattern re-randomises frame to frame — matching
//      the source's per-frame reseeded noise in density and animation. buffer(1)
//      is bound only for the kernels that declare it (no melt-style hazard).
//   4. Scaling convention: reads x255 / writes /255.
// ============================================================================

static inline uint noiseHashU(uint x)
{
    x ^= x >> 16; x *= 0x7feb352du;
    x ^= x >> 15; x *= 0x846ca68bu;
    x ^= x >> 16; return x;
}
static inline uint noiseHash2(uint2 g, uint seed)
{
    return noiseHashU(g.x * 73856093u ^ g.y * 19349663u ^ (seed * 2654435761u + 1u));
}

kernel void noiseKernel
(
 texture2d<half, access::read>  inTex   [[ texture(0) ]],
 texture2d<half, access::write> outTex  [[ texture(1) ]],
 constant float&                version [[ buffer(0)  ]],   // REPURPOSED: noiseBits 1..8 (default 1)
 constant float&                frame   [[ buffer(1)  ]],   // per-frame counter (CellNode-bound) — animates the noise
 uint2 gid [[thread_position_in_grid]])
{
    const half4 C = inTex.read(gid);

    {{ // cell.rule.noise

    uint  bits = uint(clamp(version, 1.0, 8.0));   // noiseBits
    float prob = float(1u << bits);                 // 2 .. 256

    uint  fseed = uint(max(version, 0.0)) + uint(max(frame, 0.0)) * 65537u;

    // independent per-cell fire test, P(fire) = 1/prob
    uint  h  = noiseHash2(gid, fseed);
    float r  = float(h & 0xffffffu) / float(0x1000000u);   // 0 <= r < 1

    half4 outC = C;                                 // copy .g/.r/.a (and .b) verbatim
    if (r < 1.0 / prob) {
        // fresh random low byte (decorrelated hash)
        uint rb = noiseHash2(gid, fseed * 2u + 12345u) & 0xffu;
        outC.b = half(float(rb) / 255.);
    }
    outTex.write(outC, gid);
    }}
}
