#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

// ============================================================================
// cell.rule.drift.metal  —  driftKernel
// ----------------------------------------------------------------------------
// Source of truth : WinSky  pixel/Rule.cpp:227-260  (Rule::drift)
//                   packing / NextR macro  pixel/Rule.cpp:92-95
//                   Rand32 macro           pixel/Rule.cpp:10  (rand()|(rand()<<16))
//                   neighbour macros       pixel/Univ_def.h  (c/n/e/s/w, llc, hc, lc)
//
// Behaviour (source): with probability 1/(1<<(driftBits-1)) a cell is TESTED.
//   Tested cell counts its 4 cardinal neighbours' low-2-bit "border colour"
//   (byte & 3). If every neighbour's 2-bit colour is either self's 2-bit
//   colour c&3 or the adjacent colour (c+1)&3  (cand[(c+1)&3]+cand[c&3]==4),
//   the cell drifts: value += 1 (via NextR). Otherwise it is copied unchanged.
//   If the random gate is FALSE the cell is NOT written at all in the source
//   (relies on 2-frames-back ping-pong persistence, see CallTree.md §2/§4).
//
// Variant / version map:
//   Drift has NO version variants in the source; its only knob is driftBits.
//   buffer(0) `version` is therefore REPURPOSED as driftBits.
//     version(=driftBits) 1  -> mask 0  -> every cell tested every frame
//     version(=driftBits) 2  -> mask 1  -> ~50% of cells tested per frame
//
// Parameters (from CallTree.md §2):
//   driftBits  range 1..2  default 1   (WinSky tree "CellDriftBits",
//              tree_demo.sky:1865)  -> carried on buffer(0) `version`.
//
// Metal fidelity divergence (CallTree.md §4):
//   1. GATHER port. The source's conditional non-write becomes an explicit
//      copy-through  outTex.write(inTex.read(gid), gid)  so the ping-pong pair
//      does not surface stale 2-frames-back data.
//   2. RNG: the single global libc Rand32 scan-order stream becomes a
//      per-thread integer hash of (gid, version). This changes WHICH cells are
//      tested (spatial set) but preserves the gate probability 1/(1<<(bits-1)).
//   3. RESOLVED (port): a per-frame `frame` uniform is now bound at buffer(1)
//      by CellNode.computeShader (folded into the gate hash seed below), so the
//      tested-cell mask re-randomises frame to frame. buffer(1) is bound for
//      driftKernel/noiseKernel only (CellNode binds it exclusively for the two
//      kernels that declare it — the melt unbound-buffer hazard does not apply).
//   4. VALUE: source writes r1 = lc+1 (16-bit low word +1) through NextR, which
//      yields a nonstandard middle byte; only plane .b is displayed. This port
//      uses r1 = (self+1)&0xff with the standard NextR inverse/counter so the
//      packing stays well-formed for the downstream colour stage.
//   5. Scaling convention: reads/writes use x255 (+0.5 round) / /255, matching
//      cell.rule.ave / cell.rule.slide.
// ============================================================================

static inline uint driftHashU(uint x)
{
    x ^= x >> 16; x *= 0x7feb352du;
    x ^= x >> 15; x *= 0x846ca68bu;
    x ^= x >> 16; return x;
}
static inline uint driftHash2(uint2 g, uint seed)
{
    return driftHashU(g.x * 73856093u ^ g.y * 19349663u ^ (seed * 2654435761u + 1u));
}

kernel void driftKernel
(
 texture2d<half, access::read>  inTex   [[ texture(0) ]],
 texture2d<half, access::write> outTex  [[ texture(1) ]],
 constant float&                version [[ buffer(0)  ]],   // REPURPOSED: driftBits 1..2 (default 1)
 constant float&                frame   [[ buffer(1)  ]],   // per-frame counter (CellNode-bound) — animates the gate mask
 uint2 gid [[thread_position_in_grid]])
{
    const uint  xs = outTex.get_width();
    const uint  ys = outTex.get_height();
    const uint2 ci(gid.x, gid.y);

    uint2 ni, si, ei, wi;   // n s e w toroidal indices (cardinal only)

    /** setup cardinal toroidal indices */ {
#define ew(ex,ey, wx,wy) ei=uint2(ex,ey); wi=uint2(wx,wy);
#define ns(nx,ny, sx,sy) ni=uint2(nx,ny); si=uint2(sx,sy);
        if (gid.x == 0) {
            ew(1, gid.y, xs-1, gid.y)
            if      (gid.y == 0)    { ns(0, ys-1,    0, 1      ) }
            else if (gid.y == ys-1) { ns(0, ys-2,    0, 0      ) }
            else                    { ns(0, gid.y-1, 0, gid.y+1) }
        } else if (gid.x == xs-1) {
            ew(0, gid.y, xs-2, gid.y)
            if      (gid.y == 0)    { ns(xs-1, ys-1,    xs-1, 1      ) }
            else if (gid.y == ys-1) { ns(xs-1, ys-2,    xs-1, 0      ) }
            else                    { ns(xs-1, gid.y-1, xs-1, gid.y+1) }
        } else {
            ew(gid.x+1, gid.y, gid.x-1, gid.y)
            if      (gid.y == 0)    { ns(gid.x, ys-1,    gid.x, 1      ) }
            else if (gid.y == ys-1) { ns(gid.x, ys-2,    gid.x, 0      ) }
            else                    { ns(gid.x, gid.y-1, gid.x, gid.y+1) }
        }
    }

    const half4 C = inTex.read(ci);

    {{ // cell.rule.drift

    // --- random gate: (Rand32 & mask)==0  ->  per-thread integer hash ---
    uint bits = uint(max(version, 1.0));      // driftBits, clamp >= 1
    uint mask = (1u << (bits - 1u)) - 1u;      // bits 1 -> 0 (always), bits 2 -> 1 (~50%)
    uint h    = driftHash2(gid, uint(max(version, 0.0)) + uint(max(frame, 0.0)) * 65537u);
    if ((h & mask) != 0u) {                    // gate FALSE -> copy-through (divergence #1)
        outTex.write(C, ci);
        return;
    }

    const uint self = uint(C.b * 255. + 0.5);
    const uint nB   = uint(inTex.read(ni).b * 255. + 0.5);
    const uint eB   = uint(inTex.read(ei).b * 255. + 0.5);
    const uint sB   = uint(inTex.read(si).b * 255. + 0.5);
    const uint wB   = uint(inTex.read(wi).b * 255. + 0.5);

    // 2-bit border-colour histogram of the four cardinal neighbours
    uint cm = self & 3u;            // c   & 3
    uint cp = (self + 1u) & 3u;     // (c+1) & 3   (always != cm)
    uint cand[4] = { 0u, 0u, 0u, 0u };
    cand[nB & 3u]++;
    cand[eB & 3u]++;
    cand[sB & 3u]++;
    cand[wB & 3u]++;

    if (cand[cp] + cand[cm] == 4u) {           // all neighbours within one colour -> drift
        const uint HiC = (uint(C.a * 255. + 0.5) << 8) + uint(C.r * 255. + 0.5);
        uint r1 = (self + 1u) & 0xffu;         // divergence #4: byte+1 (was lc+1)
        uint r2 = 255u - r1;
        uint r3 = HiC + (r1 & 3u);
        float fa = float((r3 >> 8) & 0xffu) / 255.;
        float fr = float( r3       & 0xffu) / 255.;
        float fg = float(r2) / 255.;
        float fb = float(r1) / 255.;
        outTex.write(half4(fr, fg, fb, fa), ci);
    } else {
        outTex.write(C, ci);                   // *next = c  (identity copy)
    }
    }}
}
