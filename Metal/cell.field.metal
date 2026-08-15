// cell.field.metal
// ============================================================================
// WinSky "Field" subsystem -- live shortlist (fieldShort.sky.h, 24 fields).
// Ported from Port/Expanded/fieldShort.expanded.cpp (source of truth for the
// math) and pixel/Field.cpp / pixel/FieldFunc.cpp (WinSky, READ-ONLY
// reference, consulted only to resolve the exact blend/wrap contract that
// Port/CallTree.md paraphrases but does not give verbatim -- see
// Port/B4.fields.notes.md for the full writeup and every divergence).
//
// ---- the one fact that shapes this whole file ----
// A "field" is NOT a per-frame animation. It is a per-pixel coordinate WARP
// (a lookup table mapping every destination pixel to a SOURCE pixel) that is
// baked ONCE when the field selection changes, then re-applied every frame
// to whatever is already on screen. Apparent motion comes entirely from
// feeding a changing image through a fixed warp, not from re-evaluating the
// field math per frame. Consequently this file is deliberately TWO kernels:
//
//   fieldMapKernel   -- host-triggered ONLY on algo/param/seed change.
//                       Evaluates the selected field function per pixel and
//                       bakes the resolved SOURCE PIXEL COORDINATE into
//                       mapTex. This is the expensive, rarely-run pass.
//   fieldApplyKernel -- every frame. Pure table lookup + blend, no field
//                       math at all. This is the cheap, always-run pass.
//
// See Port/B4.fields.notes.md for: map texture format rationale, exact
// FieldUniforms byte layout, the host regen contract (when fieldMapKernel
// must be re-dispatched), the algo -> field-name table, and per-field a[]/d[]
// usage.
// ============================================================================

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

// ----------------------------------------------------------------------------
// FieldUniforms -- buffer(0), shared by both kernels.
// Swift mirror MUST match this layout exactly (see notes.md for the byte
// table). Total size 80 bytes.
//
//   offset  0   uint  algo       fieldMapKernel: field selector, 0...23
//   offset  4   uint  seed       fieldMapKernel: per-pixel rnd() seed
//                                (consumed only by algo 0/8/18 -- see notes);
//                                bump ONLY on regen, never per frame
//   offset  8   float fadeGain   fieldApplyKernel: WinSky fader.v()/10000.0,
//                                linear gain applied to the warped sample
//   offset 12   float _pad0      explicit pad -- keeps a[] 16-byte aligned
//   offset 16   float a[16]      fieldMapKernel setup constants, HOST-
//                                populated once per regen (literal or
//                                rnd()-seeded per field -- see notes.md);
//                                d[16] is NOT here -- it is per-pixel
//                                kernel-local scratch, see fieldMapKernel body
// ----------------------------------------------------------------------------
struct FieldUniforms
{
    uint  algo;
    uint  seed;
    float fadeGain;
    float _pad0;
    float a[16];
};

// ---- WinSky pixel/Field.cpp local PI (float, not the double used by waves) ----
constant float kFieldPI = 3.14159265358979f;

// ---- pixel/FieldFunc.cpp helpers, ported verbatim (names preserved for
//      1:1 cross-reference against Port/Expanded/fieldShort.expanded.cpp) ----
inline float dabs(float n)               { return n < 0.0 ? -n : n; }
inline float fsqr(float n)               { return n * n; }
inline float trnc(float n)               { return trunc(n); }
inline float flor(float n)               { return floor(n); }
inline float fwrap(float x)              { return x - flor(x); }
inline float fclip(float n)              { return clamp(n, 0.0, 1.0); }
inline float fpos(float n)               { return n > 0.0 ? n : 0.0; }
inline float fsgn(float x)               { return x < 0.0 ? -1.0 : 1.0; }
inline float ftrwv(float x)              { float m = fmod(x, 2.0); return m > 1.0 ? 2.0 - m : m; }
inline float fsaw(float x)               { float m = fmod(x, 2.0) - 2.0; return m < -1.0 ? m + 2.0 : m; }
inline float fsqwv(float x)              { return dabs(x) < 1.0 ? 1.0 : 0.0; }

// pixel/Field.cpp Field::PiPos -- wrap to [0, 2*PI)
inline float piPos(float v)
{
    float r = fmod(v, kFieldPI * 2.0);
    if (r < 0.0) r += kFieldPI * 2.0;
    return r;
}

// ---- deterministic per-pixel rnd() replacement -----------------------------
// WinSky's rnd(range) is libc rand()/RAND_MAX, a single global stream
// advanced once per call and reseeded via srand(time(NULL)) at Field::Field()
// construction. That model is unportable to a parallel per-pixel kernel: a
// GPU thread cannot "advance a shared stream". Field bodies that call rnd()
// INSIDE the per-pixel Go*() expression (only algo 0 / 8 / 18 in the live 24
// -- see notes.md) instead hash (seed, algo, gid, call-site slot) into a
// well-mixed 32-bit value and rescale to [0,range). Same qualitative
// contract as the original (uniform, spatially frozen for the field's whole
// display duration because it only runs inside fieldMapKernel), bit-different
// values, reseed model is an explicit `seed` field bumped by the host on
// regen instead of wall-clock srand(). This is the ONLY place per-pixel
// randomness happens in this file; setup-time rnd() (a[] constants) is
// computed once, host-side, and arrives already-resolved in FieldUniforms.a[]
// -- see notes.md "host regen contract".
inline uint fieldHashU(uint x)
{
    x ^= x >> 16u; x *= 0x7feb352du;
    x ^= x >> 15u; x *= 0x846ca68bu;
    x ^= x >> 16u;
    return x;
}
inline float fieldRndPixel(uint seed, uint algo, uint2 gid, uint slot, float range)
{
    uint key = seed
             ^ (algo    * 0x9E3779B9u)
             ^ (gid.x   * 0x85EBCA6Bu)
             ^ (gid.y   * 0xC2B2AE35u)
             ^ (slot    * 0x27D4EB2Fu);
    uint  h   = fieldHashU(key);
    float u01 = float(h) * (1.0 / 4294967296.0); // [0,1)
    return u01 * range;
}

// ============================================================================
// fieldMapKernel -- REGEN ONLY (algo change / param change / seed reroll).
// Evaluates the selected field's Go*() body once per destination pixel and
// bakes the resolved SOURCE PIXEL coordinate (integer, toroidally wrapped,
// exactly mirroring Field::setFxy()) into mapTex as (xPos, yPos) floats.
//
// algo -> WinSky fieldShort.sky.h field name (see notes.md for full table
// with a[]/d[] usage, aspect, and author credit per field):
//   0 Ether Leak            6 Poinsetta            12 Five Hole          18 Smoke in the Mist
//   1 Uber Incognito        7 Psilocybin Growth     13 Gedenghi           19 Uber Concert
//   2 Gevian Rage              Formulae             14 Unfolding          20 6 Ft. Under
//   3 Disco Ball            8 Star of David            Before You)       21 g-life
//   4 D_Julia B             9 Strangeitude          15 Acid Flower        22 Tripping Hard
//   5 Hip-no-Therapy       10 Warpo Tunnel          16 Collapsing Sun     23 Lens Flare
//                          11 Watery Ripples        17 Pscyco Linear
//                                                       Spread
// ============================================================================
kernel void fieldMapKernel
(
 texture2d<float, access::write> mapTex [[ texture(0) ]],   // output: baked source-coordinate map (rg32Float)
 constant FieldUniforms&         u      [[ buffer(0)  ]],
 uint2 gid [[thread_position_in_grid]])
{
    const uint W = mapTex.get_width();
    const uint H = mapTex.get_height();
    if (gid.x >= W || gid.y >= H) return;

    // ---- pixel/Field.cpp ForXY(A): x in [-aspectGrid,aspectGrid], y in [-1,1] ----
    // aspectGrid = xs/ys of the GRID itself (Field::xya), NOT the per-field
    // `Aspect` argument baked into each Go*() call -- confirmed by reading
    // Field.cpp: the per-field Aspect only sets the unused `this->aspect`
    // member; it does not touch the ForXY loop bounds. See notes.md.
    const float aspectGrid = float(W) / float(H);
    const float xi = 2.0 * aspectGrid / float(W);
    const float yi = 2.0 / float(H);
    const float x = -aspectGrid + float(gid.x) * xi;
    const float y = 1.0 - float(gid.y) * yi;

    // ---- pixel/Field.cpp Field::calcRT(): precomputed once per grid ----
    const float radius = sqrt(x * x + y * y);
    const float theta  = piPos(atan2(y, x));

    // d[16] -- feedback/delta channels, LOCAL to this pixel's evaluation,
    // exactly like WinSky's `float d[16]` local to Field::calcMap(). Only
    // algo 9 (Strangeitude) uses d[0] in the live 24; the rest never touch it.
    float d[16] = { 0.0 };

    float outA = 0.0, outB = 0.0;   // polar: (sourceR,sourceT); Cartesian: (sourceX,sourceY)
    bool  polar = false;

    switch (u.algo)
    {
    // ---- 0: Ether Leak (Jay Protopapas) -- GoRT, per-pixel rnd() ----
    case 0:
        outA = radius * fclip(1.57 + 1.256 * sin(fsgn(0.057 - sin(radius))));
        outB = theta - sqrt(flor(fieldRndPixel(u.seed, u.algo, gid, 0, 1.00999)));
        polar = true;
        break;

    // ---- 1: Uber Incognito (Uberbach) -- GoXY -- a[0]=0.0625 a[1]=16.8 ----
    case 1:
        outA = flor(x * u.a[1] + 0.5) * u.a[0];
        outB = flor(y * u.a[1] + 0.5) * u.a[0];
        polar = false;
        break;

    // ---- 2: Gevian Rage (Demonseed) "Donut" -- GoRT, no a[] ----
    case 2:
        outA = radius - sin(0.24 * fclip(6.2 * (radius - 0.3005))) - 0.048 * radius;
        outB = theta - 0.05;
        polar = true;
        break;

    // ---- 3: Disco Ball (Doug Fawley) "Burst" -- GoRT -- a[0..2] rnd-seeded ----
    case 3:
        outA = u.a[1] * trnc(radius * u.a[0]) / u.a[0];
        outB = theta - u.a[2];
        polar = true;
        break;

    // ---- 4: D_Julia B (Mats Nordstrom) -- GoXY, no a[] (Julia-set iteration) ----
    case 4:
        outA = x * x - y * y - 0.194;
        outB = 2.0 * x * y - 0.6557;
        polar = false;
        break;

    // ---- 5: Hip-no-Therapy -- GoRT, no a[] ----
    case 5:
        outA = radius * 0.92;
        outB = theta - 0.090;
        polar = true;
        break;

    // ---- 6: Poinsetta (Demonseed) "Boxilite" -- GoRT -- a[0]=32 a[1]=0.01 ----
    case 6:
        outA = radius + u.a[1] * sin(u.a[0] * theta);
        outB = theta + u.a[1] * sin(u.a[0] * radius);
        polar = true;
        break;

    // ---- 7: Psilocybin Growth Formulae (Erich Kodotai) -- GoRT --
    //         a[0]=120.113 a[1]=1+rnd(.146517) a[2]=a[0]/a[1] ----
    case 7:
        outA = radius + fwrap(radius) * (0.01 * cos(x * u.a[0]) - 0.0120);
        outB = theta + 0.0127 * cos(y * u.a[2]);
        polar = true;
        break;

    // ---- 8: Star of David (Jay Protopapas) -- GoRT -- a[0]=-1.1883951,
    //         per-pixel rnd() ----
    case 8:
        outA = radius - fieldRndPixel(u.seed, u.algo, gid, 0, 0.05);
        outB = fwrap(0.955 * theta + 0.005) * u.a[0];
        polar = true;
        break;

    // ---- 9: Strangeitude (Erlend Robaye) -- GoDRT, 1 feedback channel --
    //         a[0]=rnd(.004)+.004 a[1]=rnd(200)+50 ----
    case 9:
        d[0] = sin(theta * u.a[1]);
        outA = radius * (1.0 + d[0] * 0.02);
        outB = theta + d[0] * u.a[0];
        polar = true;
        break;

    // ---- 10: Warpo Tunnel (Chris Sherrill) "mysterious puddle" -- GoRT, no a[] ----
    case 10:
        outA = cos(atan(radius));
        outB = theta - 0.1 / (radius + 0.0001);
        polar = true;
        break;

    // ---- 11: Watery Ripples -- GoRT, no a[] ----
    case 11:
        outA = radius - 0.01;
        outB = theta + 0.01 * (cos(41.0 * radius) + cos(29.0 * radius));
        polar = true;
        break;

    // ---- 12: Five Hole (Jay Protopapas) -- GoRT -- a[0]=rnd(31.4)+12.56
    //          a[1]=rnd(.0628)+.0314 ----
    case 12:
        outA = sin(radius * fsqr(1.0 - fclip(radius * sin(u.a[1]))));
        outB = ftrwv(theta + sin(atan(theta * flor(u.a[0])) * 0.1));
        polar = true;
        break;

    // ---- 13: Gedenghi (Erlend Robaye) -- GoRT -- a[0]=rnd(.004)+.002
    //          a[1]=rnd(30)+8 a[2]=rnd(16)+4 a[3]=2*PI*a[2] ----
    case 13:
        outA = radius * (1.0 + fsgn(sin(theta * u.a[1])) * 0.01);
        outB = theta + u.a[0] * fsgn(sin(radius * u.a[3]));
        polar = true;
        break;

    // ---- 14: Unfolding Before You) (Jay Protopapas) -- GoRT --
    //          a[0]=8+trnc(rnd(7.5)) a[1]=rnd(.05)-.075 ----
    case 14:
        outA = radius + u.a[1] * cos(theta * u.a[0]);
        outB = kFieldPI - u.a[1] * cos(radius * u.a[0] + 7.5);
        polar = true;
        break;

    // ---- 15: Acid Flower -- GoRT -- a[0]=rnd(.05)+.001 a[1]=rnd(40)+5
    //          a[2]=rnd(.05)+.01 ----
    case 15:
        outA = radius + u.a[0] * sin(theta * 8.0);
        outB = theta + u.a[2] * sin(radius * u.a[1]);
        polar = true;
        break;

    // ---- 16: Collapsing  Sun (Chris Sherrill) -- GoRT -- a[0]=sgn(rnd(.2)-.1) ----
    case 16:
        outA = radius + 0.001;
        outB = theta * 2.0 + 0.5 * (u.a[0] * (0.001 + radius));
        polar = true;
        break;

    // ---- 17: Pscyco Linear Spread (Chris Sherrill) -- GoXY, no a[] ----
    case 17:
        outA = y * 0.98;
        outB = x * 0.98;
        polar = false;
        break;

    // ---- 18: Smoke in the Mist (Chris Sherrill) -- GoXY, per-pixel rnd() x2 ----
    case 18:
        outA = sin(x)        + fieldRndPixel(u.seed, u.algo, gid, 0, 0.03) - 0.015;
        outB = sin(y) * 0.95 + fieldRndPixel(u.seed, u.algo, gid, 1, 0.03) - 0.015;
        polar = false;
        break;

    // ---- 19: Uber Concert (Uberbach) -- GoXY -- a[0]=rnd(100)+2 ----
    case 19:
        outA = x + (0.01 / (sqrt(dabs(x)) + 0.0001)) * sin(x);
        outB = y + sin(x * y * u.a[0]) / 100.0;
        polar = false;
        break;

    // ---- 20: 6 Ft. Under (Demonseed) -- GoXY -- a[0]=1/.7 ----
    case 20:
        outA = tan(0.7 * x) * u.a[0];
        outB = tan(0.7 * y) * u.a[0];
        polar = false;
        break;

    // ---- 21: g-life (Jay Protopapas) "Alife" -- GoXY --
    //          a[0]=rnd(28) a[1]=rnd(.07536) a[2]=4.39749*rnd(6.28) a[3]=rnd(.1256) ----
    case 21:
        outA = ftrwv(x + u.a[1] * sin(u.a[2] * y));
        outB = ftrwv(y + u.a[3] * sin(u.a[0] * x));
        polar = false;
        break;

    // ---- 22: Tripping Hard (Justin Swidler) -- GoRT, no a[] ----
    case 22:
        outA = radius * 0.66;
        outB = theta - 0.201;
        polar = true;
        break;

    // ---- 23: Lens Flare (Steve Wheeler) -- GoRT -- a[0]=1/sin(.1) a[1]=cos(.630) ----
    default: // case 23, and any out-of-range algo falls back to Lens Flare's shape
        outA = u.a[1] * radius;
        outB = u.a[0] * theta;
        polar = true;
        break;
    }

    // ---- pixel/Field.cpp Field::setXY / setRT / setXYRT / setFxy ----
    float fromX, fromY;
    if (polar)
    {
        float T = piPos(outB);
        fromX = outA * cos(T);
        fromY = outA * sin(T);
    }
    else
    {
        fromX = outA;
        fromY = outB;
    }

    // Field::setFxy(X,Y) -- toroidal wrap to an integer source pixel index.
    // Ported literally (truncate-toward-zero + single modulo correction, same
    // as WinSky) rather than a floor-based wrap, to stay bit-faithful; every
    // one of the 24 live field bodies keeps fromX/fromY bounded to roughly
    // [-2,2] so a single correction is always sufficient in practice (see
    // notes.md). isfinite() guards the theoretical NaN/Inf case WinSky's own
    // (int) cast would hit undefined behavior on; no live field triggers it.
    int xPos, yPos;
    if (isfinite(fromX) && isfinite(fromY))
    {
        xPos = int((fromX + 1.0) * 0.5 * float(W)) % int(W);
        if (xPos < 0) xPos += int(W);
        yPos = int((-fromY + 1.0) * 0.5 * float(H)) % int(H);
        if (yPos < 0) yPos += int(H);
    }
    else
    {
        xPos = int(gid.x);
        yPos = int(gid.y);
    }

    mapTex.write(float4(float(xPos), float(yPos), 0.0, 0.0), gid);
}

// ============================================================================
// fieldApplyKernel -- EVERY FRAME. Pure table lookup + blend; no field math,
// no rnd(), no trig. Mirrors pixel/Field.cpp Field::go()'s inner loop:
//
//   val1 = fade[ fo[ fxy[i] ] ]     // warped sample of the previous buffer,
//                                   //   run through the linear fader gain
//   val2 = *pix                    // this frame's fresh incoming pixel
//   ret  = (val1 + val2) >> 1      // flat 2-tap average
//
// fade[i] = min(255, i*fader.v()/10000.0) is LINEAR (a clamp(x*gain,0,255)
// gain curve, not an arbitrary LUT), so it is reproduced here as a direct
// multiply-and-clamp against `fadeGain` rather than a baked 256-entry table
// -- see notes.md "fade[] linearity" for the derivation.
//
// WinSky reads val1/val2 from two logically distinct buffers: buf[prev]
// (the field's own feedback history) and main.pic.mix (this frame's fresh
// camera+draw composite). DeepMuse's pipe.cell chain already conflates
// those two roles into one texture (pipe.cell.real is simultaneously "what's
// there now" and, through the draw/camera feedback loop, "last frame's
// output") for every other cell rule in this codebase -- see notes.md
// "blend contract mapping" for the full justification. prevTex is therefore
// sampled TWICE here: once through the warp (the decayed-feedback term),
// once directly at gid (the fresh-incoming term).
// ============================================================================
kernel void fieldApplyKernel
(
 texture2d<float, access::read>  mapTex  [[ texture(0) ]],   // baked source-coordinate map (written by fieldMapKernel)
 texture2d<half,  access::read>  prevTex [[ texture(1) ]],   // previous / incoming cell texture (pipe.cell.real)
 texture2d<half,  access::write> outTex  [[ texture(2) ]],   // next cell texture (pipe.cell.out)
 constant FieldUniforms&         u       [[ buffer(0)  ]],
 uint2 gid [[thread_position_in_grid]])
{
    const uint W = outTex.get_width();
    const uint H = outTex.get_height();
    if (gid.x >= W || gid.y >= H) return;

    const float2 srcF = mapTex.read(gid).xy;
    const uint2  srcCoord = uint2(clamp(srcF, float2(0.0), float2(float(W) - 1.0, float(H) - 1.0)));

    const half4 warped   = prevTex.read(srcCoord);   // fo[fxy[i]] -- nearest, pre-wrapped at bake time
    const half4 incoming = prevTex.read(gid);        // *pix -- this frame's fresh, un-warped pixel

    const half4 val1 = clamp(warped * half(u.fadeGain), 0.0h, 1.0h);  // fade[] linear-gain reproduction
    const half4 ret  = clamp((val1 + incoming) * 0.5h, 0.0h, 1.0h);   // (val1+val2)>>1

    outTex.write(ret, gid);
}
