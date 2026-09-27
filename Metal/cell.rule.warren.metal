#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

// ============================================================================
// cell.rule.warren.metal  —  warrenKernel
// ----------------------------------------------------------------------------
// Source of truth : WinSky  pixel/Rule.cpp:723-825  (Rule::warren)
//                   distance LUTs XNW/XNE/XSE/XSW  Rule.cpp:726-729
//                   Xnw/Xne/Xse/Xsw macros          Rule.cpp:731-734
//                   neighbour macros                pixel/Univ_def.h
//   FromCell enum   pixel/Rule.h:41-49  (FromNw=1,FromSw,FromNe,FromSe)
//
// Variant / version map (selected by buffer(0) `version` == warrenVersion):
//   v1 (version 1, DEFAULT) : single-pass gather. For each cell it picks a
//     value from the diagonal neighbours by comparing their low bytes and a
//     per-neighbour "squared distance" pulled from a static LUT indexed by the
//     neighbour's HiC low nibble. Writes  *next = r1 + (r2<<16)  where r2 is a
//     4-bit "which diagonal won" flag  (NOT the HiC counter).
//   v0 (version 0)          : value-band shear sort (below). Byte-multiset of
//     the texture is invariant frame-to-frame (a permutation each frame); bytes
//     sort into solid vertical bands, minima west.
//   v2 (version in [1.5,2.5)) : BAND-ORDER Batcher merge-exchange sorting network
//     (Knuth TAOCP 5.2.2 Algorithm M). TARGET = BAND ORDER: linear index
//     i = x*H + ((x&1)==0 ? y : H-1-y) -- column-major, columns alternating
//     direction so the sorted sequence is continuous across columns; every value
//     in column x <= column x+1 -> straight vertical band boundaries. Merge
//     exchange sorts N=W*H elements in t(t+1)/2 substages, t=ceil(log2 N) (171
//     for 2^18=512x512), ONE SUBSTAGE PER FRAME -- O(log^2 N) frames, beating the
//     O(side) nearest-neighbour exchange. All comparators ascending (min ends at
//     the lower band-order index) -> idempotent: sorted data fires no comparator
//     at any substage, so cycling the schedule forever is a static fixed point;
//     any perturbation re-sorts within one full cycle (~171 frames). Handles
//     non-power-of-two N natively (out-of-range partners pass through).
//     Deterministic network, no spin.
//   v3 (version in [2.5,3.5)) : local exchanger with spin -- BAND-ORDER target,
//     2-frame schedule (axis alternates every frame, pair offset flips every 2
//     frames; all four comparator classes per 4 frames). Nearest-neighbour
//     compare-exchange contrast variant to the v2 network.
//   v4 (version in [3.5,4.5)) : tetrahedral 3-sort over a complete shear backbone
//     (candL3 lineage). 6-PHASE schedule phase=counter%6 : 0=H distance-1 odd-even
//     par0 (min-west), 1=V distance-1 odd-even par0 (band-order, even col min-north),
//     2=H distance-1 odd-even par1, 3=V distance-1 odd-even par1, 4=main-diagonal
//     triangle 3-sort triA shift{0,0}, 5=main-diagonal triangle 3-sort triB
//     shift{1,1}. The triangle 3-sort writes band-rank-sorted values to a 2x2 tile's
//     three vertices across its MAIN diagonal (anti-diagonal forbidden: it fires at
//     band order). candL3's joint 3-sort alone is Margolus-class incomplete and
//     plateaus on residual oscillators (endMism 473/5219/5392 with only distance-2
//     support); the four distance-1 odd-even phases supply a COMPLETE mesh shear
//     network (both parities, both axes) that guarantees convergence, while the two
//     3-sort phases add main-diagonal transport that accelerates it. Every phase is
//     a permutation and quiescent at band order (value monotonic in band rank ->
//     3-sort no-op; rows increase west->east and band columns parity-monotone ->
//     odd-even min/max no-op) so exact band order is a fixed point. NOT v3:
//     plain tie-stable min/max with NO spin word, triangle 3-sort comparator, 6-phase
//     schedule (v3 = pairwise decideSwap spin hysteresis on a 2-frame axis-alternating
//     schedule). Fixed-point clean on the spiral seed at 2308/2490/2556 frames
//     (r/g/b) with zero end-mismatch.
//   v5 (version >= 4.5)      : Ising mutual-best compare-exchange (candL4 lineage)
//     on a DUAL/SINGLE interleaved schedule. Each cell takes its MAX-inversion
//     admissible band-order edge (argmax, priority W>E>N>S on ties) and swaps iff that
//     edge is the partner's best too (MUTUAL -> disjoint matching -> conservative
//     permutation). Schedule by the broadcast (0,0) counter: EVEN frame argmax over
//     all four edges {W,E,N,S} (dual axis); ODD frame argmax over one axis pair,
//     (counter>>1)&1 selecting H then V (single axis). candL4's bare single-axis-
//     alternating rule is deadlock-free but its per-frame swap constant is too small:
//     it fully sorts at 256 yet plateaus at 512 (b endMism 58475 @4096, O(side) with a
//     ~2x shortfall). The dual frame roughly doubles throughput (both axes matched in
//     one step); a bare dual-axis rule instead seats a residual 2-cycle (plateaus at
//     256, endMism 302), so the interleaved single-axis frame -- 1D mutual-best, which
//     strictly reduces inversions along its line -- always breaks it. Measured fixed
//     point ~1934-2425 frames at 512 across seeds, clean ~2x-per-side scaling, no limit
//     cycle at any tested size. No spin/refractory word (HiC memory unused off (0,0)).
//     Reads within 2 texels (partner dist 1, its edges dist 2). Distinct from v3
//     (spin decideSwap, 2-frame odd-even) and v4 (3-sort + odd-even + distance-2):
//     v5 alone is mutual-best matching, no comparator parity.
//   v6 (version in [5.5,6.5)) : octahedral min(left)/max(right) Margolus block with a
//     gated anti-diagonal (candO1 lineage). 6-phase schedule: phases 0/3 sort a
//     Margolus 2x2 block on the two octahedral sublattices (even{(2i,2j)} /
//     odd{(2i+1,2j+1)}), phases 1/2/4/5 are H/V odd-even finishers. The block picks at
//     most one diagonal leg: main (NW-SE) ungated -- fires when the lower-band-rank
//     vertex holds the larger tieKey (payload, then band position); anti (NE-SW) gated
//     -- fires only when swapping strictly raises the block's match-count against the
//     local band-order ideal (so anti stays quiescent at band order). Main/anti
//     contention is resolved by fixed priority: min-left over {NW,SW} vs max-right over
//     {NE,SE} by tieKey (value, then band position). History-resistance was measured
//     unreachable in this rule class and removed. Every phase is a permutation
//     (block-local swap set, odd-even disjoint pairs) so payload histogram holds; exact
//     band order fires zero comparators -> fixed point. Reads <= 2 texels. Race fixed
//     point r/g/b = 2986/3082/3073 frames on the zigular seed, conservative, endMism 0.
//     Distinct from v5 (edge argmax matching, no block) and v4 (triangle 3-sort, no gating).
//   v7 (version >= 6.5)      : pairwise mutual diagonal (candO2 lineage). Same 6-phase
//     skeleton (phases 0/3 diagonal at offset0/offset1, 1/2/4/5 H/V finishers) but no
//     block partition: each interior cell has one main and one anti diagonal partner and
//     a diagonal edge commits iff both endpoints prefer it (mutual selection -> disjoint
//     matching -> conservation). preferOf resolves a per-cell dual claim (cell prefers
//     both diagonals) by the same fixed priority -- min-left/max-right tieKey bias (value,
//     then band position) -- applied identically at both endpoints so the match is
//     symmetric. Octahedral min(left)/max(right) and gated anti-diagonal as in v6, but
//     matched per-edge rather than per-block. History-resistance was measured unreachable
//     in this rule class and removed. Race fixed point r/g/b = 3154/3082/3085 frames on
//     the zigular seed, conservative, endMism 0. Distinct from v6 (whole-block leg
//     choice) and v5 (H/V argmax, no diagonal).
//   v8 (version in [7.5,8.5)) : flight->measurement gas, rectangular axis lanes, on a single
//     packed plane. The four gas lanes ride the one half4 (channel i = lane i, 0 empty /
//     value+1 occupied), so presence folds into the value encoding and the whole protocol
//     runs live in this branch. candS8_inv below is the matching inverse flight. Target = band
//     order; route is the local mutual-best band exchange.
//   v9 (version in [8.5,9.5)) : flight->measurement gas, polar diagonal lanes, same packed
//     plane. Target = ring order; route is a raster merge-exchange followed by one gather
//     frame keyed on the pkRingRank arithmetic — no rank texture, fully self-contained.
//     candS9_inv is the matching inverse flight.
//   v10 (version in [9.5,10.5)) : perpetual pair-form sort, straight-band target. No
//     phases and no end state: the app may paint into the plane on any frame, so every
//     frame runs the same two local rules over one grid pairing -- a pixel holding two
//     occupants drains one into an adjacent empty, and neighbouring pixels swap when
//     they are out of band order. The pair form is written every frame. The flight,
//     fold, close and route this row shipped with are gone, and so is the reversal
//     claim for it: there is no flight window left to invert.
//   v11 (version >= 10.5)    : the same perpetual frame with the circular ring target,
//     kept exactly as shipped -- euclidean ring bucket, angular sector, integer cross
//     product, linear index. Its pass cycle carries both diagonals for the ring-to-ring
//     seam. A circle drawn on a rectangle puts order-neighbours far apart, so this row
//     does not reach its exact target: it settles into a calm fixed point a measured
//     distance short of it, holds there, and wakes on the next frame when painted on.
//     Both rows: see the ROWS 10/11 section below for the comparators, the pass cycle,
//     the residual matrix and the wake matrix.
//
//   What a doubly occupied pixel shows. The pair form is on screen every frame now, so
//     the colour stage reads it from the first frame on: an empty pixel is black, a
//     singly occupied one its palette colour, a doubly occupied one the clamped sum of
//     its two palette colours. The lane form no longer reaches these rows at all -- it
//     is a rows 8/9 form now.
//
//   flight then measurement, in plain terms (the packed v8/v9 protocol). A value does not just
//     sit in a pixel: it is launched in a direction and travels, and that launch direction is
//     its spin -- spin is the lane and steers where the value flows. Phase one is flight: for
//     the first (W+H)/2 frames the board runs the reversible four-lane gas, several values may
//     share one cell at once (a superposition riding different lanes), nothing resists, and
//     running the inverse rule the same number of frames returns the exact starting board byte
//     for byte. Phase two is measurement: once the counter passes the flight window the rule
//     turns irreversible, first draining every cell back to one value (local 2x2 balancing plus
//     a directed current), then routing those single values into the target arrangement (band
//     order for v8, ring order for v9). Collapse -- one value per pixel, mismatch zero -- is a
//     fixed point the measurement rule holds: at target order nothing fires and the counter
//     keeps advancing over a settled board. The board is a torus. Flight reads stay within two
//     texels, but measurement reads deliberately reach long range -- multiscale drain strides
//     and the ring-rank route partner are grid-distant -- because collapse is the non-local act,
//     exactly as in the physics; locality is a flight property, not a measurement one.
//     Pixel (0,0) carries the broadcast counter in its .x/.w channels (the HiC convention), so
//     it forfeits lane slots 0 and 3 there; it is frozen and skipped on every flight ring
//     (keeping the flight a lossless bijection) and drains/routes on its two remaining lanes.
//
//   SLIT-SCAN LIGHT MODEL. Read the frame sequence as a slit-scan of light through
//     an imaginary N-cubed volume: each frame is a depth slice, the top slice the
//     unsorted seed and the bottom slice the fully band-sorted plane, every
//     intermediate frame one slice deeper toward order. Locality is the aperture:
//     no rule reads beyond PROXIMITY <= 2 texels, so a value migrates at most two
//     texels per slice and the sorted image resolves as the scan descends rather
//     than snapping. v4/v5 differ only in how each slice's aperture is scheduled.
//   WHY BAND ORDER, NOT DOUBLY-MONOTONE. A doubly-monotone target (sorted along
//     BOTH axes) is NOT a fixed point of straight-band + column comparators: its
//     band boundaries staircase (value in column x can exceed a value in column
//     x+1 on a lower row), so min-west horizontal comparators keep firing and the
//     state never settles. Band order fixes that fixed point: bands are STRAIGHT,
//     so horizontals are silent, and each column is internally monotone in its
//     band-order direction, so verticals are silent.
//   Selection: version < 0.5 -> v0 (early return); otherwise v1.
//
// Parameters (from CallTree.md §2):
//   warrenVersion  range 0..1  default 1  (WinSky "CellWarrenVersion",
//                  tree_demo.sky:1909)  -> carried on buffer(0) `version`.
//   reseed         range 0..1  default 0  -> carried on buffer(1) `reseed`, the next
//                  free index; rows 10/11 entry pulse only (see dblReseed).
//   (cell.warren.shift tree leaf exists but has NO code consumer — dead, dropped.)
//
// V0 IMPLEMENTATION — value-band shear sort (replaces the conservation move):
//   SORTING MODEL. Value plane = .b low byte. Each frame permutes the byte
//   multiset, so the histogram is invariant frame-to-frame (conservation by
//   permutation — every cell either keeps its byte or swaps it with an adjacent
//   partner). The rule sorts bytes into solid VERTICAL bands: minima WEST,
//   ascending west->east; each column converges to one rank block. Fixed point =
//   a frame that moves nothing (a column-major monotone matrix).
//
//   WHY NOT A MARGOLUS 2x2 BLOCK SORT. A 2x2-block (Margolus-partition) compare
//   sort is not a complete sorting network: its fixed points are matrices
//   monotone in BOTH axes, of which column-major bands are one member but
//   generically unreachable — it stalls on some other monotone matrix (measured
//   on the race harness: idealMismatch ~0.95, intraVar >> 0 on high-entropy
//   channels). The band goal requires a COMPLETE network. Margolus rejected.
//
//   MESH SHEAR SORT. Alternate a complete VERTICAL odd-even transposition sort
//   (band-order columns: even columns minima-north, odd columns minima-south)
//   with a complete HORIZONTAL odd-even sort (minima-west). Each pass is a set
//   of DISJOINT adjacent compare-exchanges min(a,b)/max(a,b) — a permutation, so
//   the multiset is invariant. The alternation converges to column-major bands.
//
//   PARITY / PHASE — the (0,0) broadcast word. A 16-bit frame counter lives in
//   pixel (0,0) HiC ((.a<<8)+.r); every cell reads it (broadcast). stage =
//   (counter/xs)&1 selects vertical(0) vs horizontal(1); par = counter&1 is the
//   odd/even comparator-pair offset. Pixel (0,0) is the sole writer: it emits
//   counter+1; every other cell writes HiC 0. HiC use is v0-scoped; the v1 HiC
//   winner-flag contract is untouched.
//
//   SPIN / STABILITY. min/max compare-exchange leaves equal-valued pairs
//   unchanged, so equal bytes never churn — the stability role once framed as
//   "spin" (tie history resisting return) is met structurally by tie-stable
//   comparators; no per-pixel spin memory is stored.
//
//   BAND ORIENTATION. Minima west, maxima east; ascending along +x. The vertical
//   band-order pass carries the north/south ordering that feeds each horizontal pass.
//
//   EDGE / PASS-THROUGH. A cell with no in-grid comparator partner this pass
//   passes its own byte through unchanged (bounds-guarded), so partial edge
//   rows/columns are conserved.
//
//   EVOLUTION. octant router (original WinSky warren) -> conservation particle
//   move (empty-pull permutation) -> value-band shear sort (this v0). Each step
//   held the byte-multiset invariant; the last adds monotone band convergence.
//   Write: packCell(val, hic) -> half4(hic&0xff, 0, val, (hic>>8)&0xff) /255.
//
// Metal fidelity divergence (CallTree.md §4):
//   1. v1 write BYPASSES NextR. High word = 4-bit winner flag r2, low word = r1.
//      Packing: .b = r1, .g = 0 (bits 8-15 unused), (.a<<8)+.r = HiC = r2.
//      Do NOT route this through the generic HiC self-counter.
//   2. The v1 "right" block is ported LITERALLY, preserving the source's
//      if / if-else control-flow quirk (Rule.cpp:800-802 uses `if` then
//      `if..else`, not `if..elif..else`): net effect neB>seB -> (seB,Xse),
//      else -> (neB, min(Xne,Xse)).
//   3. Xnw/Xne/Xse/Xsw index the LUT by the diagonal neighbour's HiC low nibble
//      (hnw&0xf ...), i.e. last frame's winner flag — intended feedback.
//   4. Scaling convention: reads x255 (+0.5 round) / writes /255.
// ============================================================================

// ---- v0 shear-sort helpers (pure reads over inTex snapshot) ----

// low byte of a texel (value plane); read x255 (+0.5 round) convention
static inline int cellByte(texture2d<half, access::read> tex, uint2 q)
{
    return int(uint(tex.read(q).b * 255. + 0.5));
}

// HiC of a texel: (.a<<8)+.r, established packing convention
static inline uint cellHiC(texture2d<half, access::read> tex, uint2 q)
{
    half4 c = tex.read(q);
    return (uint(c.a * 255. + 0.5) << 8) + uint(c.r * 255. + 0.5);
}

// pack value plane + HiC into half4(fr,0,fb,fa) using write /255. convention
static inline half4 packCell(int val, uint hic)
{
    float fb = float(uint(val) & 0xffu) / 255.;
    float fr = float(hic & 0xffu) / 255.;
    float fa = float((hic >> 8) & 0xffu) / 255.;
    return half4(fr, 0.0, fb, fa);
}

// band-order linear rank r(x,y)=x*H+((x&1)==0 ? y : H-1-y) (column-major snake)
static inline uint bandRank(uint x, uint y, uint H)
{
    return x * H + (((x & 1u) == 0u) ? y : (H - 1u - y));
}

// ---- v3 spin helpers (spin word packed in HiC bits ABOVE bit0) ----
// spin word layout: bit1 valid, bit2 axis(0=x/main-diag 1=y/anti-diag), bit3 dir(0=neg/low-end 1=pos/high-end)
static inline uint packSpin(bool valid, uint axis, uint dir)
{
    return (uint(valid) << 1) | ((axis & 1u) << 2) | ((dir & 1u) << 3);
}

// read a cell's spin word; (0,0) carries the broadcast counter -> no spin
static inline uint readSpinWord(texture2d<half, access::read> tex, uint2 q)
{
    if (q.x == 0u && q.y == 0u) return 0u;
    return cellHiC(tex, q);
}

// pairwise swap decision: min ends at the "low" cell; symmetric pure function.
// spin DEMOTES an immediate reversal (value returning whence it came on this axis)
// unless the inversion magnitude exceeds resist; strict inequality only.
static inline bool decideSwap(int valLow, int valHigh, uint spinLow, uint spinHigh, uint axis, int resist)
{
    if (valLow <= valHigh) return false;                                // ordered -> no fire
    const int mag = valLow - valHigh;                                   // inversion magnitude
    const bool revHigh = ((spinHigh >> 1) & 1u) && (((spinHigh >> 2) & 1u) == axis) && (((spinHigh >> 3) & 1u) == 1u);
    const bool revLow  = ((spinLow  >> 1) & 1u) && (((spinLow  >> 2) & 1u) == axis) && (((spinLow  >> 3) & 1u) == 0u);
    if ((revHigh || revLow) && mag <= resist) return false;             // demote reversal below threshold
    return true;
}

// ---- v5 Ising mutual-best helpers (candL4): 4-edge argmax over band-order target ----
// dir codes: 0=W 1=E 2=N 3=S ; band-order = min-west horizontals, even-col min-north.
// inversion magnitude of the edge from (cx,cy) toward direction d (0 if OOB / ordered)
static inline int edgeMag(texture2d<half, access::read> tex, int cx, int cy, int W, int H, int selfV, int d)
{
    const bool asc = ((cx & 1) == 0);          // even column min-north
    if (d == 0) {                              // West neighbour: west should be min
        if (cx - 1 < 0) return 0;
        int w = cellByte(tex, uint2(uint(cx-1), uint(cy)));
        return (w > selfV) ? (w - selfV) : 0;
    } else if (d == 1) {                        // East: self(west) should be min
        if (cx + 1 >= W) return 0;
        int e = cellByte(tex, uint2(uint(cx+1), uint(cy)));
        return (selfV > e) ? (selfV - e) : 0;
    } else if (d == 2) {                        // North neighbour
        if (cy - 1 < 0) return 0;
        int n = cellByte(tex, uint2(uint(cx), uint(cy-1)));
        return asc ? ((n > selfV) ? (n - selfV) : 0)   // north should be min
                   : ((n < selfV) ? (selfV - n) : 0);  // north should be max
    } else {                                    // South neighbour
        if (cy + 1 >= H) return 0;
        int s = cellByte(tex, uint2(uint(cx), uint(cy+1)));
        return asc ? ((selfV > s) ? (selfV - s) : 0)   // south should be max
                   : ((s > selfV) ? (s - selfV) : 0);  // south should be min
    }
}

// argmax edge of a cell over an EDGE SET selected by `axis`:
//   axis 0 -> horizontal pair {W,E}; axis 1 -> vertical pair {N,S};
//   axis < 0 -> all four {W,E,N,S} (dual-axis frame).
// -> best direction (-1 none) and its magnitude. Priority W>E>N>S via strict '>'.
// Single-axis restriction is deadlock-free 1D mutual-best; the dual-axis frame
// raises throughput but can seat a residual 2-cycle, which the interleaved
// single-axis frame always breaks (1D mutual-best strictly reduces inversions).
static inline int bestEdge(texture2d<half, access::read> tex, int cx, int cy, int W, int H, int axis, thread int& bestMag)
{
    int selfV = cellByte(tex, uint2(uint(cx), uint(cy)));
    int bd = -1; bestMag = 0;
    const int d0 = (axis < 0) ? 0 : ((axis == 0) ? 0 : 2);   // start dir
    const int nd = (axis < 0) ? 4 : 2;                        // edge count
    for (int k = 0; k < nd; k++) {             // priority low-dir first via strict '>'
        const int d = d0 + k;
        int m = edgeMag(tex, cx, cy, W, H, selfV, d);
        if (m > bestMag) { bestMag = m; bd = d; }
    }
    return bd;
}

static inline int2 dirDelta(int d)
{
    if (d == 0) return int2(-1, 0);
    if (d == 1) return int2( 1, 0);
    if (d == 2) return int2( 0,-1);
    return int2(0, 1);
}

// ---- v6/v7 octahedral min-left/max-right helpers (candO1/candO2 lineage) ----
// Strict total order (payload, band-order-independent linear index) breaks ties.
static inline bool warrenTieGreater(int va, uint ia, int vb, uint ib)
{
    return (va > vb) || (va == vb && ia > ib);
}

// band-order edge violation: the lower-rank endpoint holds the strictly larger
// tieKey (should hold the smaller). Quiescent at band order for both diagonals.
// Tie key = bandRank (column-major, parity-corrected) so an equal-value anti pair
// in exact band order fires ZERO comparators (the lower bandRank never tests
// greater than the higher). Row-major (cy*W+cx) tie keys disagreed with the
// column-major bandRank across anti-diagonal pairs -> equal-value churn.
static inline bool edgeInverted(int va, uint ra, int vb, uint rb)
{
    if (ra < rb) return warrenTieGreater(va, ra, vb, rb);
    return warrenTieGreater(vb, rb, va, ra);
}

// v7 (candO2) per-cell preference over its incident diagonals: 0 none, 1 main, 2 anti
static inline uint preferOf(texture2d<half, access::read> tex,
                            int cx, int cy, int W, int H, uint offset)
{
    const uint HU = uint(H);
    const int  selfV = cellByte(tex, uint2(uint(cx), uint(cy)));
    const uint selfR = bandRank(uint(cx), uint(cy), HU);

    const bool low  = (((cx + int(offset)) & 1) == 0);        // low member (reaches east)
    const int  mpx = low ? cx + 1 : cx - 1, mpy = low ? cy + 1 : cy - 1;   // MAIN partner (SE / NW)
    const int  apx = low ? cx + 1 : cx - 1, apy = low ? cy - 1 : cy + 1;   // ANTI partner (NE / SW)

    bool mainFire = false, antiFire = false;
    if (mpx >= 0 && mpy >= 0 && mpx < W && mpy < H) {
        int mv = cellByte(tex, uint2(uint(mpx), uint(mpy)));
        uint mr = bandRank(uint(mpx), uint(mpy), HU);
        mainFire = edgeInverted(selfV, selfR, mv, mr);
    }
    if (apx >= 0 && apy >= 0 && apx < W && apy < H) {
        int av = cellByte(tex, uint2(uint(apx), uint(apy)));
        uint ar = bandRank(uint(apx), uint(apy), HU);
        antiFire = edgeInverted(selfV, selfR, av, ar);
    }

    if (mainFire && !antiFire) return 1u;
    if (!mainFire && antiFire) return 2u;
    if (!mainFire && !antiFire) return 0u;

    // dual claim -> fixed-priority resolution: minLeft over {NW,SW}, maxRight over
    // {NE,SE}; bias by tieKey = bandRank (column-major, parity-corrected) everywhere.
    bool haveL = false; int mlV = 0; uint mlR = 0;
    bool haveR = false; int mrV = 0; uint mrR = 0;
    if (cx - 1 >= 0 && cy - 1 >= 0) { int v = cellByte(tex, uint2(uint(cx-1),uint(cy-1))); uint r = bandRank(uint(cx-1),uint(cy-1),HU); if (!haveL || warrenTieGreater(mlV,mlR,v,r)) { mlV=v; mlR=r; haveL=true; } }
    if (cx - 1 >= 0 && cy + 1 <  H) { int v = cellByte(tex, uint2(uint(cx-1),uint(cy+1))); uint r = bandRank(uint(cx-1),uint(cy+1),HU); if (!haveL || warrenTieGreater(mlV,mlR,v,r)) { mlV=v; mlR=r; haveL=true; } }
    if (cx + 1 <  W && cy - 1 >= 0) { int v = cellByte(tex, uint2(uint(cx+1),uint(cy-1))); uint r = bandRank(uint(cx+1),uint(cy-1),HU); if (!haveR || warrenTieGreater(v,r,mrV,mrR)) { mrV=v; mrR=r; haveR=true; } }
    if (cx + 1 <  W && cy + 1 <  H) { int v = cellByte(tex, uint2(uint(cx+1),uint(cy+1))); uint r = bandRank(uint(cx+1),uint(cy+1),HU); if (!haveR || warrenTieGreater(v,r,mrV,mrR)) { mrV=v; mrR=r; haveR=true; } }
    if (!haveL) { mlV = selfV; mlR = selfR; }
    if (!haveR) { mrV = selfV; mrR = selfR; }
    return warrenTieGreater(mrV, mrR, mlV, mlR) ? 1u : 2u;    // tieKey(minLeft)<tieKey(maxRight)->MAIN
}

// ============================================================================
// packed single-plane gas (v8/v9). One half4 carries four lanes: channel i holds
// lane i as 0 (empty) or value+1 in 1..256 (occupied), so presence folds into the
// value encoding and no separate presence plane is needed. Pixel (0,0) forfeits
// lane slots 0 (.x) and 3 (.w) to the broadcast counter (lo=.x, hi=.w, matching the
// v0-v7 HiC=(.a<<8)+.r convention); (0,0) is frozen and isolated on every flight
// ring (all four lanes double-hop over it) so the forfeit never costs a token and
// the flight stays a lossless bijection. Its single token (pre-placed at its target
// value by the harness) rides lane 1 (.y). variant 0 = candS8 axis lanes
// (0 N,1 E,2 S,3 W), variant 1 = candS9 diagonal lanes (0 NE,1 NW,2 SE,3 SW).
//
// STORAGE FORM. The two variants store the same lane structure through different
// codes, so the packing helpers below are forked by a PkForm carried per call.
//   raw form (v8) -- the original codes: the slot number 0..256 written straight
//     into the channel, counter bytes written straight into (0,0).x/.w. v8 is left
//     exactly as it was, byte for byte, so every raw-form branch below repeats the
//     original expression verbatim rather than scaling by one.
//   scaled form (v9) -- v9 is looked at, so no channel may leave [0,1]. A lane
//     stores enc(raw) = raw / pkScale with pkScale = 512, and the (0,0) counter
//     bytes take the /255 convention the rest of this file already uses.
//   display form (v9 route and hold) -- once the ring order is reached the plane
//     is a finished picture, so it is stored the way rows 0-7 store theirs:
//     packCell(value, hic), value in .b over 255, the other channels zero.
//
// WHY 512. Every raw value 0..256 is a whole number below 2^11, so it sits exactly
// in the 11-bit significand of a half. Dividing by 512 = 2^9 only lowers the
// exponent -- no significand bit moves -- and the smallest nonzero code 2^-9 stays
// far above the smallest normal half, so nothing falls into the denormal range.
// The encode is therefore exact, the decode multiply by 512 is exact in float, and
// round-to-nearest returns every one of the 257 raw values with residual zero
// (checked by a cpu sweep of the whole range before this was written). Neighbouring
// codes are 2^-9 apart while the largest half step over the used range [0, 0.5] is
// 2^-11, so the decode carries four steps of slack. 257 would round trip too and
// would fill the range more brightly, but its encode is not exact (worst decode
// residual 0.0625), so the exact power of two is taken. Occupied lanes then tint
// their channel in proportion to the value they carry, over [1/512, 0.5]: the
// flight reads as dim coloured motion instead of saturated channels.
//
// FORM BY PHASE (v9). Flight and drain carry the scaled lane form, since several
// tokens may share a cell there. Route and the hold after it start from one token
// per cell, so they carry the display form. The boundary is the broadcast counter
// alone -- write display from the first route frame, read display from the frame
// after it -- so every cell agrees without extra state, and the reverse mode, which
// is confined to the flight window, never meets it.
// ============================================================================

constant float pkScale = 512.0;              // v9 lane code scale, an exact power of two

struct PkLanes { int v[4]; int p[4]; };

// which storage form a call reads or writes. sc = scaled lane codes, disp = display packing.
// The rows 10/11 pair form is not in this set: those rows carry one form for every frame
// and read it through dblRead alone.
struct PkForm { bool sc; bool disp; };
static inline PkForm pkFormRaw()             { PkForm f; f.sc = false; f.disp = false; return f; }
static inline PkForm pkFormScaled(bool disp) { PkForm f; f.sc = true;  f.disp = disp;  return f; }

static inline bool pkOrigin(int x, int y) { return x == 0 && y == 0; }
static inline bool pkForfeit(int x, int y, int lane) { return pkOrigin(x, y) && (lane == 0 || lane == 3); }

// lane form decode; forfeited (0,0) lanes read as empty (they hold the counter)
static inline PkLanes pkReadLanes(texture2d<half, access::read> t, int x, int y, PkForm f)
{
    half4 c = t.read(uint2(uint(x), uint(y)));
    int e[4];
    if (f.sc) {
        e[0] = int(float(c.x) * pkScale + 0.5); e[1] = int(float(c.y) * pkScale + 0.5);
        e[2] = int(float(c.z) * pkScale + 0.5); e[3] = int(float(c.w) * pkScale + 0.5);
    } else {
        e[0] = int(float(c.x) + 0.5); e[1] = int(float(c.y) + 0.5);
        e[2] = int(float(c.z) + 0.5); e[3] = int(float(c.w) + 0.5);
    }
    PkLanes L;
    for (int i = 0; i < 4; i++) {
        if (pkForfeit(x, y, i) || e[i] <= 0) { L.p[i] = 0; L.v[i] = 0; }
        else                                 { L.p[i] = 1; L.v[i] = e[i] - 1; }
    }
    return L;
}

// display form decode: one token in .b at the /255 byte scale, occupancy always 1.
// (0,0) is no exception -- its counter rides .x/.w, its token .b.
static inline PkLanes pkReadDisp(texture2d<half, access::read> t, int x, int y)
{
    half4 c = t.read(uint2(uint(x), uint(y)));
    PkLanes L;
    for (int i = 0; i < 4; i++) { L.v[i] = 0; L.p[i] = 0; }
    L.v[2] = int(float(c.z) * 255. + 0.5);
    L.p[2] = 1;
    return L;
}

// decode a texel into lanes under the form the caller is in
static inline PkLanes pkRead(texture2d<half, access::read> t, int x, int y, PkForm f)
{
    return f.disp ? pkReadDisp(t, x, y) : pkReadLanes(t, x, y, f);
}

// broadcast frame counter from (0,0): lo in .x, hi in .w. The scaled form puts the
// two bytes on the /255 convention, so the counter decodes without knowing the phase.
static inline int pkCounter(texture2d<half, access::read> t, bool sc)
{
    half4 c = t.read(uint2(0, 0));
    if (sc) return int(float(c.x) * 255. + 0.5) + int(float(c.w) * 255. + 0.5) * 256;
    return int(float(c.x) + 0.5) + int(float(c.w) + 0.5) * 256;
}

// encode lanes back to a texel; at (0,0) the two forfeited slots carry the counter
static inline void pkWrite(texture2d<half, access::write> o, uint2 gid,
                           thread const PkLanes& L, int cLo, int cHi, PkForm f)
{
    const bool org = pkOrigin(int(gid.x), int(gid.y));
    if (f.disp) {                                        // finished picture, packed like rows 0-7
        int val = 0;
        for (int i = 0; i < 4; i++) if (L.p[i]) { val = L.v[i]; break; }
        const uint hic = org ? ((uint(cHi) << 8) | uint(cLo)) : 0u;
        o.write(packCell(val, hic), gid);
        return;
    }
    float e[4];
    if (f.sc) {
        for (int i = 0; i < 4; i++) e[i] = L.p[i] ? float((L.v[i] & 0xff) + 1) / pkScale : 0.0;
        if (org) { e[0] = float(cLo) / 255.; e[3] = float(cHi) / 255.; }
    } else {
        for (int i = 0; i < 4; i++) e[i] = L.p[i] ? float((L.v[i] & 0xff) + 1) : 0.0;
        if (org) { e[0] = float(cLo); e[3] = float(cHi); }
    }
    o.write(half4(half(e[0]), half(e[1]), half(e[2]), half(e[3])), gid);
}

static inline int pkOcc(thread const PkLanes& L)      { return L.p[0] + L.p[1] + L.p[2] + L.p[3]; }
static inline int pkLowOcc(thread const PkLanes& L)   { for (int i = 0; i < 4; i++) if (L.p[i]) return i; return -1; }

static inline void pkRotPlus(thread PkLanes& L)
{
    int tv[4], tp[4];
    for (int i = 0; i < 4; i++) { tv[i] = L.v[(i + 3) & 3]; tp[i] = L.p[(i + 3) & 3]; }
    for (int i = 0; i < 4; i++) { L.v[i] = tv[i]; L.p[i] = tp[i]; }
}
static inline void pkRotMinus(thread PkLanes& L)
{
    int tv[4], tp[4];
    for (int i = 0; i < 4; i++) { tv[i] = L.v[(i + 1) & 3]; tp[i] = L.p[(i + 1) & 3]; }
    for (int i = 0; i < 4; i++) { L.v[i] = tv[i]; L.p[i] = tp[i]; }
}
static inline bool pkTurn(int x, int y, int c) { return ((x + y + c) & 7) == 0; }

// forward flight source of lane at (x,y)
static inline int2 pkSrc(int variant, int lane, int x, int y, int W, int H)
{
    if (variant == 0) {
        if (lane == 0) return int2(x, (y + 1) % H);
        if (lane == 1) return int2((x - 1 + W) % W, y);
        if (lane == 2) return int2(x, (y - 1 + H) % H);
        return int2((x + 1) % W, y);
    }
    if (lane == 0) return int2((x - 1 + W) % W, (y + 1) % H);
    if (lane == 1) return int2((x + 1) % W, (y + 1) % H);
    if (lane == 2) return int2((x - 1 + W) % W, (y - 1 + H) % H);
    return int2((x + 1) % W, (y - 1 + H) % H);
}
// inverse flight: cell that read (x,y) as its lane source
static inline int2 pkInvSrc(int variant, int lane, int x, int y, int W, int H)
{
    if (variant == 0) {
        if (lane == 0) return int2(x, (y - 1 + H) % H);
        if (lane == 1) return int2((x + 1) % W, y);
        if (lane == 2) return int2(x, (y + 1) % H);
        return int2((x - 1 + W) % W, y);
    }
    if (lane == 0) return int2((x + 1) % W, (y - 1 + H) % H);
    if (lane == 1) return int2((x - 1 + W) % W, (y - 1 + H) % H);
    if (lane == 2) return int2((x + 1) % W, (y + 1) % H);
    return int2((x - 1 + W) % W, (y + 1) % H);
}

// forward flight: gather each lane from its source, skipping (0,0) on every ring, then
// rotate at turn cells. (0,0) is frozen (keeps its own kept lanes, never rotates).
static inline PkLanes pkFlight(texture2d<half, access::read> t, int variant, int x, int y, int W, int H, int c, PkForm f)
{
    PkLanes L;
    if (pkOrigin(x, y)) {
        L = pkReadLanes(t, x, y, f);
        return L;
    }
    for (int i = 0; i < 4; i++) { L.v[i] = 0; L.p[i] = 0; }
    for (int lane = 0; lane < 4; lane++) {
        int2 s = pkSrc(variant, lane, x, y, W, H);
        if (pkOrigin(s.x, s.y)) s = pkSrc(variant, lane, s.x, s.y, W, H);   // double-hop over (0,0)
        PkLanes S = pkReadLanes(t, s.x, s.y, f);
        L.v[lane] = S.v[lane]; L.p[lane] = S.p[lane];
    }
    if (pkTurn(x, y, c)) pkRotPlus(L);
    return L;
}

// inverse flight: undo rotation on each inverse-source cell, then gather
static inline PkLanes pkUnrot(texture2d<half, access::read> t, int nx, int ny, int c, PkForm f)
{
    PkLanes L = pkReadLanes(t, nx, ny, f);
    if (!pkOrigin(nx, ny) && pkTurn(nx, ny, c)) pkRotMinus(L);
    return L;
}
static inline PkLanes pkInvFlight(texture2d<half, access::read> t, int variant, int x, int y, int W, int H, int c, PkForm f)
{
    PkLanes L;
    if (pkOrigin(x, y)) {
        L = pkReadLanes(t, x, y, f);
        return L;
    }
    for (int i = 0; i < 4; i++) { L.v[i] = 0; L.p[i] = 0; }
    for (int lane = 0; lane < 4; lane++) {
        int2 cc = pkInvSrc(variant, lane, x, y, W, H);
        int2 os = pkSrc(variant, lane, 0, 0, W, H);                 // origin's own source for this lane
        if (x == os.x && y == os.y) cc = pkInvSrc(variant, lane, 0, 0, W, H);   // I am origin's source -> double-hop reader
        PkLanes U = pkUnrot(t, cc.x, cc.y, c, f);
        L.v[lane] = U.v[lane]; L.p[lane] = U.p[lane];
    }
    return L;
}

// ---- measurement: drain (occupancy -> 1) then route (sort to target). (0,0) is frozen and
// treated as an inert non-partner so its pre-placed target token never moves. ----

// number of usable lane slots at a cell (2 at (0,0): lanes 0,3 are counter, 4 elsewhere)
static inline int pkCap(int x, int y) { return pkOrigin(x, y) ? 2 : 4; }
// lowest empty usable lane at a cell (skips the (0,0) counter slots)
static inline int pkLowEmptyKept(int x, int y, thread const PkLanes& L)
{
    for (int i = 0; i < 4; i++) { if (pkForfeit(x, y, i)) continue; if (!L.p[i]) return i; }
    return -1;
}
// pack n tokens into a cell's usable lanes (fills lanes 1,2 at (0,0), lanes 0..3 elsewhere)
static inline PkLanes pkPack(int x, int y, thread const int* vals, int n)
{
    PkLanes Lo; for (int i = 0; i < 4; i++) { Lo.v[i] = 0; Lo.p[i] = 0; }
    int slot[4], ns = 0;
    for (int i = 0; i < 4; i++) if (!pkForfeit(x, y, i)) slot[ns++] = i;
    const int m = min(n, ns);
    for (int k = 0; k < m; k++) { Lo.v[slot[k]] = vals[k]; Lo.p[slot[k]] = 1; }
    return Lo;
}

// 2x2 averaging block at stride str; conservative repartition, capped to each member's usable lanes
// so (0,0) (2 usable lanes) never overflows. Shares stay agreed across the four block threads.
static inline PkLanes pkDrainBlock(texture2d<half, access::read> t, int x, int y, int W, int H, int offx, int offy, int str, PkForm f)
{
    const int gx = (x - offx + W) % W, gy = (y - offy + H) % H;
    const int colP = (gx / str) & 1, rowP = (gy / str) & 1;
    const int xP = (colP == 0) ? (x + str) % W : (x - str + W) % W;
    const int yP = (rowP == 0) ? (y + str) % H : (y - str + H) % H;
    const int lX = (colP == 0) ? x : xP, rX = (colP == 0) ? xP : x;
    const int tY = (rowP == 0) ? y : yP, bY = (rowP == 0) ? yP : y;
    const int bi = rowP * 2 + colP;
    int2 cell[4];
    cell[0] = int2(lX, tY); cell[1] = int2(rX, tY); cell[2] = int2(lX, bY); cell[3] = int2(rX, bY);
    int vals[16]; int nTok = 0;
    for (int q = 0; q < 4; q++) { PkLanes L = pkReadLanes(t, cell[q].x, cell[q].y, f); for (int l = 0; l < 4; l++) if (L.p[l]) vals[nTok++] = L.v[l]; }
    int cap[4]; for (int q = 0; q < 4; q++) cap[q] = pkCap(cell[q].x, cell[q].y);
    int share[4]; const int base = nTok >> 2, rem = nTok & 3;
    for (int q = 0; q < 4; q++) share[q] = base + (q < rem ? 1 : 0);
    for (int q = 0; q < 4; q++) if (share[q] > cap[q]) {          // spill overflow to members with room
        int ex = share[q] - cap[q]; share[q] = cap[q];
        for (int r = 0; r < 4 && ex > 0; r++) if (r != q) { int room = cap[r] - share[r]; int add = min(room, ex); share[r] += add; ex -= add; }
    }
    int start = 0;
    for (int i = 0; i < bi; i++) start += share[i];
    int mine[4]; for (int k = 0; k < share[bi]; k++) mine[k] = vals[start + k];
    return pkPack(x, y, mine, share[bi]);
}

// directed held-axis current: one token flows from the higher-occ upper seat to the lower seat
static inline PkLanes pkDrainDrift(texture2d<half, access::read> t, int x, int y, int W, int H, int stage, int par, PkForm f)
{
    PkLanes Ls = pkReadLanes(t, x, y, f);
    const int seat = (stage == 0) ? y : x;
    const bool lowMember = (((seat - par) & 1) == 0);
    const int delta = lowMember ? 1 : -1;
    int px = x, py = y;
    if (stage == 0) py = (y + delta + H) % H; else px = (x + delta + W) % W;
    PkLanes Lp = pkReadLanes(t, px, py, f);
    const int Os = pkOcc(Ls), Op = pkOcc(Lp);
    PkLanes Lo = Ls;
    if (lowMember) {                                               // receive iff donor has more and room exists
        if (Op > Os) { const int sl = pkLowOcc(Lp), el = pkLowEmptyKept(x, y, Ls); if (sl >= 0 && el >= 0) { Lo.v[el] = Lp.v[sl]; Lo.p[el] = 1; } }
    } else {
        if (Os > Op && pkOcc(Lp) < pkCap(px, py)) { const int dl = pkLowOcc(Ls); if (dl >= 0) { Lo.v[dl] = 0; Lo.p[dl] = 0; } }
    }
    return Lo;
}

static inline PkLanes pkDrainStep(texture2d<half, access::read> t, int x, int y, int W, int H, int m, PkForm f)
{
    const int ph = m % 3;
    if (ph == 0) return pkDrainBlock(t, x, y, W, H, (m / 3) & 1, ((m / 3) >> 1) & 1, 1, f);
    if (ph == 1) { const int e = m / 3; const int s = 2 << ((e >> 2) % 8); return pkDrainBlock(t, x, y, W, H, e & 1, (e >> 1) & 1, s, f); }
    const int d = m / 3; const int axis = (d / W) & 1; const int par = d & 1;
    return pkDrainDrift(t, x, y, W, H, axis, par, f);
}

static inline int2 pkDirDelta(int d)
{
    if (d == 0) return int2(-1, 0);
    if (d == 1) return int2( 1, 0);
    if (d == 2) return int2( 0, -1);
    return int2(0, 1);
}

// band-order precedence for the local route (mode 0); ring order (mode 1) uses the Batcher rank field
static inline bool pkBandLess(int ax, int ay, int bx, int by, int H)
{
    return bandRank(uint(ax), uint(ay), uint(H)) < bandRank(uint(bx), uint(by), uint(H));
}
static inline bool pkRouteInv(int va, int ax, int ay, int vb, int bx, int by, int H)
{
    return pkBandLess(ax, ay, bx, by, H) ? (va > vb) : (vb > va);
}

// single token value of a cell (lowest occupied lane); occupancy by reference.
static inline int pkSingle(texture2d<half, access::read> t, int x, int y, thread int& occOut, PkForm f)
{
    PkLanes L = pkRead(t, x, y, f);
    occOut = pkOcc(L);
    const int lo = pkLowOcc(L);
    return lo >= 0 ? L.v[lo] : 0;
}

// best (max-inversion) admissible band-route edge from (x,y) over the selected axis
static inline int pkBestEdge(texture2d<half, access::read> t, int x, int y, int v, int axisSel, int W, int H, PkForm f)
{
    const int d0 = (axisSel < 0) ? 0 : ((axisSel == 0) ? 0 : 2);
    const int nd = (axisSel < 0) ? 4 : 2;
    int bestMag = 0, bestDir = -1;
    for (int k = 0; k < nd; k++) {
        const int d = d0 + k;
        const int2 dd = pkDirDelta(d);
        const int nx = (x + dd.x + W) % W, ny = (y + dd.y + H) % H;
        int occN; const int nv = pkSingle(t, nx, ny, occN, f);
        if (occN != 1) continue;
        if (pkRouteInv(v, x, y, nv, nx, ny, H)) { const int mag = (v > nv) ? (v - nv) : (nv - v); if (mag > bestMag) { bestMag = mag; bestDir = d; } }
    }
    return bestDir;
}

// local mutual-best band route (v8); survivor canonicalised into a usable lane
// (lane 1 at (0,0) since lane `primary` may be a counter slot there).
static inline PkLanes pkRouteLocal(texture2d<half, access::read> t, int x, int y, int W, int H, int routeCounter, int primary, PkForm f)
{
    const int pr = pkOrigin(x, y) ? 1 : primary;
    PkLanes Lin = pkRead(t, x, y, f);
    if (pkOcc(Lin) != 1) return Lin;
    int survivor = Lin.v[pkLowOcc(Lin)];
    const int axisSel = ((routeCounter & 1) == 0) ? -1 : ((routeCounter >> 1) & 1);
    const int myDir = pkBestEdge(t, x, y, survivor, axisSel, W, H, f);
    if (myDir >= 0) {
        const int2 dd = pkDirDelta(myDir);
        const int px = (x + dd.x + W) % W, py = (y + dd.y + H) % H;
        int occP; const int pv = pkSingle(t, px, py, occP, f);
        if (occP == 1) {
            const int pDir = pkBestEdge(t, px, py, pv, axisSel, W, H, f);
            if (pDir >= 0) { const int2 pd = pkDirDelta(pDir); if ((px + pd.x + W) % W == x && (py + pd.y + H) % H == y) survivor = pv; }
        }
    }
    PkLanes Lo; for (int i = 0; i < 4; i++) { Lo.v[i] = 0; Lo.p[i] = 0; }
    Lo.v[pr] = survivor; Lo.p[pr] = 1;
    return Lo;
}

// integer isqrt (floor of the square root), exact for the grid's coordinate range
static inline int pkIsqrt(int d)
{
    if (d <= 0) return 0;
    int s = int(sqrt(float(d)));
    while ((s + 1) * (s + 1) <= d) s++;
    while (s * s > d) s--;
    return s;
}
// ring bucket = round(dist) on doubled integer coords X2=2x-W, Y2=2y-H, D=X2*X2+Y2*Y2,
// so round(sqrt(D)/2) is exact integer math (no float rounding at the half boundary)
static inline int pkRingIndex(int d)
{
    if (d <= 0) return 0;
    return (pkIsqrt(d) + 1) / 2;
}
// atan2-ascending sector of a doubled-coord vector: 0 lower half (y<0), 1 the +x axis
// (angle 0), 2 upper half (y>0), 3 the -x axis (angle pi, the maximum)
static inline int pkAngGroup(int X2, int Y2)
{
    if (Y2 < 0) return 0;
    if (Y2 > 0) return 2;
    if (X2 > 0) return 1;
    if (X2 < 0) return 3;
    return 1;
}
// floor division by a strictly positive divisor (c truncates toward zero)
static inline int pkFloorDiv(int n, int d)
{
    int q = n / d;
    if ((n % d) != 0 && n < 0) q--;
    return q;
}
// cells of one row's progression aX2 = 2*xx-W, xx in [0,W), with p <= aX2 <= q and xx < xcap.
// both bounds land on the progression by floor/ceil halving, so the count is exact.
static inline int pkSpanCap(int p, int q, int W, int xcap)
{
    if (q < p) return 0;
    p = max(p, -W);
    q = min(q, W);
    if (q < p) return 0;
    int lo = (W + p + 1) >> 1;                     // ceil, numerator non-negative after the clamp
    int hi = (W + q) >> 1;                         // floor, same
    hi = min(hi, W - 1);
    hi = min(hi, xcap - 1);
    lo = max(lo, 0);
    return (hi >= lo) ? (hi - lo + 1) : 0;
}
static inline int pkSpan(int p, int q, int W) { return pkSpanCap(p, q, W, W); }
// one row's slice of ring bR is the arm lo <= |aX2| <= hi (two runs, or one when lo is 0),
// optionally cut by the angle test to aX2 <= ub or aX2 >= lb
static inline int pkArmAll(int lo, int hi, int W)
{
    if (lo <= 0) return pkSpan(-hi, hi, W);
    return pkSpan(-hi, -lo, W) + pkSpan(lo, hi, W);
}
static inline int pkArmLE(int lo, int hi, int ub, int W)
{
    if (lo <= 0) return pkSpan(-hi, min(ub, hi), W);
    return pkSpan(-hi, min(ub, -lo), W) + pkSpan(lo, min(ub, hi), W);
}
static inline int pkArmGE(int lo, int hi, int lb, int W)
{
    if (lo <= 0) return pkSpan(max(lb, -hi), hi, W);
    return pkSpan(max(lb, -hi), -lo, W) + pkSpan(max(lb, lo), hi, W);
}
// forward ring rank of (x,y): count of cells strictly before it under the harness ring
// order (ring bucket, then atan2 sector + integer cross-product angle, then linear-index
// tiebreak). a strict total order, so the count equals the sorted position.
//
// counted a row at a time instead of a cell at a time, which is the same number the old
// full-plane scan produced. ring(a) < bR is the open disk D < (2*bR-1)^2 and ring(a) == bR
// is the annulus (2*bR-1)^2 <= D < (2*bR+1)^2, so on row yy (aY2 = 2*yy-H fixed) both are
// bounds on aX2^2 alone: two isqrt calls give the disk half-width Mi and the ring outer
// half-width Mo, the disk slice is [-Mi,Mi] and the ring slice is Mi+1 <= |aX2| <= Mo.
// a whole row shares one angle group -- aY2 < 0 is group 0, aY2 > 0 is group 2, aY2 == 0
// splits by sign(aX2) into groups 3 and 1 -- so a row below b's group is added whole and a
// row above it is skipped. inside b's own group the cross product aX2*bY2 - aY2*bX2 > 0 is
// linear in aX2 at fixed aY2, so it is one cut on the row, taken from above when bY2 < 0
// and from below when bY2 > 0. the axis groups hold at most one cell per ring per side, so
// their linear-index tiebreak is the same span with an xx cap. bR == 0 is the lone D == 0
// class and ranks first.
static inline uint pkRingRank(int x, int y, int W, int H)
{
    const int bX2 = 2 * x - W, bY2 = 2 * y - H;
    const int bR = pkRingIndex(bX2 * bX2 + bY2 * bY2);
    if (bR == 0) return 0u;                        // the doubled origin is the whole first class
    const int bG = pkAngGroup(bX2, bY2);
    const int bIdx = y * W + x;
    const int T0 = (2 * bR - 1) * (2 * bR - 1);    // inner threshold, ring < bR
    const int T1 = (2 * bR + 1) * (2 * bR + 1);    // outer threshold, ring <= bR
    uint rank = 0u;
    for (int yy = 0; yy < H; yy++) {
        const int aY2 = 2 * yy - H;
        const int y2s = aY2 * aY2;
        const int Ro = T1 - y2s;
        if (Ro <= 0) continue;                     // row clears ring bR and the disk under it
        const int Mo = pkIsqrt(Ro - 1);
        const int Ri = T0 - y2s;
        int lo = 0;
        if (Ri > 0) {
            const int Mi = pkIsqrt(Ri - 1);
            rank += uint(pkSpan(-Mi, Mi, W));      // the row's disk slice, every ring below bR
            lo = Mi + 1;
        }
        if (lo > Mo) continue;                     // no ring bR cell on this row
        if (aY2 == 0) {                            // axis row, +x is group 1, -x is group 3
            const int xcap = bIdx - yy * W;
            if (bG > 1)       rank += uint(pkSpan(lo, Mo, W));
            else if (bG == 1) rank += uint(pkSpanCap(lo, Mo, W, xcap));
            if (bG == 3)      rank += uint(pkSpanCap(-Mo, -lo, W, xcap));
            continue;
        }
        const int g = (aY2 < 0) ? 0 : 2;
        if (g < bG) { rank += uint(pkArmAll(lo, Mo, W)); continue; }
        if (g > bG) continue;
        if (bG == 0) {                             // bY2 < 0, cross > 0 caps aX2 from above
            const int ub = pkFloorDiv(-(aY2 * bX2) - 1, -bY2);
            rank += uint(pkArmLE(lo, Mo, ub, W));
        } else {                                   // bY2 > 0, cross > 0 floors aX2 from below
            const int lb = pkFloorDiv(aY2 * bX2, bY2) + 1;
            rank += uint(pkArmGE(lo, Mo, lb, W));
        }
    }
    return rank;
}

// ring route (v9), forward-map only. a physical merge-exchange raster-sort keyed on the plain
// linear index sorts the drained tokens ascending (cell i holds the i-th smallest), then one
// gather frame has each cell pull the token at linear index pkRingRank(x,y), scattering the
// sorted run into ring order; an identity tail then holds that state. only the forward rank is
// needed (no inverse), the network is idempotent while sorted, and the post-gather ring state
// is a fixed point, so convergence and the target fixed point are preserved. (0,0) rides kept
// lane 1 (lane 0 is a counter slot) and participates as an ordinary mid-rank cell.
// `dirty` reports that some pixel is not singly occupied. The merge-exchange substages
// are safe under that (a non-single pixel holds and no single reads through it), but the
// gather is a permutation pull: a single source that is not single would leave the puller
// holding its own value while another wire pulls that same value, duplicating one occupant
// and dropping another. So the gather refuses to fire while the board reports dirty.
static inline PkLanes pkRouteBatcher(texture2d<half, access::read> t,
                                     int x, int y, int W, int H, int substage, int primary, PkForm f,
                                     bool dirty = false)
{
    const int pr = pkOrigin(x, y) ? 1 : primary;
    PkLanes Lin = pkRead(t, x, y, f);
    if (pkOcc(Lin) != 1) return Lin;
    int survivor = Lin.v[pkLowOcc(Lin)];
    const int N = W * H;
    uint tt = 0u; while ((1u << tt) < uint(N)) tt++;
    const uint total = (tt * (tt + 1u)) >> 1u;
    const uint raw = uint(substage);
    if (raw < total) {                                   // physical raster merge-exchange substage
        const uint step = raw;
        uint pSel = 0u, rSel = 0u, dSel = 0u;
        { uint idx = 0u; const uint phalf = 1u << (tt - 1u);
          for (uint p = phalf; p >= 1u; p >>= 1u) {
            uint q = phalf, r = 0u, d = p;
            while (true) { if (idx == step) { pSel = p; rSel = r; dSel = d; } idx++;
              if (q == p) break; d = q - p; q >>= 1u; r = p; } } }
        const uint i = uint(y) * uint(W) + uint(x);
        int jr = -1; bool isLow = false;
        if ((i & pSel) == rSel) { const uint j = i + dSel; if (j < uint(N)) { jr = int(j); isLow = true; } }
        else if (i >= dSel && (((i - dSel) & pSel) == rSel)) { jr = int(i - dSel); isLow = false; }
        if (jr >= 0) {
            const int px = jr % W, py = jr / W;
            int occP; const int pv = pkSingle(t, px, py, occP, f);
            if (occP == 1) survivor = isLow ? min(survivor, pv) : max(survivor, pv);
        }
    } else if (raw == total && !dirty) {                 // forward-rank gather -> ring order
        const uint L = pkRingRank(x, y, W, H);
        const int px = int(L) % W, py = int(L) / W;
        int occP; const int pv = pkSingle(t, px, py, occP, f);
        if (occP == 1) survivor = pv;
    }                                                    // raw > total: identity hold
    PkLanes Lo; for (int i = 0; i < 4; i++) { Lo.v[i] = 0; Lo.p[i] = 0; }
    Lo.v[pr] = survivor; Lo.p[pr] = 1;
    return Lo;
}

// ============================================================================
// ROWS 10/11 -- PERPETUAL PAIR-FORM SORT
// ----------------------------------------------------------------------------
// These rows run continuously. The app may paint into the plane on any frame, so
// there is no entry phase, no phase schedule, no end state and no whole-board scan:
// every frame is the same frame. Two local rules, both carried by one transaction
// over one pair of pixels:
//
//   drain  a pixel holding two occupants hands one to an adjacent pixel holding
//          none, by mutual agreement -- both members of the pair compute the same
//          transaction from the same two reads, so no atomics and no arbitration.
//   order  neighbouring pixels exchange occupants when they are out of order for the
//          row's target, decided by an O(1) key comparison on coordinates. The rank
//          number is never formed; the comparator answers only "is this cell earlier".
//
// STORAGE, one form every frame -- no lane form, no display form, no flight.
//   off origin : .r count 0/1/2 over 255, .b occupant one over 255, .g occupant two
//     over 255 (zero below count 2), .a one. An empty pixel is half4(0,0,0,1).
//     Canonical in-pixel order is .b <= .g, so the state is a function of the
//     occupant multiset with no hidden history. .a = 1 tells the colour stage this
//     pixel holds up to two occupants.
//   at  origin : .r/.a keep the broadcast counter, .b the single occupant, .g the
//     count. (0,0) therefore holds nothing or one occupant and never two -- it has
//     one value slot. That cap is the only deviation from the uniform rule, and it
//     lives entirely in dblTransact.
//
// TICKER. The origin's counter is a benign alternation ticker and nothing else:
// pass = counter mod 4 (row 10) or mod 8 (row 11). A garbage start byte phases the
// cycle and changes nothing else, verified by an exhaustive start-phase sweep -- all
// residues give identical medians and worsts pairwise (17 = 1, 200 = 0, 255 = 3).
// The counter wraps at 65536, which is a multiple of both periods, so the wrap is not
// a discontinuity either.
//
// ORDER, ROW 10 -- BAND, as shipped. i = x*H + ((x&1)==0 ? y : H-1-y), earlier is the
// smaller i. A grid-adjacent linearisation: a successor census over 187 board sizes
// (16..132 in both axes) gives worst Chebyshev gap 1 and successor offset set exactly
// {(0,-1),(0,+1),(+1,0)}, so the four axis passes below are the minimal covering set.
// Diagonals are legal and measured worse in the tail (128x128 worst 18105 against
// 4425), so they are not taken.
//
// ORDER, ROW 11 -- CIRCULAR RING. Euclidean ring bucket on doubled coordinates,
// then octant, then an integer cross product inside the octant, then the linear
// index. Note: this circle is not byte-equal to row 9's (dblRingBucket floors where
// pkRingIndex rounds; the axes centre on 2x-(W-1) not 2x-W; octants replace the
// four-way sector) -- same picture, slightly different ring boundaries and
// within-ring order. The circular look is kept deliberately. Circular order
// puts order-neighbours far apart on a rectangle -- the outer rings are clipped into
// four disjoint corner arcs the angular order visits consecutively -- so a rule that
// reads one texel cannot carry an occupant across those seams and the board does not
// reach its exact target. It reaches a fixed point short of it and holds there.
//
// The residual is geometric, not a schedule property. Off-target fraction measured
// over 24 seed classes x 2 reps at five sizes, against the area fraction outside the
// inscribed circle:
//   size      off% med   outside-circle%   visible >5%   largest blob
//   32x32       22.27       21.46             6.74          70 cells
//   64x64       21.97       21.46             3.50         251
//   96x64       47.17       47.64             4.42        1458
//   128x128     21.78       21.46             2.90         953
//   33x47       43.71       44.86             9.12         350
//   512x512     21.57       21.46             2.45       14354
// Off% tracks the geometry to within 1.2 points at every size, the cells inside the
// inscribed circle are 0.1 to 3.0 percent off target and the cells outside it are
// essentially all off target. Four seed classes -- sorted, all-equal, and both
// two-value classes -- do reach the exact target at every size, 10 runs of 10.
//
// The one-texel alphabet is exhausted, not sampled. An offset admits a phase
// functional only where that functional is odd on it, so (1,0) admits x and x+y,
// (0,1) admits y and x+y, and (1,1) and (1,-1) admit x and y: 8 families x 2 phases
// = 16 classes and no seventeenth exists. All 16 were built and run at all five
// sizes. Nothing below eight classes survives (H+V alone freezes the board after
// about 100 frames with 99.93% of cells wrong; adding a brick class instead is no
// better at 99.94%) and nothing above eight helps (r12b 21.89%, r12d 21.69%, r16
// 21.91%, r16i 22.78%, all inside seed noise of the eight-class 21.78% while costing
// 31 to 200 percent more frames). The eight below are therefore the chosen set.
//
// PASSES, one pairing per frame, chosen by the ticker.
//   row 10, mod 4 : V phase 0/1, then H phase 0/1
//   row 11, mod 8 : H phase 0/1, V phase 0/1, D+ (1,1) phase 0/1, D- (1,-1) phase 0/1
// Phase parity is on x for H and for both diagonals, on y for V. The grouped order is
// load bearing: the interleaved permutation of the same eight classes measures worse
// on every metric (22.33% against 21.78% off target, 6566 against 3787 frames at
// 128x128). Both diagonal classes are mandatory -- the diagonal step is the
// ring-to-ring seam, and without it the board freezes almost at once.
// A cell whose partner is off board idles that frame; the pairing never wraps.
//
// COST. O(1) per pixel per frame: three texture reads (self, one partner, and the
// ticker at (0,0)), one comparison, one four-element merge. Neighbourhood one texel
// for occupant motion, inside the two-texel
// family proximity budget. No whole-board work anywhere, no dispatch that scales with
// the plane, so the cost per frame is flat in the board size.
//
// QUIESCENCE, measured. A board that goes two full alternation periods with no state
// change is a proven fixed point of every pass class, so it holds forever until the
// app paints on it. Frames to quiescence, median and worst over 24 seed classes:
//   row 10   32x32 311/344     128x128 4185/4388    512x512 63366  (off target 0.0000
//                                                    at every size, 248 runs of 248)
//   row 11   32x32 462/1643    128x128 3787/24223   512x512 46648/47852
// WAKE. A 16x16 block painted onto a quiesced board moves state on the very next
// frame -- maximum delay over 484 runs is 1 frame, at every size and for both rows --
// and the board re-quiesces without ever failing (row 11 median 1894 frames at
// 128x128, row 10 back to exactly zero off target every time). Thirty successive
// paints on one board leave row 11's residual oscillating between 21.09 and 25.76
// percent with no upward drift.
// ============================================================================

constant int dblEmpty = 0xffff;    // empty-slot sentinel; sorts after every byte key

// ---- order comparator, O(1) per cell, no rank number ------------------------

// row 10 band key: boustrophedon column scan, the shipped v10 target unchanged
static inline int dblBandKey(int x, int y, int H)
{
    return x * H + (((x & 1) == 0) ? y : (H - 1 - y));
}

// row 11 doubled coordinates: the board centre lands at (0,0) whatever the parity of
// W and H, and every component stays an integer, so the whole comparator is exact
static inline int2 dblRingAxes(int x, int y, int W, int H)
{
    return int2(2 * x - (W - 1), 2 * y - (H - 1));
}

// euclidean ring bucket, the shipped circular target: floor of the doubled radius,
// halved back. pkIsqrt is the exact integer square root already in this file.
static inline int dblRingBucket(int2 d)
{
    return pkIsqrt(d.x * d.x + d.y * d.y) / 2;
}

// octant of (a,b), counter clockwise from +a
static inline int dblOctant(int a, int b)
{
    if (b >= 0) {
        if (a > 0) return (b <= a) ? 0 : 1;
        if (a < 0) return (b >= -a) ? 2 : 3;
        return (b == 0) ? 0 : 1;
    }
    if (a < 0) return (-b <= -a) ? 4 : 5;
    if (a > 0) return (-b >= a) ? 6 : 7;
    return 6;
}

static inline bool dblRingEarlier(int ax, int ay, int bx, int by, int W, int H)
{
    const int2 pa = dblRingAxes(ax, ay, W, H), pb = dblRingAxes(bx, by, W, H);
    const int ra = dblRingBucket(pa), rb = dblRingBucket(pb);
    if (ra != rb) return ra < rb;
    const int ga = dblOctant(pa.x, pa.y), gb = dblOctant(pb.x, pb.y);
    if (ga != gb) return ga < gb;
    const int cr = pa.x * pb.y - pa.y * pb.x;    // within one octant: integer cross product
    if (cr != 0) return cr > 0;
    return (ay * W + ax) < (by * W + bx);        // ties fall through to the linear index
}

static inline bool dblEarlier(int ax, int ay, int bx, int by, int W, int H, int row)
{
    if (row == 10) return dblBandKey(ax, ay, H) < dblBandKey(bx, by, H);
    return dblRingEarlier(ax, ay, bx, by, W, H);
}

// ---- pass schedule ----------------------------------------------------------

static inline int dblPassCount(int row) { return (row == 10) ? 4 : 8; }

// (dx, dy, phase) of pass p; the parity coordinate is x when dx is nonzero, else y
static inline int3 dblPass(int p, int row)
{
    if (row == 10) {
        if (p == 0) return int3(0,  1, 0);
        if (p == 1) return int3(0,  1, 1);
        if (p == 2) return int3(1,  0, 0);
        return          int3(1,  0, 1);
    }
    if (p == 0) return int3(1,  0, 0);
    if (p == 1) return int3(1,  0, 1);
    if (p == 2) return int3(0,  1, 0);
    if (p == 3) return int3(0,  1, 1);
    if (p == 4) return int3(1,  1, 0);
    if (p == 5) return int3(1,  1, 1);
    if (p == 6) return int3(1, -1, 0);
    return          int3(1, -1, 1);
}

// this frame's partner: the +step neighbour when the cell is the pass's first member,
// the -step neighbour when it is the second. The parity flips across one step, so the
// two members always name each other and the pairing is an involution. False when the
// partner is off board, and the cell then idles.
static inline bool dblPartnerOf(int x, int y, int W, int H, int3 ps, thread int2& q)
{
    const int coord = (ps.x != 0) ? x : y;
    const int d = (((coord - ps.z + 2) & 1) == 0) ? 1 : -1;
    q = int2(x + d * ps.x, y + d * ps.y);
    return q.x >= 0 && q.x < W && q.y >= 0 && q.y < H;
}

// ---- pair form --------------------------------------------------------------

struct DblCell { int n; int k0; int k1; };   // k0 <= k1, dblEmpty in an unused slot

static inline DblCell dblRead(texture2d<half, access::read> t, int x, int y)
{
    const half4 c = t.read(uint2(uint(x), uint(y)));
    DblCell p;
    if (pkOrigin(x, y)) {                                  // count in .g, one value slot
        p.n  = clamp(int(float(c.y) * 255. + 0.5), 0, 1);
        p.k0 = (p.n >= 1) ? int(float(c.z) * 255. + 0.5) : dblEmpty;
        p.k1 = dblEmpty;
        return p;
    }
    p.n  = clamp(int(float(c.x) * 255. + 0.5), 0, 2);      // a painted byte decodes as a count
    p.k0 = (p.n >= 1) ? int(float(c.z) * 255. + 0.5) : dblEmpty;
    p.k1 = (p.n >= 2) ? int(float(c.y) * 255. + 0.5) : dblEmpty;
    if (p.k0 > p.k1) { const int sw = p.k0; p.k0 = p.k1; p.k1 = sw; }
    return p;
}

static inline void dblWrite(texture2d<half, access::write> o, uint2 gid,
                            thread const DblCell& p, int cLo, int cHi)
{
    const bool org = pkOrigin(int(gid.x), int(gid.y));
    const float fr = org ? float(cLo) / 255. : float(p.n) / 255.;
    const float fa = org ? float(cHi) / 255. : 1.0;        // off origin: alpha at one
    const float fg = org ? float(p.n) / 255.
                         : ((p.n < 2) ? 0.0 : float(p.k1 & 0xff) / 255.);
    const float fb = (p.n >= 1) ? float(p.k0 & 0xff) / 255. : 0.0;
    o.write(half4(half(fr), half(fg), half(fb), half(fa)), gid);
}

// ---- the pair transaction, drain and order in one expression ----------------
// Both members run this with the same two cells and reach the same two results, so
// the frame needs no atomics: each writes only its own half.
//   merge the two sorted 2-lists to m0 <= m1 <= m2 <= m3 (dblEmpty last), then
//   count rule  nE = (n==0) ? 0 : (n==4) ? 2 : 1, nL = n - nE
//   keys        the earlier cell takes the small end, the later cell the rest.
// So (2,0) -> (1,1) is the drain, (2,1) -> (1,2) walks the surplus toward the order
// tail, and (1,2) and (2,2) are already fixed points. Equal keys never swap, since the
// merge is stable in value terms; duplicates and an all-equal plane converge.
static inline DblCell dblTransact(thread const DblCell& S, thread const DblCell& P,
                                  bool selfEarlier, bool originLater)
{
    const int lo0 = min(S.k0, P.k0), hi0 = max(S.k0, P.k0);
    const int lo1 = min(S.k1, P.k1), hi1 = max(S.k1, P.k1);
    const int m0 = lo0;
    const int m1 = min(hi0, lo1);
    const int m2 = max(hi0, lo1);
    const int m3 = hi1;
    const int n = S.n + P.n;
    int nE = (n == 0) ? 0 : ((n == 4) ? 2 : 1);
    // the origin has one value slot, so it never receives a second occupant. Only
    // (earlier holds two, origin holds one) is touched, and the clamped pair is itself
    // a fixed point, so the surplus simply stacks one rank earlier.
    if (originLater && n == 3) nE = 2;
    const int nL = n - nE;
    const int e0 = (nE >= 1) ? m0 : dblEmpty;
    const int e1 = (nE >= 2) ? m1 : dblEmpty;
    const int l0 = (nE == 0) ? m0 : ((nE == 1) ? m1 : m2);
    const int l1 = (nE == 0) ? m1 : ((nE == 1) ? m2 : m3);
    DblCell o;
    o.n  = selfEarlier ? nE : nL;
    o.k0 = selfEarlier ? e0 : ((nL >= 1) ? l0 : dblEmpty);
    o.k1 = selfEarlier ? e1 : ((nL >= 2) ? l1 : dblEmpty);
    return o;
}

// ---- one frame --------------------------------------------------------------
static inline void dblFrame(texture2d<half, access::read>  inTex,
                            texture2d<half, access::write> outTex,
                            uint2 gid, int W, int H, int row, int tick, int cLo, int cHi)
{
    const int x = int(gid.x), y = int(gid.y);
    DblCell S = dblRead(inTex, x, y);
    const int3 ps = dblPass(tick % dblPassCount(row), row);
    int2 q;
    if (dblPartnerOf(x, y, W, H, ps, q)) {
        const DblCell P = dblRead(inTex, q.x, q.y);
        const bool selfEarlier = dblEarlier(x, y, q.x, q.y, W, H, row);
        const bool originLater = pkOrigin(x, y) ? !selfEarlier
                               : (pkOrigin(q.x, q.y) && selfEarlier);
        S = dblTransact(S, P, selfEarlier, originLater);
    }
    dblWrite(outTex, gid, S, cLo, cHi);
}

// ---- entry reseed ------------------------------------------------------------
// Rows 10/11 are entered by a rule switch, so the incoming texture is the previous
// rule's leftover, not a board this row ever wrote. The one-frame reseed pulse
// (`reseed` on the warren flo node, raised by the app for exactly one rendered frame
// at entry) discards that state and writes the perpetual pair form directly: one
// occupant per pixel taken from .b, which is where the rules the app switches from
// leave their value, count one, alpha tagged, counter bytes zero. The next frame is
// an ordinary frame -- there is no entry phase to cross.
static inline void dblReseed(texture2d<half, access::read>  inTex,
                             texture2d<half, access::write> outTex,
                             uint2 gid)
{
    const half4 c = inTex.read(gid);
    DblCell p;
    p.n  = 1;
    p.k0 = clamp(int(float(c.z) * 255. + 0.5), 0, 255);
    p.k1 = dblEmpty;
    dblWrite(outTex, gid, p, 0, 0);                       // counter bytes zero
}

// ---- one v10/v11 frame ----
static inline void dblStep(texture2d<half, access::read>  inTex,
                           texture2d<half, access::write> outTex,
                           uint2 gid, int row, float reseed)
{
    if (reseed > 0.5) { dblReseed(inTex, outTex, gid); return; }   // entry pulse, before the counter decode
    const int W = int(outTex.get_width()), H = int(outTex.get_height());
    const int counter = pkCounter(inTex, true);
    const int nc = (counter + 1) & 0xffff;
    dblFrame(inTex, outTex, gid, W, H, row, counter, nc & 0xff, (nc >> 8) & 0xff);
}

kernel void warrenKernel
(
 texture2d<half, access::read>  inTex   [[ texture(0) ]],
 texture2d<half, access::write> outTex  [[ texture(1) ]],
 constant float&                version [[ buffer(0)  ]],   // warrenVersion 0..1 (default 1)
 constant float&                reseed  [[ buffer(1)  ]],   // rows 10/11 entry pulse, 0 or 1
 uint2 gid [[thread_position_in_grid]])
{
    const uint  xs = outTex.get_width();
    const uint  ys = outTex.get_height();
    const uint2 ci(gid.x, gid.y);

    // ---- v0 value-band shear sort (alternating complete odd-even passes) ----
    if (version < 0.5) {
        const int ixs = int(xs);
        const int iys = int(ys);
        const int cx  = int(gid.x);
        const int cy  = int(gid.y);

        const uint counter = cellHiC(inTex, uint2(0, 0)) & 0xffffu;  // broadcast frame counter
        const uint stage   = (counter / uint(ixs)) & 1u;            // 0 vertical, 1 horizontal
        const int  par     = int(counter & 1u);                     // odd/even pair offset
        int val = cellByte(inTex, uint2(uint(cx), uint(cy)));       // default: pass through

        if (stage == 0u) {                          // vertical band-order odd-even pass
            const bool asc = ((cx & 1) == 0);                       // even column: minima north
            const bool top = (cy >= par) && (((cy - par) & 1) == 0) && (cy + 1 < iys);
            const bool bot = (cy - 1 >= par) && (((cy - 1 - par) & 1) == 0);
            if (top)      { int o = cellByte(inTex, uint2(uint(cx), uint(cy + 1))); val = asc ? min(val, o) : max(val, o); }
            else if (bot) { int o = cellByte(inTex, uint2(uint(cx), uint(cy - 1))); val = asc ? max(val, o) : min(val, o); }
        } else {                                    // horizontal ascending odd-even pass
            const bool west = (cx >= par) && (((cx - par) & 1) == 0) && (cx + 1 < ixs);
            const bool east = (cx - 1 >= par) && (((cx - 1 - par) & 1) == 0);
            if (west)      { int o = cellByte(inTex, uint2(uint(cx + 1), uint(cy))); val = min(val, o); }
            else if (east) { int o = cellByte(inTex, uint2(uint(cx - 1), uint(cy))); val = max(val, o); }
        }

        const uint outHiC = (cx == 0 && cy == 0) ? ((counter + 1u) & 0xffffu) : 0u;  // (0,0) advances counter
        outTex.write(packCell(val, outHiC), ci);
        return;
    }

    // ---- v2 band-order Batcher merge-exchange network (Knuth 5.2.2 Alg M) ----
    // TARGET = BAND ORDER: linear i = x*H + ((x&1)==0 ? y : H-1-y) (column-major,
    // columns alternating direction -> sorted sequence continuous across columns,
    // straight vertical band boundaries). Merge exchange sorts N=W*H in t(t+1)/2
    // substages, t=ceil(log2 N) (171 for 2^18), ONE SUBSTAGE PER FRAME. Substage
    // decoded from the broadcast (0,0) counter mod totalSubstages; (p,r,d) found by
    // replaying Alg M's loops from step 0 (<=210 trivial iterations). All
    // comparators ascending (min at lower band-order index) -> idempotent: sorted
    // data fires nothing at any substage, cycling the schedule is a static fixed
    // point; any perturbation re-sorts within one cycle. Non-power-of-two N native
    // (out-of-range partners pass through). Deterministic, no spin.
    if (version >= 1.5 && version < 2.5) {
        const uint W = xs;
        const uint H = ys;
        const uint N = W * H;

        uint t = 0u;                                     // t = ceil(log2 N)
        while ((1u << t) < N) t++;
        const uint totalSubstages = (t * (t + 1u)) >> 1u;

        const uint counter = cellHiC(inTex, uint2(0, 0)) & 0xffffu;  // broadcast frame counter
        const uint step    = counter % totalSubstages;              // substage this frame

        // replay Alg M loops from substage 0 to `step`, extract (p, r, d)
        uint pSel = 0u, rSel = 0u, dSel = 0u;
        {
            uint idx = 0u;
            const uint phalf = 1u << (t - 1u);
            for (uint p = phalf; p >= 1u; p >>= 1u) {
                uint q = phalf, r = 0u, d = p;
                while (true) {
                    if (idx == step) { pSel = p; rSel = r; dSel = d; }
                    idx++;
                    if (q == p) break;                   // M4: q==p ends inner loop
                    d = q - p; q >>= 1u; r = p;          // M4 body: next d,q,r
                }
            }
        }

        // own band-order linear index
        const uint i = gid.x * H + (((gid.x & 1u) == 0u) ? gid.y : (H - 1u - gid.y));
        int outV = cellByte(inTex, uint2(gid.x, gid.y));            // default: pass through

        if ((i & pSel) == rSel) {                        // low member of a pair (if partner in range)
            const uint j = i + dSel;
            if (j < N) {
                const uint jx = j / H, jr = j % H;
                const uint jy = ((jx & 1u) == 0u) ? jr : (H - 1u - jr);
                outV = min(outV, cellByte(inTex, uint2(jx, jy)));   // min ends at lower index
            }
        } else if (i >= dSel && (((i - dSel) & pSel) == rSel)) {    // high member of a pair
            const uint j = i - dSel;
            const uint jx = j / H, jr = j % H;
            const uint jy = ((jx & 1u) == 0u) ? jr : (H - 1u - jr);
            outV = max(outV, cellByte(inTex, uint2(jx, jy)));       // max ends at higher index
        }

        const uint outHiC = (gid.x == 0u && gid.y == 0u) ? ((counter + 1u) & 0xffffu) : 0u;
        outTex.write(packCell(outV, outHiC), ci);
        return;
    }

    // ---- v3 band-order local exchanger with spin (2-frame cycle) ----
    // BAND-ORDER target (sorted bytes filled column-major west->east, even cols
    // north->south, odd cols south->north -> STRAIGHT vertical bands, continuous
    // across joins). Nearest-neighbour comparators: min-west horizontals, band-order
    // verticals (even col min-north, odd col min-south), decideSwap/resist/decay
    // spin. Contrast variant to the v2 network: axis flips EVERY frame (counter&1),
    // pair offset flips every 2 frames ((counter>>1)&1), so all four comparator
    // classes (H0,H1,V0,V1) recur every 4 frames. Not doubly-monotone: that target
    // staircases its band edges and never reaches a fixed point.
    if (version >= 2.5 && version < 3.5) {
        const int  ixs = int(xs);
        const int  iys = int(ys);
        const int  cx  = int(gid.x);
        const int  cy  = int(gid.y);
        const uint counter = cellHiC(inTex, uint2(0, 0)) & 0xffffu;   // broadcast frame counter
        const uint axis    = counter & 1u;                           // 0 horizontal 1 vertical, flips every frame
        const int  par     = int((counter >> 1) & 1u);               // pair offset, flips every 2 frames
        const int  resist  = 1;                                      // spin resist threshold

        const int  selfV    = cellByte(inTex, uint2(uint(cx), uint(cy)));
        const uint selfSpin = readSpinWord(inTex, uint2(uint(cx), uint(cy)));
        int  outV    = selfV;                                        // default: pass through
        uint outSpin = 0u;                                           // default: did not move -> clear

        if (axis == 0u) {                                           // horizontal, min ends west
            const bool west = (cx - par >= 0) && (((cx - par) & 1) == 0) && (cx + 1 < ixs);
            const bool east = (cx - 1 - par >= 0) && (((cx - 1 - par) & 1) == 0);
            if (west) {
                const int  o  = cellByte(inTex, uint2(uint(cx + 1), uint(cy)));
                const uint os = readSpinWord(inTex, uint2(uint(cx + 1), uint(cy)));
                if (decideSwap(selfV, o, selfSpin, os, 0u, resist)) { outV = o; outSpin = packSpin(true, 0u, 0u); }
            } else if (east) {
                const int  o  = cellByte(inTex, uint2(uint(cx - 1), uint(cy)));
                const uint os = readSpinWord(inTex, uint2(uint(cx - 1), uint(cy)));
                if (decideSwap(o, selfV, os, selfSpin, 0u, resist)) { outV = o; outSpin = packSpin(true, 0u, 1u); }
            }
        } else {                                                    // vertical band-order: even col min-north, odd col min-south
            const bool asc   = ((cx & 1) == 0);                     // even column ascends north->south
            const bool north = (cy - par >= 0) && (((cy - par) & 1) == 0) && (cy + 1 < iys);
            const bool south = (cy - 1 - par >= 0) && (((cy - 1 - par) & 1) == 0);
            if (north) {                                            // upper cell of pair, neighbour below
                const int  o  = cellByte(inTex, uint2(uint(cx), uint(cy + 1)));
                const uint os = readSpinWord(inTex, uint2(uint(cx), uint(cy + 1)));
                const bool fire = asc ? decideSwap(selfV, o, selfSpin, os, 1u, resist)  // upper = min-end
                                      : decideSwap(o, selfV, os, selfSpin, 1u, resist);  // upper = max-end
                if (fire) { outV = o; outSpin = packSpin(true, 1u, asc ? 0u : 1u); }
            } else if (south) {                                     // lower cell of pair, neighbour above
                const int  o  = cellByte(inTex, uint2(uint(cx), uint(cy - 1)));
                const uint os = readSpinWord(inTex, uint2(uint(cx), uint(cy - 1)));
                const bool fire = asc ? decideSwap(o, selfV, os, selfSpin, 1u, resist)  // lower = max-end
                                      : decideSwap(selfV, o, selfSpin, os, 1u, resist);  // lower = min-end
                if (fire) { outV = o; outSpin = packSpin(true, 1u, asc ? 1u : 0u); }
            }
        }

        const uint outHiC = (cx == 0 && cy == 0) ? ((counter + 1u) & 0xffffu) : outSpin;
        outTex.write(packCell(outV, outHiC), ci);
        return;
    }

    // ---- v4 tetrahedral 3-sort + distance-2 transport (candL3 lineage) ----
    // phase = counter%6 : 0-3 main-diagonal triangle 3-sorts (origin shift {0,0}
    // then {1,1}; triA/triB alternate), 4 = H distance-2 min-west skip, 5 = V
    // distance-2 band-order skip. The 3-sort assigns band-rank-sorted values to a
    // 2x2 tile's three vertices across its MAIN-diagonal hypotenuse (anti-diagonal
    // forbidden: it fires at band order). candL3 alone plateaus (residual
    // oscillators); the two distance-2 strokes transport those two texels per
    // stroke to reach the fixed point. All six phases quiescent at band order --
    // value is monotonic in band rank so every 3-sort is a no-op, rows strictly
    // increase west->east and band columns are parity-monotone so both distance-2
    // skips are no-ops -- hence exact band order is a fixed point. Each phase is a
    // permutation (triangle vertices permuted, excluded vertex + disjoint distance-2
    // pairs conserved). Functionally distinct from v3: triangle 3-sort comparator
    // set + distance-2 transport, no spin word, 6-phase schedule (vs v3's pairwise
    // spin compare-exchange on a 2-frame axis-alternating schedule).
    if (version >= 3.5 && version < 4.5) {
        const int  ixs = int(xs);
        const int  iys = int(ys);
        const int  cx  = int(gid.x);
        const int  cy  = int(gid.y);
        const uint counter = cellHiC(inTex, uint2(0, 0)) & 0xffffu;   // broadcast frame counter
        const uint phase   = counter % 6u;
        int outV = cellByte(inTex, uint2(uint(cx), uint(cy)));        // default: pass through

        if (phase == 0u || phase == 2u) {          // H distance-1 odd-even, min-west
            const int  par  = (phase == 0u) ? 0 : 1;
            const bool west = (cx - par >= 0) && (((cx - par) & 1) == 0) && (cx + 1 < ixs);
            const bool east = (cx - 1 - par >= 0) && (((cx - 1 - par) & 1) == 0);
            if (west)      outV = min(outV, cellByte(inTex, uint2(uint(cx + 1), uint(cy))));
            else if (east) outV = max(outV, cellByte(inTex, uint2(uint(cx - 1), uint(cy))));
        } else if (phase == 1u || phase == 3u) {   // V distance-1 odd-even, band-order
            const int  par   = (phase == 1u) ? 0 : 1;
            const bool asc   = ((cx & 1) == 0);                       // even col min-north
            const bool north = (cy - par >= 0) && (((cy - par) & 1) == 0) && (cy + 1 < iys);
            const bool south = (cy - 1 - par >= 0) && (((cy - 1 - par) & 1) == 0);
            if (north)      { int o = cellByte(inTex, uint2(uint(cx), uint(cy + 1))); outV = asc ? min(outV, o) : max(outV, o); }
            else if (south) { int o = cellByte(inTex, uint2(uint(cx), uint(cy - 1))); outV = asc ? max(outV, o) : min(outV, o); }
        } else {                                   // main-diagonal triangle 3-sort (phase 4 triA sh0, phase 5 triB sh1)
            const int  shift = (phase == 5u) ? 1 : 0;
            const bool triA  = (phase == 4u);
            const int  lx = cx - shift;
            const int  ly = cy - shift;
            if (lx >= 0 && ly >= 0) {
                const int bx = shift + (lx & ~1);
                const int by = shift + (ly & ~1);
                if (bx + 1 < ixs && by + 1 < iys) {
                    int2 vA, vB, vC, excl;
                    if (triA) { vA = int2(bx,by); vB = int2(bx+1,by); vC = int2(bx+1,by+1); excl = int2(bx,by+1); }
                    else      { vA = int2(bx,by); vB = int2(bx,by+1); vC = int2(bx+1,by+1); excl = int2(bx+1,by); }
                    if (!(cx == excl.x && cy == excl.y)) {
                        int2 vc[3] = { vA, vB, vC };
                        int  val[3];
                        uint rnk[3];
                        for (int k = 0; k < 3; k++) {
                            val[k] = cellByte(inTex, uint2(uint(vc[k].x), uint(vc[k].y)));
                            rnk[k] = bandRank(uint(vc[k].x), uint(vc[k].y), ys);
                        }
                        int sv[3] = { val[0], val[1], val[2] };        // sorted ascending
                        for (int a = 0; a < 2; a++)
                            for (int b = 0; b < 2 - a; b++)
                                if (sv[b] > sv[b+1]) { int tmp = sv[b]; sv[b] = sv[b+1]; sv[b+1] = tmp; }
                        int self3 = 0;
                        for (int k = 0; k < 3; k++) if (vc[k].x == cx && vc[k].y == cy) self3 = k;
                        int pos = 0;                                   // band-rank position of self among the three
                        for (int k = 0; k < 3; k++) if (rnk[k] < rnk[self3]) pos++;
                        outV = sv[pos];
                    }
                }
            }
        }

        const uint outHiC = (cx == 0 && cy == 0) ? ((counter + 1u) & 0xffffu) : 0u;
        outTex.write(packCell(outV, outHiC), ci);
        return;
    }

    // ---- v5 Ising mutual-best compare-exchange, DUAL/SINGLE interleaved schedule ----
    // Each cell takes its max-inversion admissible band-order edge (argmax, priority
    // W>E>N>S) and swaps iff that edge is the partner's best too (MUTUAL -> disjoint
    // matching -> conservative permutation). candL4's single-axis-alternating schedule
    // is deadlock-free but O(side) with too small a per-frame constant: it fully sorts
    // at 256 yet plateaus at 512 (b endMism 58475 @4096). Root fix = 2-frame schedule
    //   even counter -> DUAL axis  (argmax over all four {W,E,N,S})
    //   odd  counter -> SINGLE axis (counter>>1)&1  (H then V)
    // The dual frame doubles throughput (both axes matched at once); the single frame
    // is 1D mutual-best, which strictly reduces inversions along its line and so always
    // breaks the residual 2-cycle a bare dual-axis rule can seat (bare dual plateaus at
    // 256: endMism 302). Measured: fixed point by ~1934-2425 frames at 512 across seeds,
    // clean ~2x-per-side scaling, no limit cycle at any tested size. All reads within 2
    // texels (partner at distance 1, its edges at distance 2). Every frame is a
    // permutation and quiescent at band order (all edge magnitudes 0 -> no matching),
    // so exact band order is a fixed point. NOT candL4 (single-axis only) and distinct
    // from v3 (spin decideSwap, 2-frame odd-even) and v4 (3-sort + odd-even + distance-2):
    // v5 alone is mutual-best matching, no comparator parity, no spin word.
    if (version >= 4.5 && version < 5.5) {
        const int  W  = int(xs);
        const int  H  = int(ys);
        const int  cx = int(gid.x);
        const int  cy = int(gid.y);
        const uint counter = cellHiC(inTex, uint2(0, 0)) & 0xffffu;   // broadcast frame counter
        const int  axis    = ((counter & 1u) == 0u) ? -1               // even frame: dual axis
                                                    : int((counter >> 1) & 1u);  // odd: single H/V

        const int selfV = cellByte(inTex, uint2(uint(cx), uint(cy)));
        int outV = selfV;

        int myMag;
        int myDir = bestEdge(inTex, cx, cy, W, H, axis, myMag);
        if (myDir >= 0) {
            int2 dd = dirDelta(myDir);
            int px = cx + dd.x, py = cy + dd.y;    // partner
            int pMag;
            int pDir = bestEdge(inTex, px, py, W, H, axis, pMag);
            int2 pd = (pDir >= 0) ? dirDelta(pDir) : int2(0, 0);
            const bool mutual = (pDir >= 0) && (px + pd.x == cx) && (py + pd.y == cy);
            if (mutual) {
                outV = cellByte(inTex, uint2(uint(px), uint(py)));   // conservative disjoint-matching swap
            }
        }

        const uint outHiC = (cx == 0 && cy == 0) ? ((counter + 1u) & 0xffffu) : 0u;
        outTex.write(packCell(outV, outHiC), ci);
        return;
    }

    // ---- v6 octahedral Margolus 2x2 block, gated anti-diagonal (candO1 lineage) ----
    // 6-phase schedule : 0 block even-offset diag, 1 H odd, 2 V odd, 3 block odd-offset
    // diag, 4 H even, 5 V even. Block offsets even{(2i,2j)} / odd{(2i+1,2j+1)} are the
    // two octahedral sublattices; all four block threads read one snapshot and write
    // their own post-swap value -> block output permutes block input (conservation).
    // Each block picks at most one leg: main (NW-SE) ungated, fires when the lower-rank
    // vertex holds the larger tieKey; anti (NE-SW) gated, fires only when the swap
    // strictly raises block match-count vs the local band-order ideal (anti-diagonal is
    // quiescent at band order otherwise). Main/anti contention is resolved by fixed
    // priority: min-left over {NW,SW} vs max-right over {NE,SE} by tieKey (value, then
    // band position). History-resistance was measured unreachable in this rule class and
    // removed. Distinct from v5 (mutual-best matching, no block partition) and v4
    // (triangle 3-sort, no diagonal gating). Race fixed point r/g/b = 2986/3082/3073
    // frames on the zigular seed, conservative, endMism 0.
    if (version >= 5.5 && version < 6.5) {
        const int  W  = int(xs);
        const int  H  = int(ys);
        const uint HU = ys;
        const int  cx = int(gid.x);
        const int  cy = int(gid.y);
        const uint counter = cellHiC(inTex, uint2(0, 0)) & 0xffffu;   // broadcast frame counter
        const uint phase   = counter % 6u;

        const int  selfV    = cellByte(inTex, gid);
        int  outV    = selfV;

        if (phase == 1u || phase == 4u) {              // H odd-even min-west finisher
            const int  par  = (phase == 1u) ? 1 : 0;
            const bool west = (cx - par >= 0) && (((cx - par) & 1) == 0) && (cx + 1 < W);
            const bool east = (cx - 1 - par >= 0) && (((cx - 1 - par) & 1) == 0);
            if (west)      outV = min(selfV, cellByte(inTex, uint2(uint(cx + 1), uint(cy))));
            else if (east) outV = max(selfV, cellByte(inTex, uint2(uint(cx - 1), uint(cy))));
        } else if (phase == 2u || phase == 5u) {       // V odd-even band-order finisher
            const int  par   = (phase == 2u) ? 1 : 0;
            const bool asc   = ((cx & 1) == 0);        // even col min-north
            const bool north = (cy - par >= 0) && (((cy - par) & 1) == 0) && (cy + 1 < H);
            const bool south = (cy - 1 - par >= 0) && (((cy - 1 - par) & 1) == 0);
            if (north)      { int o = cellByte(inTex, uint2(uint(cx), uint(cy + 1))); outV = asc ? min(selfV, o) : max(selfV, o); }
            else if (south) { int o = cellByte(inTex, uint2(uint(cx), uint(cy - 1))); outV = asc ? max(selfV, o) : min(selfV, o); }
        } else {                                       // block diagonal contention (phase 0 EVEN, 3 ODD)
            const bool oddOff = (phase == 3u);
            int ox, oy;
            if (!oddOff) { ox = cx & ~1; oy = cy & ~1; }
            else         { ox = ((cx - 1) & ~1) + 1; oy = ((cy - 1) & ~1) + 1; }
            const bool valid = (ox >= 0) && (oy >= 0) && (ox + 1 < W) && (oy + 1 < H);
            if (valid) {
                const uint2 pNW = uint2(uint(ox),     uint(oy));
                const uint2 pNE = uint2(uint(ox + 1), uint(oy));
                const uint2 pSW = uint2(uint(ox),     uint(oy + 1));
                const uint2 pSE = uint2(uint(ox + 1), uint(oy + 1));
                const int vNW = cellByte(inTex, pNW), vNE = cellByte(inTex, pNE);
                const int vSW = cellByte(inTex, pSW), vSE = cellByte(inTex, pSE);
                const uint rNW = bandRank(pNW.x, pNW.y, HU), rNE = bandRank(pNE.x, pNE.y, HU);
                const uint rSW = bandRank(pSW.x, pSW.y, HU), rSE = bandRank(pSE.x, pSE.y, HU);

                // MAIN (NW-SE), ungated: inverted iff lower-rank NW holds larger tieKey
                // (tieKey = bandRank column-major, parity-corrected)
                const bool mainInv = edgeInverted(vNW, rNW, vSE, rSE);

                // ANTI (NE-SW), gated: swap strictly raises block match count vs local ideal
                int sv[4] = { vNW, vNE, vSW, vSE };
                for (int a = 0; a < 3; a++)
                    for (int b = 0; b < 3 - a; b++)
                        if (sv[b] > sv[b + 1]) { int t = sv[b]; sv[b] = sv[b + 1]; sv[b + 1] = t; }
                const uint rnk4[4] = { rNW, rNE, rSW, rSE };
                int posNE = 0, posSW = 0;
                for (int k = 0; k < 4; k++) { if (rnk4[k] < rNE) posNE++; if (rnk4[k] < rSW) posSW++; }
                const int idealNE = sv[posNE], idealSW = sv[posSW];
                const int mBefore = (vNE == idealNE ? 1 : 0) + (vSW == idealSW ? 1 : 0);
                const int mAfter  = (vSW == idealNE ? 1 : 0) + (vNE == idealSW ? 1 : 0);
                const bool antiViol = mAfter > mBefore;

                // choose at most one leg
                uint chosen = 0u;                                  // 0 none, 1 main, 2 anti
                if (mainInv && !antiViol)       chosen = 1u;
                else if (!mainInv && antiViol)  chosen = 2u;
                else if (mainInv && antiViol) {                    // contention -> fixed priority
                    const bool nwSmall = !warrenTieGreater(vNW, rNW, vSW, rSW);   // minLeft over {NW,SW}
                    const int  mlV = nwSmall ? vNW : vSW; const uint mlR = nwSmall ? rNW : rSW;
                    const bool neBig = warrenTieGreater(vNE, rNE, vSE, rSE);      // maxRight over {NE,SE}
                    const int  mrV = neBig ? vNE : vSE;  const uint mrR = neBig ? rNE : rSE;
                    chosen = warrenTieGreater(mrV, mrR, mlV, mlR) ? 1u : 2u;      // tieKey(minLeft)<tieKey(maxRight)->main
                }

                const bool isNW = (cx == ox && cy == oy),         isSE = (cx == ox + 1 && cy == oy + 1);
                const bool isNE = (cx == ox + 1 && cy == oy),     isSW = (cx == ox && cy == oy + 1);
                if (chosen == 1u) {
                    if (isNW)      outV = vSE;
                    else if (isSE) outV = vNW;
                } else if (chosen == 2u) {
                    if (isNE)      outV = vSW;
                    else if (isSW) outV = vNE;
                }
            }
        }

        const uint outHiC = (cx == 0 && cy == 0) ? ((counter + 1u) & 0xffffu) : 0u;
        outTex.write(packCell(outV, outHiC), ci);
        return;
    }

    // ---- v7 pairwise mutual diagonal (candO2 lineage) ----
    // 6-phase schedule : 0 mutual offset0, 1 H odd, 2 V odd, 3 mutual offset1, 4 H even,
    // 5 V even. Each interior cell has one main and one anti diagonal partner; a diagonal
    // edge commits iff both endpoints prefer it (mutual selection -> disjoint matching ->
    // conservation), no block partition. preferOf resolves a per-cell dual claim (cell
    // prefers both its diagonals) by fixed priority -- min-left/max-right tieKey bias
    // (value, then band position) -- identical rule at both endpoints so the match is
    // symmetric. History-resistance was measured unreachable in this rule class and
    // removed. Distinct from v6 (Margolus block, whole-block leg choice) and from v5
    // (H/V edge argmax, no diagonal). Race fixed point r/g/b = 3154/3082/3085 frames on
    // the zigular seed, conservative, endMism 0.
    if (version >= 6.5 && version < 7.5) {
        const int  W  = int(xs);
        const int  H  = int(ys);
        const int  cx = int(gid.x);
        const int  cy = int(gid.y);
        const uint counter = cellHiC(inTex, uint2(0, 0)) & 0xffffu;   // broadcast frame counter
        const uint phase   = counter % 6u;

        const int  selfV    = cellByte(inTex, gid);
        int  outV    = selfV;

        if (phase == 1u || phase == 4u) {              // H odd-even min-west finisher
            const int  par  = (phase == 1u) ? 1 : 0;
            const bool west = (cx - par >= 0) && (((cx - par) & 1) == 0) && (cx + 1 < W);
            const bool east = (cx - 1 - par >= 0) && (((cx - 1 - par) & 1) == 0);
            if (west)      outV = min(selfV, cellByte(inTex, uint2(uint(cx + 1), uint(cy))));
            else if (east) outV = max(selfV, cellByte(inTex, uint2(uint(cx - 1), uint(cy))));
        } else if (phase == 2u || phase == 5u) {       // V odd-even band-order finisher
            const int  par   = (phase == 2u) ? 1 : 0;
            const bool asc   = ((cx & 1) == 0);
            const bool north = (cy - par >= 0) && (((cy - par) & 1) == 0) && (cy + 1 < H);
            const bool south = (cy - 1 - par >= 0) && (((cy - 1 - par) & 1) == 0);
            if (north)      { int o = cellByte(inTex, uint2(uint(cx), uint(cy + 1))); outV = asc ? min(selfV, o) : max(selfV, o); }
            else if (south) { int o = cellByte(inTex, uint2(uint(cx), uint(cy - 1))); outV = asc ? max(selfV, o) : min(selfV, o); }
        } else {                                       // mutual diagonal pass (phase 0 offset0, 3 offset1)
            const uint offset = (phase == 3u) ? 1u : 0u;
            const uint myPref = preferOf(inTex, cx, cy, W, H, offset);
            if (myPref != 0u) {
                const bool low = (((cx + int(offset)) & 1) == 0);
                int px, py;
                if (myPref == 1u) { px = low ? cx + 1 : cx - 1; py = low ? cy + 1 : cy - 1; }
                else              { px = low ? cx + 1 : cx - 1; py = low ? cy - 1 : cy + 1; }
                if (px >= 0 && py >= 0 && px < W && py < H) {
                    const uint pPref = preferOf(inTex, px, py, W, H, offset);   // matching -> partner prefers self
                    if (pPref == myPref) {
                        outV = cellByte(inTex, uint2(uint(px), uint(py)));
                    }
                }
            }
        }

        const uint outHiC = (cx == 0 && cy == 0) ? ((counter + 1u) & 0xffffu) : 0u;
        outTex.write(packCell(outV, outHiC), ci);
        return;
    }

    // ---- v8 flight->measurement gas, rectangular axis lanes (packed single plane) ----
    // The full two-phase protocol on the packed half4: flight for the first (W+H)/2 frames
    // (reversible four-lane axis gas), then drain to one token per cell, then a local
    // mutual-best band route. (0,0) carries the broadcast counter and is frozen; its token is
    // pre-placed at the band target value by the harness. Collapse (one token per pixel, band
    // order) fires no comparator -> measurement fixed point.
    if (version >= 7.5 && version < 8.5) {
        const int W = int(xs), H = int(ys);
        const int x = int(gid.x), y = int(gid.y);
        const PkForm fm = pkFormRaw();                               // v8 keeps the original codes
        const int counter = pkCounter(inTex, false);
        const int flightLen = (W + H) / 2;
        const int drainLen = 2048;                                   // measured-correct rectangular drain
        const int nc = (counter + 1) & 0xffff;
        const int cLo = nc & 0xff, cHi = (nc >> 8) & 0xff;
        PkLanes L;
        if (counter < flightLen)                       L = pkFlight(inTex, 0, x, y, W, H, counter, fm);
        else if (counter < flightLen + drainLen)       L = pkDrainStep(inTex, x, y, W, H, counter - flightLen, fm);
        else                                           L = pkRouteLocal(inTex, x, y, W, H, counter - flightLen - drainLen, 3, fm);
        pkWrite(outTex, gid, L, cLo, cHi, fm);
        return;
    }

    // ---- v9 flight->measurement gas, polar diagonal lanes (packed single plane) ----
    // Same protocol on the diagonal gas; the diagonal flight returns to single occupancy at
    // flightLen so the drain is a short safety net, then a merge-exchange raster-sort plus one
    // forward-rank gather (pkRingRank arithmetic, no rank texture) reaches ring order (local
    // rules cannot). (0,0) rides its ring token in kept lane 1; measurement idempotent at collapse.
    if (version >= 8.5 && version < 9.5) {
        const int W = int(xs), H = int(ys);
        const int x = int(gid.x), y = int(gid.y);
        const int counter = pkCounter(inTex, true);                  // v9 stores its bytes at /255
        const int flightLen = (W + H) / 2;
        const int drainLen = 512;                                    // diagonal flight self-drains; short net
        const int routeAt = flightLen + drainLen;                    // first route frame
        const PkForm fLane = pkFormScaled(false);                    // flight and drain: scaled lanes
        const PkForm fRead = pkFormScaled(counter >  routeAt);       // route input is display one frame later
        const PkForm fPut  = pkFormScaled(counter >= routeAt);       // route and hold write display
        const int nc = (counter + 1) & 0xffff;
        const int cLo = nc & 0xff, cHi = (nc >> 8) & 0xff;
        PkLanes L;
        if (counter < flightLen)                       L = pkFlight(inTex, 1, x, y, W, H, counter, fLane);
        else if (counter < routeAt)                    L = pkDrainStep(inTex, x, y, W, H, counter - flightLen, fLane);
        else                                           L = pkRouteBatcher(inTex, x, y, W, H, counter - routeAt, 0, fRead);
        pkWrite(outTex, gid, L, cLo, cHi, fPut);
        return;
    }

    // ---- v10 perpetual pair-form sort, band target (drain + order, one pairing a frame) ----
    if (version >= 9.5 && version < 10.5) { dblStep(inTex, outTex, gid, 10, reseed); return; }

    // ---- v11 the same perpetual frame, circular ring target (quiesces short, holds) ----
    if (version >= 10.5) { dblStep(inTex, outTex, gid, 11, reseed); return; }

    uint2 ni, si, ei, wi;       // n s e w (unused by v1 but set by shared macro block)
    uint2 nwi, nei, sei, swi;   // nw ne se sw

    /** setup 8-neighbour indices -- NO WRAP!!! */ {
#define ew(ex,ey, wx,wy) ei=uint2(ex,ey); wi=uint2(wx,wy);
#define ns(nx,ny, sx,sy) ni=uint2(nx,ny); si=uint2(sx,sy);
#define nwsw(nwx,nwy, swx,swy) nwi=uint2(nwx,nwy); swi=uint2(swx,swy);
#define nese(nex,ney, sex,sey) nei=uint2(nex,ney); sei=uint2(sex,sey);
#define y gid.y
#define x gid.x
#define y1 ys-1
#define x1 xs-1
// this sets up hard walls -- NOT Toroid!
        if (x == 0) {
            ew(1, y, 0, y)
            if (y == 0) {
                ns  (0,0, 0,1)
                nwsw(0,0, 0,1)
                nese(1,0, 1,1)
            } else if (y == y1) {
                ns  (0,y1-1, 0,y1)
                nwsw(0,y1-1, 0,y1)
                nese(1,y1-1, 1,y1)
            } else {
                ns  (0,y-1, 0,y+1)
                nwsw(0,y-1, 0,y+1)
                nese(1,y-1, 1,y+1)
            }
        } else if (x == x1) {
            ew(x1, y, x1-1, y)
            if (y == 0) {
                ns  (x1  ,0, x1  ,1)
                nwsw(x1-1,0, x1-1,1)
                nese(x1  ,0, x1  ,1)
            } else if (y == y1) {
                ns  (x1  ,y1-1, x1  ,y1)
                nwsw(x1-1,y1-1, x1-1,y1)
                nese(x1  ,y1-1, x1  ,y1)
            } else {
                ns  (x1  ,y-1, x1  ,y+1)
                nwsw(x1-1,y-1, x1-1,y+1)
                nese(x1  ,y-1, x1  ,y+1)
            }
        } else {
            ew(x+1,y, x-1,y)
            if (y == 0) {
                ns  (x  ,0, x,  1)
                nwsw(x-1,0, x-1,1)
                nese(x+1,0, x+1,1)
            } else if (y == y1) {
                ns  (x,  y1-1, x,  y1)
                nwsw(x-1,y1-1, x-1,y1)
                nese(x+1,y1-1, x+1,y1)
            } else {
                ns  (x  ,y-1, x  ,y+1)
                nwsw(x-1,y-1, x-1,y+1)
                nese(x+1,y-1, x+1,y+1)
            }
        }
    }
    const half4 C   = inTex.read(ci);
    const half4 Cnw = inTex.read(nwi);
    const half4 Cne = inTex.read(nei);
    const half4 Cse = inTex.read(sei);
    const half4 Csw = inTex.read(swi);
    const int selfB = int(uint(C.b * 255. + 0.5));       // llc  (fallback value)

    const int nwB = int(uint(Cnw.b * 255. + 0.5));       // llnw
    const int neB = int(uint(Cne.b * 255. + 0.5));       // llne
    const int seB = int(uint(Cse.b * 255. + 0.5));       // llse
    const int swB = int(uint(Csw.b * 255. + 0.5));       // llsw

    // HiC low nibble of each diagonal neighbour  (hnw&0xf ...)  = last frame's winner flag
    const uint hnwN = ((uint(Cnw.a * 255. + 0.5) << 8) + uint(Cnw.r * 255. + 0.5)) & 0xfu;
    const uint hneN = ((uint(Cne.a * 255. + 0.5) << 8) + uint(Cne.r * 255. + 0.5)) & 0xfu;
    const uint hseN = ((uint(Cse.a * 255. + 0.5) << 8) + uint(Cse.r * 255. + 0.5)) & 0xfu;
    const uint hswN = ((uint(Csw.a * 255. + 0.5) << 8) + uint(Csw.r * 255. + 0.5)) & 0xfu;
    // squared-distance LUTs indexed by diagonal neighbour's HiC low nibble
    const int XNW[16] = {2,4,8,5,4,2,5,8,0,1,2,4,1,0,4,2};
    const int XNE[16] = {2,8,4,5,0,2,1,4,4,5,2,8,1,4,0,2};
    const int XSE[16] = {2,4,0,1,4,2,1,0,8,5,2,4,5,8,4,2};
    const int XSW[16] = {2,0,4,1,8,2,5,4,4,1,2,0,5,4,8,2};
    const int Xnw = XNW[hnwN];
    const int Xne = XNE[hneN];
    const int Xse = XSE[hseN];
    const int Xsw = XSW[hswN];

    // ---- v1 single-pass decision (Rule.cpp:793-822) ----
    int left = 0, leftX = 0;
    if      (nwB > swB) { left = nwB; leftX = Xnw; }
    else if (nwB < swB) { left = swB; leftX = Xsw; }
    else                { left = nwB; leftX = min(Xnw, Xsw); }

    // literal port of source if / if-else quirk (divergence #2)
    int right = 0, rightX = 0;
    if (neB < seB) { right = neB; rightX = Xne; }
    if (neB > seB) { right = seB; rightX = Xse; }
    else           { right = neB; rightX = min(Xse, Xne); }

    int r1;
    if      (leftX < rightX)                 r1 = left;   // shorter distance
    else if (leftX > rightX)                 r1 = right;
    else if (nwB == swB && neB != seB)       r1 = right;  // favour unique
    else if (nwB != swB && neB == seB)       r1 = left;
    else if (Xnw + Xsw < Xne + Xse)          r1 = left;   // shorter combined distance
    else if (Xnw + Xsw > Xne + Xse)          r1 = right;
    else                                     r1 = selfB;

    int r2 = (r1 == nwB ? 8 : 0)
           + (r1 == neB ? 4 : 0)
           + (r1 == seB ? 2 : 0)
           + (r1 == swB ? 1 : 0);

    // write: *next = r1 + (r2<<16)  -> .b=r1, .g=0, HiC=r2  (divergence #1)
    float fb = float(uint(r1) & 0xffu) / 255.;
    float fg = 0.0;
    float fr = float(uint(r2) & 0xffu) / 255.;   // HiC low byte = r2 (winner flag)
    float fa = 0.0;                              // HiC high byte = 0
    outTex.write(half4(fr, fg, fb, fa), ci);

}

// the v1 neighbour-setup block leaks object-like macros (x,y,x1,y1) to file scope;
// drop them so the gas kernels below can use x/y identifiers and .x/.y components.
#undef x
#undef y
#undef x1
#undef y1

// ============================================================================
// packed inverse flight kernels — reverse mode retargets to these live kernels
// (no dead forwards: the v8/v9 forwards are the warrenKernel branches above).
// candS8_inv undoes the v8 axis flight, candS9_inv the v9 diagonal flight, on the
// same packed single plane; they verify byte-exact reversibility of the flight
// window (counter < flightLen) by undoing rotation then inverse-shifting, with
// (0,0) frozen exactly as the forward flight leaves it.
// ============================================================================
kernel void candS8_inv
(
 texture2d<half, access::read>  inTex  [[ texture(0) ]],
 texture2d<half, access::write> outTex [[ texture(1) ]],
 constant float&                sel    [[ buffer(0)  ]],
 uint2 gid [[thread_position_in_grid]])
{
    (void)sel;
    const int W = int(outTex.get_width());
    const int H = int(outTex.get_height());
    const int x = int(gid.x), y = int(gid.y);
    const PkForm fm = pkFormRaw();                            // v8 keeps the original codes
    const int counterIn = pkCounter(inTex, false);
    const int c = counterIn - 1;                              // counter of the frame being undone
    PkLanes L = pkInvFlight(inTex, 0, x, y, W, H, c, fm);
    const int nc = (counterIn - 1) & 0xffff;
    pkWrite(outTex, gid, L, nc & 0xff, (nc >> 8) & 0xff, fm);
}

kernel void candS9_inv
(
 texture2d<half, access::read>  inTex  [[ texture(0) ]],
 texture2d<half, access::write> outTex [[ texture(1) ]],
 constant float&                sel    [[ buffer(0)  ]],
 uint2 gid [[thread_position_in_grid]])
{
    (void)sel;
    const int W = int(outTex.get_width());
    const int H = int(outTex.get_height());
    const int x = int(gid.x), y = int(gid.y);
    const PkForm fm = pkFormScaled(false);                    // reverse mode is flight only -> lane form
    const int counterIn = pkCounter(inTex, true);
    const int c = counterIn - 1;
    PkLanes L = pkInvFlight(inTex, 1, x, y, W, H, c, fm);
    const int nc = (counterIn - 1) & 0xffff;
    pkWrite(outTex, gid, L, nc & 0xff, (nc >> 8) & 0xff, fm);
}

