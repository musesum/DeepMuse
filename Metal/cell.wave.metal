#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

// ============================================================================
// cell.wave.metal -- WinSky Waves subsystem (live shortlist) ported to a
// Metal SCATTER compute kernel. See Port/B3.waves.notes.md for the full
// uniform-layout table, algo->shape-name catalog, and documented divergences.
//
// DESIGN SUMMARY (binding, see Port/CallTree.md "Waves and Fields" + task
// brief for full rationale):
//   - GATHER kernels (cell.rule.*.metal) dispatch one thread per PIXEL.
//     This kernel dispatches one thread per POINT: 1D grid of `uniforms.num`
//     threads. Each thread evaluates ONE (instance, step) pair of the
//     selected wave shape and scatter-writes up to a handful of points into
//     the shared cell texture.
//   - Thread -> (instance, step) decomposition: STEPS is a per-shape
//     constant (see algoSteps() below, sourced from the WinSky catalog).
//     stepIdx = gid % STEPS, instIdx = gid / STEPS, s = stepIdx/(STEPS-1),
//     id = float(instIdx), numF = max(1, floor(uniforms.num / STEPS)).
//     Host controls live instance count simply by setting uniforms.num to a
//     multiple of STEPS; setting num == STEPS gives exactly the source's
//     single-instance behavior.
//   - Divergence (documented, binding per task brief): overwrite races
//     between threads targeting the same output pixel are accepted
//     (last-write-wins), matching the sequential-overdraw semantics of the
//     source's per-frame point/line rasterizer. connect==1 polylines from
//     the source degrade to independent dot scatter (no inter-thread line
//     rasterization); draw()'s `width` argument is dropped (no stroke
//     thickness); `color` maps to the written cell intensity.
//   - In-place read_write texture (NOT the dual read/write-texture gather
//     convention of Integration.md): a scatter kernel only touches the
//     handful of pixels it draws this dispatch, so it must read-modify-write
//     the SAME texture the rest of the pipeline already holds, rather than
//     writing a fresh full-frame texture the CellNode ping-pong assumes.
//     See notes for the host-integration implication.
//   - rnd(n) -> deterministic hash of (instance id, algo, uniforms.seed,
//     a per-call-site counter); frame-stable for a given instance+seed, so
//     shape "constants" chosen once at selection in the source look stable
//     here too, and reroll on shape-select just by bumping uniforms.seed.
//   - Source patterns of the form `a[0]=t; ... (t-a[0]) ...` capture a
//     "time since this shape was selected" anchor in the source (a[] persists
//     across frames once set at selection). Recomputing a[] fresh every
//     frame would collapse (t-a[0]) to always 0, so those specific shapes
//     use uniforms.selectT (a value the host must set to `t` only when algo
//     changes) in place of `t` for that one anchor read. See notes for the
//     shape list.
//   - beat() -> constant 1.0 (stub, matches source's WaveSky::beat()).
//   - mag(s)/fft(s) index into buffer(1)/buffer(2), clamped by
//     uniforms.magCount/fftCount; both read as 0 with a zero-length/absent
//     buffer (no MuAudio tap exists yet -- see Port/Stubs.md).
//   - sampleSteps()/sampleSlots()/fftSlots()/fftSteps() are structural
//     buffer-size accessors in the source (not live signal); baked to the
//     kSampleSteps/kFftSlots constants below pending a real audio tap.
// ============================================================================

// ---- WaveUniforms: buffer(0). Byte layout is authoritative -- mirror
// exactly in the Swift uniform struct. All fields are `float` (cast to
// int/uint in-kernel where needed), 4-byte aligned, no padding.
struct WaveUniforms
{
    float algo;      // offset 0  - shape select, 0..67 (int(algo); see algoSteps()/notes table)
    float t;         // offset 4  - elapsed seconds (matches source `t`)
    float num;       // offset 8  - total 1D dispatch thread count this frame (points to evaluate)
    float ux;        // offset 12 - UI slider X (source `ux`)
    float uy;        // offset 16 - UI slider Y (source `uy`)
    float ur;        // offset 20 - UI slider R (source `ur`)
    float ua;        // offset 24 - UI slider A (source `ua`)
    float seed;      // offset 28 - rnd() reseed key; host bumps whenever algo changes
    float selectT;   // offset 32 - `t` value at the last algo change (selection-time anchor)
    float magCount;  // offset 36 - valid element count in the mag buffer (0 = silent/no tap)
    float fftCount;  // offset 40 - valid element count in the fft buffer (0 = silent/no tap)
};                   // total size: 44 bytes

// ---- structural buffer-size stand-in (see header note above). fftSlots()/
// sampleSlots()/fftSteps() all bake to this same representative constant;
// STEPS-only uses (Steps()==fftSlots() etc.) are baked directly as literals
// in algoSteps() below instead (see per-case comments there). ----
constant float kSampleSteps = 1024.0; // ~ WaveSky::samPerBuf, no live tap yet

// pixel/Waveshapes.cpp uses the double-precision constant for waves (as opposed
// to Field.cpp's separate float PI); MSL has no double, so this is the closest
// float representation -- see main/Defs.h in the notes for the source dual-PI callout.
constant float PI = 3.14159265358979323846;

// ---- deterministic per-thread hash-based rnd()/seed() ----
inline uint wsHashCombine(uint a, uint b)
{
    a ^= b + 0x9e3779b9u + (a << 6) + (a >> 2);
    return a;
}
inline float wsHash01(uint x)
{
    x ^= x >> 16; x *= 0x7feb352du;
    x ^= x >> 15; x *= 0x846ca68bu;
    x ^= x >> 16;
    return float(x) * (1.0 / 4294967296.0);
}
// Replaces source rnd(range): deterministic per (instance, algo, seed, call-site).
inline float wsRnd(uint instIdx, int algo, float seedF, thread uint &rc, thread uint &rfold, float range)
{
    uint h = wsHashCombine(instIdx, uint(algo) * 2654435761u);
    h = wsHashCombine(h, as_type<uint>(seedF));
    h = wsHashCombine(h, rfold);
    h = wsHashCombine(h, rc);
    rc += 1u;
    return wsHash01(h) * range;
}
// Replaces source seed(x): folds x into the rnd() chain instead of reseeding libc rand().
inline float wsSeed(float x, thread uint &rfold)
{
    rfold = wsHashCombine(rfold, as_type<uint>(x));
    return x;
}

// ---- pixel/FieldFunc.cpp DSL helpers, exact semantics (WinSky read-only ref) ----
inline float ws_dabs(float n) { return n < 0.0 ? -n : n; }
inline float ws_sqr(float n)  { return n * n; }
inline float ws_trnc(float n) { return trunc(n); }
inline float ws_flor(float n) { return floor(n); }
inline float ws_wrap(float x) { return x - floor(x); }
inline float ws_clip(float n) { return clamp(n, 0.0, 1.0); }
inline float ws_pos(float n)  { return n > 0.0 ? n : 0.0; }
inline float ws_sgn(float x)  { return x < 0.0 ? -1.0 : 1.0; }
inline float ws_trwv(float x) { float m = fmod(x, 2.0); return (m > 1.0) ? (2.0 - m) : m; }
inline float ws_saw(float x)  { float m = fmod(x, 2.0) - 2.0; if (m < -1.0) m += 2.0; return m; }
inline float ws_sqwv(float x) { return (fabs(x) < 1.0) ? 1.0 : 0.0; }

// ---- audio taps: buffer(1)=mag, buffer(2)=fft, count-clamped, zero-safe ----
inline float wsMag(constant float *buf, float countF, float s)
{
    uint count = uint(max(countF, 0.0));
    if (count == 0u) return 0.0;
    float cf = clamp(s, 0.0, 1.0) * float(count - 1u);
    uint idx = min(uint(cf + 0.5), count - 1u);
    return buf[idx];
}
inline float wsFft(constant float *buf, float countF, float s)
{
    uint count = uint(max(countF, 0.0));
    if (count == 0u) return 0.0;
    float cf = clamp(s, 0.0, 1.0) * float(count - 1u);
    uint idx = min(uint(cf + 0.5), count - 1u);
    return buf[idx];
}
inline float wsBeat() { return 1.0; }
inline float wsTimeEnd(constant WaveUniforms &u) { return u.selectT + 1200.0; }

// ---- scatter write: same .b/.g/.r+.a HiC packing as cell.rule.*.metal ----
// px,py are normalized device coords, roughly -1..1 (source convention);
// aspect is treated as a no-op (destination canvas is always square).
// Out-of-canvas / non-finite points are silently clipped (no wraparound).
// Split read(0)/write(1) args (host binds the SAME pipe.cell.out to both):
// bgra8Unorm is not a Metal read-write format, so a single access::read_write
// arg fails validateComputeFunctionArguments; separate shaderRead+shaderWrite
// bindings are legal. Each thread reads then writes only its own point.
inline void wsWritePoint(texture2d<half, access::read> texIn,
                         texture2d<half, access::write> texOut,
                         float px, float py, float value)
{
    if (!isfinite(px) || !isfinite(py) || !isfinite(value)) return;
    float u = px * 0.5 + 0.5;
    float v = 0.5 - py * 0.5; // y-up NDC -> top-left-origin texture row order
    if (u < 0.0 || u > 1.0 || v < 0.0 || v > 1.0) return;
    uint W = texIn.get_width();
    uint H = texIn.get_height();
    uint2 p = uint2(min(uint(u * float(W)), W - 1u), min(uint(v * float(H)), H - 1u));
    half4 prev = texIn.read(p);
    uint HiC = (uint(prev.a * 256.0) << 8) + uint(prev.r * 256.0);
    uint r1 = uint(clamp(value, 0.0, 1.0) * 255.0);
    uint r2 = 255u - r1;
    uint r3 = HiC + (r1 & 0x03u);
    half4 outv = half4(float(r3 & 0xffu) / 256.0, float(r2) / 256.0, float(r1) / 256.0, float(r3 >> 8) / 256.0);
    texOut.write(outv, p);
}

// ---- algo -> STEPS (per-shape point-loop resolution/thread-per-instance count) ----
// Full algo->name table lives in Port/B3.waves.notes.md. -1 sentinel shapes
// resolve to 300 (Steps(-1) rule, pixel/Waveshapes.cpp). Shapes whose STEPS
// depends on rnd()/id/sampleSlots() etc. in source bake a representative
// literal here (documented per-case in the notes file).
inline uint algoSteps(int algo)
{
    switch (algo) {
        case 0: return 100u;   // Pair
        case 1: return 150u;   // Dancing_Days
        case 2: return 120u;   // Five
        case 3: return 100u;   // Big_and_Banded
        case 4: return 100u;   // Big_and_Banded2
        case 5: return 512u;   // HAL_Splashy_Scope (sampleSlots() baked)
        case 6: return 11u;    // Cycling_Dots
        case 7: return 20u;    // CircWarp
        case 8: return 720u;   // Dense_Spiral
        case 9: return 300u;   // Hourglass (Steps(-1))
        case 10: return 68u;   // DT_SineDot
        case 11: return 9u;    // Pollock_Spectagon
        case 12: return 80u;   // Uber_Aurora
        case 13: return 5u;    // Spectagon
        case 14: return 500u;  // I_Declare
        case 15: return 100u;  // Align
        case 16: return 100u;  // Arena
        case 17: return 100u;  // Critters
        case 18: return 512u;  // Cylinder
        case 19: return 300u;  // Dans_Furathama (Steps(-1))
        case 20: return 512u;  // Father_and_Daughters (fftSlots() baked)
        case 21: return 32u;   // Lightning_Strikes
        case 22: return 160u;  // Moving
        case 23: return 512u;  // Radar_Sweep
        case 24: return 300u;  // Rotating_Arcs (Steps(-1))
        case 25: return 30u;   // Rotating_Bars
        case 26: return 512u;  // Rotating_X
        case 27: return 512u;  // Simple_Horizontal
        case 28: return 512u;  // Simple_Vertical
        case 29: return 512u;  // Sing_Me_to_Sleep (fftSlots() baked)
        case 30: return 10u;   // SM_Spectometer
        case 31: return 512u;  // SOLs_Vinyl
        case 32: return 512u;  // Spin_Doctor
        case 33: return 512u;  // SpinIt
        case 34: return 512u;  // The_Eye
        case 35: return 128u;  // Threes_A_Crowd
        case 36: return 1024u; // Thunderation (2*fftSlots() baked)
        case 37: return 512u;  // Wave
        case 38: return 300u;  // Darren_Doublehelix (Steps(-1))
        case 39: return 3u;    // DT_Spectrum
        case 40: return 512u;  // DT_Wild
        case 41: return 300u;  // Splutterbug (Steps(-1))
        case 42: return 55u;   // Orbiting_Stars
        case 43: return 512u;  // Sci_Fi_Expander
        case 44: return 512u;  // Simple_Sine
        case 45: return 512u;  // Tension_II (fftSlots() baked)
        case 46: return 512u;  // Walls_of_Sound (fftSlots() baked)
        case 47: return 12u;   // Sparkling_Table_Water
        case 48: return 8u;    // Solala (5+rnd(5) baked representative)
        case 49: return 16u;   // Rotating_Pulsating_Oval
        case 50: return 2u;    // Colliders
        case 51: return 300u;  // Dancing_String
        case 52: return 2u;    // Orbiting_Rods_N_Sticks
        case 53: return 20u;   // Miris_Ball (num+(num-id) baked representative)
        case 54: return 20u;   // Waves
        case 55: return 200u;  // DNA_String
        case 56: return 400u;  // Sea_Surface (sqr(flor(15+rnd(15))) baked representative)
        case 57: return 9u;    // Pollock_Dots
        case 58: return 70u;   // Pop_Circles
        case 59: return 210u;  // Raindrops
        case 60: return 11u;   // Protozoan_Lovers (rnd(3)+9 baked representative)
        case 61: return 50u;   // Snakes
        case 62: return 500u;  // Spiral
        case 63: return 121u;  // Tosser
        case 64: return 150u;  // Typhoon
        case 65: return 512u;  // Uber_Spirograph
        case 66: return 300u;  // Crosshatch
        case 67: return 2u;    // Juggler
        default: return 100u;
    }
}

kernel void waveKernel
(
 texture2d<half, access::read>       cellIn  [[ texture(0) ]],   // pipe.cell.out (same texture both slots:
 texture2d<half, access::write>      cellOut [[ texture(1) ]],   //  in-place scatter, split for bgra8Unorm)
 constant WaveUniforms&              u       [[ buffer(0)  ]],
 constant float*                     magBuf  [[ buffer(1)  ]],
 constant float*                     fftBuf  [[ buffer(2)  ]],
 uint gid [[ thread_position_in_grid ]])
{
    if (float(gid) >= max(u.num, 0.0)) return; // dispatch may round up to threadgroup multiples

    int algo = clamp(int(u.algo), 0, 67);
    uint STEPS = algoSteps(algo);
    if (STEPS < 1u) STEPS = 1u;
    uint stepIdx = gid % STEPS;
    uint instIdx = gid / STEPS;
    float s = (STEPS > 1u) ? (float(stepIdx) / float(STEPS - 1u)) : 0.0;
    float id = float(instIdx);
    float numF = max(1.0, floor(u.num / float(STEPS)));
    float t = u.t;
    float ux = u.ux, uy = u.uy, ur = u.ur, ua = u.ua;
    float sgnid = ((instIdx & 1u) == 0u) ? 1.0 : -1.0; // replaces source's pow((int)-1,(int)id)

    float a[40] = { 0 };
    float b[40] = { 0 };
    float c[40] = { 0 };
    float x[40] = { 0 };
    float y[40] = { 0 };

    switch (algo) {

    case 0: { // Pair (waveshort.sky.h:1)
        uint rc = 0, rfold = 0;
        a[0] = cos(.3 + wsRnd(instIdx, algo, u.seed, rc, rfold, .6));
        a[1] = sin(.5 + wsRnd(instIdx, algo, u.seed, rc, rfold, .4));
        a[2] = cos(.1 + wsRnd(instIdx, algo, u.seed, rc, rfold, .8));
        a[3] = sin(.2 + wsRnd(instIdx, algo, u.seed, rc, rfold, .7));
        a[4] = cos(.6 + wsRnd(instIdx, algo, u.seed, rc, rfold, .3));
        b[0] = -.6 * t + 1.0; b[1] = .25 * t; b[2] = -.275 * t;
        c[0] = .7 * (s - .1) * cos(b[1]) + a[0];
        c[1] = .7 * (s - .1) * sin(b[1]) + a[0];
        c[2] = c[0] * wsMag(magBuf, u.magCount, .7 * s) * .7;
        x[0] = c[0]*cos(b[0]) - c[1]*sin(b[0]); y[0] = c[1]*sin(b[0]) + c[2]*cos(b[0]);
        x[1] = -(c[0]*sin(b[2]) - c[1]*cos(b[2])); y[1] = -(c[1]*cos(b[2]) + c[2]*sin(b[2]));
        wsWritePoint(cellIn, cellOut, x[0], y[0], 1.0);
        wsWritePoint(cellIn, cellOut, x[1], y[1], 1.0);
        break;
    }
    case 1: { // Dancing_Days (waveshort.sky.h:30)
        b[0] = 0.0002*sin(t*0.2); b[6] = sin(0.1*t); b[16] = ws_wrap(t*b[0])*6.28;
        b[1] = 0.0003*cos(t*0.5); b[7] = sin(0.1*t); b[17] = ws_wrap(t*b[1])*6.28;
        b[2] = 0.0004*cos(t*0.05); b[8] = sin(0.2*t); b[18] = ws_wrap(t*b[2])*6.28;
        b[3] = 0.0005*cos(t*0.3); b[9] = cos(0.6*t); b[19] = ws_wrap(t*b[3])*6.28;
        b[4] = 0.0006*cos(t*0.2); b[10] = cos(0.1*t); b[20] = ws_wrap(t*b[4])*6.28;
        b[5] = 0.0004*cos(t*0.1); b[11] = cos(0.08*t); b[21] = ws_wrap(t*b[5])*6.28;
        b[12] = cos(t*0.01); b[13] = cos(t*0.02); b[14] = cos(t*0.05); b[15] = sin(t*0.07);
        c[0] = .3 * wsMag(magBuf, u.magCount, s);
        x[0]=cos(b[16]+s*b[6])*(b[12]+c[0]); y[0]=sin(b[16]+s*b[6])*(0.3+c[0]);
        x[1]=cos(b[17]+s*b[7])*(0.7+c[0]); y[1]=sin(b[17]+s*b[7])*(b[13]+c[0]);
        x[2]=cos(b[18]+s*b[8])*(b[14]+c[0]); y[2]=sin(b[18]+s*b[8])*(b[14]+c[0]);
        x[3]=cos(b[19]+s*b[9])*(b[15]+c[0]); y[3]=sin(b[19]+s*b[9])*(b[15]+c[0]);
        x[4]=cos(b[20]+s*b[10])*(0.6+c[0]); y[4]=sin(b[20]+s*b[10])*(0.3+c[0]);
        x[5]=cos(b[21]+s*b[11])*(0.4+c[0]); y[5]=sin(b[21]+s*b[11])*(0.7+c[0]);
        for (int i=0;i<=5;i++) wsWritePoint(cellIn, cellOut, x[i], y[i], 1.0);
        break;
    }
    case 2: { // Five (waveshort.sky.h:64)
        uint rc = 0, rfold = 0;
        a[0] = cos(.3 + wsRnd(instIdx, algo, u.seed, rc, rfold, .6));
        a[1] = sin(.5 + wsRnd(instIdx, algo, u.seed, rc, rfold, .4));
        a[2] = cos(.1 + wsRnd(instIdx, algo, u.seed, rc, rfold, .8));
        a[3] = sin(.2 + wsRnd(instIdx, algo, u.seed, rc, rfold, .7));
        a[4] = cos(.6 + wsRnd(instIdx, algo, u.seed, rc, rfold, .3));
        b[0]=-.5*t; b[1]=.15*t; b[2]=-.4*t+1.23213; b[3]=.15*t; b[4]=-.65*t;
        b[5]=-.55*t+4.45245; b[6]=-.315*t+2.13213; b[7]=.7*cos(b[1]); b[8]=.7*sin(b[1]);
        c[0]=b[7]*(s-.1)+a[0]; c[1]=b[8]*(s-.1)+a[0];
        c[2]=.7*(s-.1)*sin(b[3])+a[1]; c[3]=.7*(s-.1)*cos(b[3])+a[1];
        c[4]=b[7]*(s-.1)+a[2]; c[5]=b[8]*(s-.1)+a[2];
        c[6]=b[7]*(s-.1)+a[3]; c[7]=b[8]*(s-.1)+a[3];
        c[8]=b[7]*(s-.1)+a[4]; c[9]=b[8]*(s-.1)+a[4];
        c[10]=.6*wsMag(magBuf, u.magCount, .7*s);
        x[0]=c[0]*cos(b[0])-c[1]*sin(b[0]); y[0]=c[1]*sin(b[0])+c[0]*cos(b[0])*c[10];
        x[1]=-(c[0]*sin(b[2])-c[1]*cos(b[2])); y[1]=-(c[1]*cos(b[2])+c[0]*sin(b[2])*c[10]);
        x[2]=-(c[4]*sin(b[4])-c[5]*cos(b[4])); y[2]=-(c[5]*cos(b[4])+c[4]*sin(b[4])*c[10]);
        x[3]=c[6]*cos(b[5])-c[7]*sin(b[5]); y[3]=c[7]*sin(b[5])+c[6]*cos(b[5])*c[10];
        x[4]=-c[8]*cos(b[6])-c[9]*sin(b[6]); y[4]=-c[9]*sin(b[6])+c[8]*cos(b[6])*c[10];
        for (int i=0;i<=4;i++) wsWritePoint(cellIn, cellOut, x[i], y[i], 1.0);
        break;
    }
    case 3: { // Big_and_Banded (waveshort.sky.h:115)
        x[0] = 2*s-1; y[0] = .9*wsMag(magBuf, u.magCount, s);
        float col = .05 + pow(8*ws_dabs(wsMag(magBuf, u.magCount, s)), 1.5);
        wsWritePoint(cellIn, cellOut, x[0], y[0], col);
        break;
    }
    case 4: { // Big_and_Banded2 (waveshort.sky.h:124)
        x[0] = 2*s-1; y[0] = .9*wsFft(fftBuf, u.fftCount, s);
        wsWritePoint(cellIn, cellOut, x[0], y[0], 1.0);
        break;
    }
    case 5: { // HAL_Splashy_Scope (waveshort.sky.h:132)
        b[0] = .5*sin(t*.6); b[1] = 64*ux;
        x[0] = 2*s-1; y[0] = .8*wsMag(magBuf, u.magCount, s) + b[0];
        wsWritePoint(cellIn, cellOut, x[0], y[0], 1.0);
        break;
    }
    case 6: { // Cycling_Dots (waveshort.sky.h:148) -- multi-instance, selection anchor
        float a0 = u.selectT; float a1 = 1.1;
        b[0] = 1.5 - a1*(t - a0); b[1] = sin(b[0])/8; b[2] = cos(b[0])/8;
        x[0] = (2*s-1) + (b[1]*sgnid); y[0] = b[2]*sgnid;
        float col = pow(35*wsMag(magBuf, u.magCount, s), 1.8) + 5.0;
        wsWritePoint(cellIn, cellOut, x[0], y[0], col);
        break;
    }
    case 7: { // CircWarp (waveshort.sky.h:167) -- multi-instance
        uint rc = 0, rfold = 0;
        a[1] = .02 + wsRnd(instIdx, algo, u.seed, rc, rfold, .2);
        a[2] = wsRnd(instIdx, algo, u.seed, rc, rfold, 1000.0);
        a[3] = wsRnd(instIdx, algo, u.seed, rc, rfold, 8.0);
        a[4] = PI * 2;
        a[7] = .1 + wsRnd(instIdx, algo, u.seed, rc, rfold, .6);
        b[0] = wsSeed(id * a[2], rfold);
        b[1] = 4 * (1.01 - ws_wrap(a[1]*t + wsRnd(instIdx, algo, u.seed, rc, rfold, 100.0)));
        b[2] = (wsRnd(instIdx, algo, u.seed, rc, rfold, 2.0) - 1) / b[1];
        b[3] = (wsRnd(instIdx, algo, u.seed, rc, rfold, 2.0) - 1) / b[1];
        b[4] = (ux*2.0*(1 - 2*uy*wsFft(fftBuf, u.fftCount, id/numF)) * .09 + .02) / b[1];
        x[0] = b[2] + b[4]*cos(s*a[4]); y[0] = b[3] + b[4]*sin(s*a[4]);
        wsWritePoint(cellIn, cellOut, x[0], y[0], a[7]);
        break;
    }
    case 8: { // Dense_Spiral (waveshort.sky.h:195)
        uint rc = 0, rfold = 0;
        a[0] = wsRnd(instIdx, algo, u.seed, rc, rfold, .5) + .5;
        b[0] = t * a[0]; b[1] = 20 * ux;
        c[0] = 1 - s - wsMag(magBuf, u.magCount, s) * .5;
        c[1] = s * 18.8495;
        x[0] = c[0]*cos(c[1]+b[0]); y[0] = c[0]*sin(c[1]+b[0]);
        wsWritePoint(cellIn, cellOut, x[0], y[0], c[1]);
        break;
    }
    case 9: { // Hourglass (waveshort.sky.h:214) -- Steps(-1)->300; width-only 2nd
              // assignment of c[5] dropped (draw() width is not ported)
        a[0] = 2 * PI;
        b[0] = .6*t; b[1] = .5*cos(b[0]); b[2] = .5*sin(b[0]);
        c[0] = s*a[0]; c[3] = cos(c[0]); c[4] = sin(c[0]); c[5] = .1*wsMag(magBuf, u.magCount, s);
        x[0]=5.0*c[5]+0.5*c[3]+b[1]; y[0]=0.5*c[4]+b[2];
        x[1]=5.0*c[5]+0.5*c[3]-b[1]; y[1]=0.5*c[4]-b[2];
        x[2]=c[5]+.12*c[3]; y[2]=c[5]+.12*c[4];
        c[6] = .5 + (wsMag(magBuf, u.magCount, s) + 1) / 2;
        for (int i=0;i<=2;i++) wsWritePoint(cellIn, cellOut, x[i], y[i], c[6]);
        break;
    }
    case 10: { // DT_SineDot (waveshort.sky.h:247)
        uint rc = 0, rfold = 0;
        a[0] = wsRnd(instIdx, algo, u.seed, rc, rfold, .8);
        b[0]=.97*sin(t*.3); b[1]=.97*cos(t*.1); b[2]=.70*sin(t*.5);
        b[3]=10*sin(t*.03); b[4]=14*sin(t*.15); b[5]=18*sin(t*.3); b[6]=4*sin(t*.3);
        c[0] = 2*s-1;
        x[0]=c[0]; y[0]=b[0]*sin(s*b[3]+t*0.6);
        x[1]=c[0]; y[1]=b[1]*sin(s*b[4]-b[6]);
        x[2]=c[0]; y[2]=b[2]*sin(s*b[5]+t);
        float col = ws_clip(wsMag(magBuf, u.magCount, 0.1) + 0.7 + a[0]);
        for (int i=0;i<=2;i++) wsWritePoint(cellIn, cellOut, x[i], y[i], col);
        break;
    }
    case 11: { // Pollock_Spectagon (waveshort.sky.h:272) -- multi-instance, selection anchor
        float a0 = u.selectT; float a1 = 1.6; float a2 = .3;
        b[0] = 1.5 - a1*(t - a0); b[1] = sin(b[0])/4; b[2] = cos(1.3*sin(a2*(t-a0))+.3);
        c[0] = 20*uy*wsFft(fftBuf, u.fftCount, id/float(STEPS));
        x[0] = (2*s-1) + (b[1]*sgnid); y[0] = b[2]*sgnid + (0.04*sgnid);
        wsWritePoint(cellIn, cellOut, x[0], y[0], c[0]);
        break;
    }
    case 12: { // Uber_Aurora (waveshort.sky.h:295)
        c[0] = sin(sin((s+t/15)*PI)*PI)*.8; c[1] = cos(s*PI);
        x[0]=c[0]; y[0]=c[1];
        x[1]=c[0]+sin(s+t/2)/3; y[1]=c[1];
        x[2]=c[0]+cos(s+t/2.7)/3; y[2]=c[1];
        float col = wsFft(fftBuf, u.fftCount, s) + .7;
        for (int i=0;i<=2;i++) wsWritePoint(cellIn, cellOut, x[i], y[i], col);
        break;
    }
    case 13: { // Spectagon (waveshort.sky.h:315)
        float a0=.3; // a1=10.0 in source only feeds dead a[2]/a[3] registers, dropped
        b[2]=.03+a0*pow(wsFft(fftBuf,u.fftCount, ux+uy*.0), 1.0+ur*.3);
        b[3]=.03+a0*pow(wsFft(fftBuf,u.fftCount, ux+uy*.1), 1.0+ur*.3);
        b[4]=.03+a0*pow(wsFft(fftBuf,u.fftCount, ux+uy*.2), 1.0+ur*.3);
        b[5]=.03+a0*pow(wsFft(fftBuf,u.fftCount, ux+uy*.3), 1.0+ur*.3);
        b[6]=.03+a0*pow(wsFft(fftBuf,u.fftCount, ux+uy*.4), 1.0+ur*.3);
        b[7]=.03+a0*pow(wsFft(fftBuf,u.fftCount, ux+uy*.5), 1.0+ur*.3);
        b[8]=.03+a0*pow(wsFft(fftBuf,u.fftCount, ux+uy*.6), 1.0+ur*.3);
        b[9]=.03+a0*pow(wsFft(fftBuf,u.fftCount, ux+uy*.7), 1.0+ur*.3);
        b[10]=.03+a0*pow(wsFft(fftBuf,u.fftCount, ux+uy*.8), 1.0+ur*.3);
        c[0]=cos(s*PI*2+.6*t); c[1]=sin(s*PI*2+.6*t);
        x[3]=b[2]*c[0]-.8; y[3]=b[2]*c[1];
        x[4]=b[3]*c[0]-.6; y[4]=b[3]*c[1];
        x[5]=b[4]*c[0]-.4; y[5]=b[4]*c[1];
        x[1]=b[5]*c[0]-.2; y[1]=b[5]*c[1];
        x[0]=b[6]*c[0]-.01; y[0]=b[6]*c[1];
        x[2]=b[7]*c[0]+.2; y[2]=b[7]*c[1];
        x[6]=b[8]*c[0]+.4; y[6]=b[8]*c[1];
        x[7]=b[9]*c[0]+.6; y[7]=b[9]*c[1];
        x[8]=b[10]*c[0]+.8; y[8]=b[10]*c[1];
        for (int i=0;i<=8;i++) wsWritePoint(cellIn, cellOut, x[i], y[i], 1.0);
        break;
    }
    case 14: { // I_Declare (waveshort.sky.h:344)
        uint rc = 0, rfold = 0;
        a[0] = .05 + wsRnd(instIdx, algo, u.seed, rc, rfold, .3);
        a[5] = .05 + wsRnd(instIdx, algo, u.seed, rc, rfold, .3);
        a[1] = ws_trnc(kSampleSteps / 100.0);
        a[2] = kSampleSteps / a[1];
        a[3] = 4 + wsRnd(instIdx, algo, u.seed, rc, rfold, 7.0);
        a[4] = a[3] * (.4 + wsRnd(instIdx, algo, u.seed, rc, rfold, .5));
        a[6] = 2 * PI / a[1];
        a[7] = 2 * tan(PI / a[1]);
        b[0] = sin(t*a[5]); b[1] = cos(t*a[5]); b[2] = sin(t*a[0]); b[3] = cos(t*a[0]);
        c[0] = a[6]*ws_trnc(s*a[1]);
        c[1] = a[7]*(ws_wrap(s*a[1]) - .5);
        c[2] = 1 + .55*wsMag(magBuf, u.magCount, s*a[1]);
        c[3] = c[2]*cos(c[0]) - c[1]*sin(c[0]);
        c[4] = c[2]*sin(c[0]) + c[1]*cos(c[0]);
        c[5] = c[3]*b[1] - c[4]*b[0];
        c[6] = c[3]*b[0] + c[4]*b[1];
        c[7] = c[6]*b[3];
        c[8] = a[3] - c[6]*b[2];
        x[0] = a[4]*c[5]/c[8]; y[0] = a[4]*c[7]/c[8];
        wsWritePoint(cellIn, cellOut, x[0], y[0], 1.0);
        break;
    }
    case 15: { // Align (waveshort.sky.h:396)
        uint rc = 0, rfold = 0;
        a[0] = .1 + wsRnd(instIdx, algo, u.seed, rc, rfold, .6);
        a[1] = .1 + wsRnd(instIdx, algo, u.seed, rc, rfold, .4);
        a[2] = .1 + wsRnd(instIdx, algo, u.seed, rc, rfold, .4);
        b[0] = a[0]*sin(a[2]*t);
        c[0] = .18*wsMag(magBuf, u.magCount, s) + a[1];
        c[1] = c[0]*cos(s*PI*2+b[0]); c[2] = c[0]*sin(s*PI*2+b[0]);
        x[0]=c[1]+b[0]; y[0]=c[2];
        x[1]=c[1]-b[0]; y[1]=c[2];
        x[2]=c[1]; y[2]=c[2]+b[0];
        x[3]=c[1]; y[3]=c[2]-b[0];
        for (int i=0;i<=3;i++) wsWritePoint(cellIn, cellOut, x[i], y[i], .5);
        break;
    }
    case 16: { // Arena (waveshort.sky.h:421)
        b[0] = .4*(sin(t*.55)+1);
        c[0] = .3*wsMag(magBuf, u.magCount, s); c[1] = b[0]+c[0];
        x[0]=s-.5; y[0]=c[0]+b[0];
        x[1]=s-.5; y[1]=c[0]-b[0];
        c[2] = sin(s*PI)*c[1]; c[3] = cos(s*PI)*c[1];
        x[2]=.5+c[2]; y[2]=c[3];
        x[3]=-.5-c[2]; y[3]=c[3];
        for (int i=0;i<=3;i++) wsWritePoint(cellIn, cellOut, x[i], y[i], 1.0);
        break;
    }
    case 17: { // Critters (waveshort.sky.h:448)
        // NOTE(port): source reads c[1] one step stale before assigning it
        // this pass (CallTree.md section 6 point 8 -- a persistent-register
        // quirk of the original engine). SCATTER threads have no access to
        // that stale carry, so c[1] is computed first here for a
        // well-defined result instead of reading always-zero garbage.
        c[1] = .9 + .3*wsMag(magBuf, u.magCount, .7*s);
        c[3] = c[1]*sin(s*1.57079632);
        c[2] = c[1]*cos(s*1.57079632);
        x[0]=c[2]*.25;  y[0]=c[3]*.25;
        x[1]=c[2]*-.25; y[1]=c[3]*.25;
        x[2]=c[2]*-.25; y[2]=c[3]*-.25;
        x[3]=c[2]*.25;  y[3]=c[3]*-.25;
        x[4]=c[2]*.5;   y[4]=c[3]*.5;
        x[5]=c[2]*-.5;  y[5]=c[3]*.5;
        x[6]=c[2]*-.5;  y[6]=c[3]*-.5;
        x[7]=c[2]*.5;   y[7]=c[3]*-.5;
        x[8]=c[2]*.75;  y[8]=c[3]*.75;
        x[9]=c[2]*-.75; y[9]=c[3]*.75;
        x[10]=c[2]*-.75; y[10]=c[3]*-.75;
        x[11]=c[2]*.75;  y[11]=c[3]*-.75;
        float col = pow(8*ws_dabs(wsMag(magBuf, u.magCount, s)), 1.5);
        for (int i=0;i<=11;i++) wsWritePoint(cellIn, cellOut, x[i], y[i], col);
        break;
    }
    case 18: { // Cylinder (waveshort.sky.h:481)
        uint rc = 0, rfold = 0;
        a[1] = sin(-3.14*.4); a[2] = cos(-3.14*.4);
        a[3] = 2 + wsRnd(instIdx, algo, u.seed, rc, rfold, 2.0);
        a[4] = a[3] * (.7 + wsRnd(instIdx, algo, u.seed, rc, rfold, .3));
        a[5] = .3 + wsRnd(instIdx, algo, u.seed, rc, rfold, .3);
        b[0] = t*a[5];
        c[0]=cos(PI*2*s+b[0]); c[1]=sin(PI*2*s+b[0]); c[2]=.5*wsMag(magBuf, u.magCount, s);
        c[3]=c[1]*a[2]+c[2]*a[1]; c[4]=a[3]+c[2]*a[2]-c[1]*a[1];
        x[0]=a[4]*c[0]/c[4]; y[0]=a[4]*c[3]/c[4];
        wsWritePoint(cellIn, cellOut, x[0], y[0], 1.0);
        break;
    }
    case 19: { // Dans_Furathama (waveshort.sky.h:505) -- Steps(-1)->300
        uint rc = 0, rfold = 0;
        a[0] = .3 + wsRnd(instIdx, algo, u.seed, rc, rfold, .3);
        b[0] = cos(t*a[0]); b[1] = sin(t*a[0]);
        c[0] = wsMag(magBuf, u.magCount, s)*1.4*s;
        c[1] = b[1]*(c[0]-s); c[2] = b[0]*c[0]-b[1]*s;
        x[0]=c[1]; y[0]=c[2];
        x[1]=-c[1]; y[1]=-c[2];
        for (int i=0;i<=1;i++) wsWritePoint(cellIn, cellOut, x[i], y[i], 1.0);
        break;
    }
    case 20: { // Father_and_Daughters (waveshort.sky.h:534) -- fftSlots() baked
        c[0] = .4*wsFft(fftBuf, u.fftCount, s) + .3;
        c[1] = (2*s-1)*.4 + .6;
        x[1]=c[1]; y[1]=c[0];
        x[2]=c[1]; y[2]=c[0]+.3;
        x[3]=-c[1]; y[3]=c[0];
        x[4]=-c[1]; y[4]=c[0]+.3;
        x[5]=-c[1]; y[5]=-c[0];
        x[6]=-c[1]; y[6]=-c[0]-.3;
        x[7]=c[1]; y[7]=-c[0];
        x[0]=c[1]; y[0]=-c[0]-.3;
        for (int i=0;i<=7;i++) wsWritePoint(cellIn, cellOut, x[i], y[i], 1.0);
        break;
    }
    case 21: { // Lightning_Strikes (waveshort.sky.h:556)
        b[0] = .25*t;
        c[0] = .2*wsMag(magBuf, u.magCount, s) + .3*sin(5*s+b[0]) + .1*sin(.5*b[0]) + s*0.2*(cos(3*b[0])+sin(5*b[0]));
        c[1] = 1 - 2*s;
        x[0]=c[0]; y[0]=c[1];
        c[2] = ws_clip(s-.5+.06*sin(b[0])) * (sin(b[0])+.4*cos(9*s));
        x[1]=c[0]+c[2]; y[1]=c[1];
        x[2]=c[0]+ws_clip(s-.9)*1.5*sin(1.5*b[0]); y[2]=c[1];
        x[3]=c[0]+c[2]-ws_clip(s-.7+.05*cos(1.2*b[0]))*.6*(cos(1.2*b[0])+.3*sin(12*s)); y[3]=c[1];
        for (int i=0;i<=3;i++) wsWritePoint(cellIn, cellOut, x[i], y[i], 1.0);
        break;
    }
    case 22: { // Moving (waveshort.sky.h:613)
        b[0] = .7*sin(.2*t);
        c[0] = 2*(s-.3); c[1] = b[0] + wsMag(magBuf, u.magCount, s)*.25;
        x[0]=c[1]-.6; y[0]=c[0];
        x[1]=c[1]-1.2; y[1]=c[0]+.6;
        x[2]=c[1]; y[2]=c[0]-.6;
        x[3]=c[1]+.6; y[3]=c[0];
        x[4]=c[1]+1.2; y[4]=c[0]+.6;
        for (int i=0;i<=4;i++) wsWritePoint(cellIn, cellOut, x[i], y[i], 1.0);
        break;
    }
    case 23: { // Radar_Sweep (waveshort.sky.h:631)
        uint rc = 0, rfold = 0;
        a[0] = .2 + wsRnd(instIdx, algo, u.seed, rc, rfold, .5);
        b[0] = 1.1*cos(t*a[0]); b[1] = 1.1*sin(t*a[0]);
        c[0] = wsMag(magBuf, u.magCount, s)*0.4*s;
        x[0] = -b[0]*s - b[1]*c[0]; y[0] = b[0]*c[0] - b[1]*s;
        wsWritePoint(cellIn, cellOut, x[0], y[0], ws_clip(7 - 7*s));
        break;
    }
    case 24: { // Rotating_Arcs (waveshort.sky.h:647) -- Steps(-1)->300
        uint rc = 0, rfold = 0;
        a[0] = .5 + wsRnd(instIdx, algo, u.seed, rc, rfold, .2);
        a[1] = wsRnd(instIdx, algo, u.seed, rc, rfold, 1.3) + 1.4;
        c[0] = a[0] + .25*wsMag(magBuf, u.magCount, s);
        c[1] = .3*t + a[1]*s;
        x[0]=c[0]*cos(c[1]); y[0]=c[0]*sin(c[1]);
        x[1]=c[0]*cos(c[1]+3.14159); y[1]=c[0]*sin(c[1]+3.14159);
        for (int i=0;i<=1;i++) wsWritePoint(cellIn, cellOut, x[i], y[i], 1.0);
        break;
    }
    case 25: { // Rotating_Bars (waveshort.sky.h:666)
        c[0]=sin(t)*wsMag(magBuf, u.magCount, s)*.8;
        c[1]=cos(t)*wsMag(magBuf, u.magCount, s)*.8;
        c[2]=sin(2*t)*wsMag(magBuf, u.magCount, s)*.8;
        x[0]=.5+c[0]; y[0]=.5-c[1];
        x[1]=-.5+c[0]; y[1]=-.5-c[1];
        x[2]=.5+c[0]; y[2]=-.5+c[1];
        x[3]=-.5+c[0]; y[3]=.5+c[1];
        x[4]=-2*c[0]; y[4]=c[1];
        x[5]=2*c[0]; y[5]=c[1];
        x[6]=c[2]; y[6]=-c[1];
        x[7]=c[2]; y[7]=c[1];
        x[8]=-c[1]; y[8]=c[2];
        x[9]=c[1]; y[9]=c[2];
        for (int i=0;i<=9;i++) wsWritePoint(cellIn, cellOut, x[i], y[i], 1.0);
        break;
    }
    case 26: { // Rotating_X (waveshort.sky.h:689)
        b[0]=cos(t*(-0.3)); b[1]=sin(t*(-0.3));
        c[0]=sin(s*PI)*wsMag(magBuf, u.magCount, s)*0.3; c[1]=2*s-1;
        x[0]=-b[0]*c[1]-b[1]*c[0]; y[0]=b[0]*c[0]-b[1]*c[1];
        x[1]=-b[1]*c[1]-b[0]*c[0]; y[1]=-b[1]*c[0]+b[0]*c[1];
        for (int i=0;i<=1;i++) wsWritePoint(cellIn, cellOut, x[i], y[i], 1.0);
        break;
    }
    case 27: { // Simple_Horizontal (waveshort.sky.h:705)
        uint rc = 0, rfold = 0;
        a[0] = 1.8 + wsRnd(instIdx, algo, u.seed, rc, rfold, 3.5);
        c[0] = cos(PI*(s-.5));
        x[0] = 2*s-1; y[0] = .7*wsMag(magBuf, u.magCount, s)*c[0];
        wsWritePoint(cellIn, cellOut, x[0], y[0], 1.0);
        break;
    }
    case 28: { // Simple_Vertical (waveshort.sky.h:715)
        x[0] = .8*wsMag(magBuf, u.magCount, s); y[0] = 2*s-1;
        wsWritePoint(cellIn, cellOut, x[0], y[0], 1.0);
        break;
    }
    case 29: { // Sing_Me_to_Sleep (waveshort.sky.h:724) -- fftSlots() baked
        c[0] = pow(.8*wsFft(fftBuf, u.fftCount, s), 1.4);
        x[0]=s; y[0]=c[0];
        x[1]=-s; y[1]=-c[0];
        x[2]=-s; y[2]=c[0];
        x[3]=s; y[3]=-c[0];
        for (int i=0;i<=3;i++) wsWritePoint(cellIn, cellOut, x[i], y[i], 8*c[0]);
        break;
    }
    case 30: { // SM_Spectometer (waveshort.sky.h:738)
        uint rc = 0, rfold = 0;
        float a0 = 1.5;
        (void)wsRnd(instIdx, algo, u.seed, rc, rfold, 6.0); // a1: thickness, width-only, dropped
        x[0]=-0.9; y[0]=a0*s*(wsFft(fftBuf,u.fftCount,.05)+wsFft(fftBuf,u.fftCount,.95))-1;
        x[1]=-0.8; y[1]=a0*s*(wsFft(fftBuf,u.fftCount,.10)+wsFft(fftBuf,u.fftCount,.90))-1;
        x[2]=-0.7; y[2]=a0*s*(wsFft(fftBuf,u.fftCount,.15)+wsFft(fftBuf,u.fftCount,.85))-1;
        x[3]=-0.6; y[3]=a0*s*(wsFft(fftBuf,u.fftCount,.20)+wsFft(fftBuf,u.fftCount,.80))-1;
        x[4]=-0.5; y[4]=a0*s*(wsFft(fftBuf,u.fftCount,.25)+wsFft(fftBuf,u.fftCount,.75))-1;
        x[5]=-0.4; y[5]=a0*s*(wsFft(fftBuf,u.fftCount,.30)+wsFft(fftBuf,u.fftCount,.70))-1;
        x[6]=-0.3; y[6]=a0*s*(wsFft(fftBuf,u.fftCount,.35)+wsFft(fftBuf,u.fftCount,.65))-1;
        x[7]=-0.2; y[7]=a0*s*(wsFft(fftBuf,u.fftCount,.40)+wsFft(fftBuf,u.fftCount,.60))-1;
        x[8]=-0.1; y[8]=a0*s*(wsFft(fftBuf,u.fftCount,.45)+wsFft(fftBuf,u.fftCount,.55))-1;
        x[9]=-0.0; y[9]=2*a0*s*wsFft(fftBuf,u.fftCount,.50)-1;
        x[10]=0.1; y[10]=a0*s*(wsFft(fftBuf,u.fftCount,.45)+wsFft(fftBuf,u.fftCount,.55))-1;
        x[11]=0.2; y[11]=a0*s*(wsFft(fftBuf,u.fftCount,.40)+wsFft(fftBuf,u.fftCount,.60))-1;
        x[12]=0.3; y[12]=a0*s*(wsFft(fftBuf,u.fftCount,.35)+wsFft(fftBuf,u.fftCount,.65))-1;
        x[13]=0.4; y[13]=a0*s*(wsFft(fftBuf,u.fftCount,.30)+wsFft(fftBuf,u.fftCount,.70))-1;
        x[14]=0.5; y[14]=a0*s*(wsFft(fftBuf,u.fftCount,.25)+wsFft(fftBuf,u.fftCount,.75))-1;
        x[15]=0.6; y[15]=a0*s*(wsFft(fftBuf,u.fftCount,.20)+wsFft(fftBuf,u.fftCount,.80))-1;
        x[16]=0.7; y[16]=a0*s*(wsFft(fftBuf,u.fftCount,.15)+wsFft(fftBuf,u.fftCount,.85))-1;
        x[17]=0.8; y[17]=a0*s*(wsFft(fftBuf,u.fftCount,.10)+wsFft(fftBuf,u.fftCount,.90))-1;
        x[18]=0.9; y[18]=a0*s*(wsFft(fftBuf,u.fftCount,.05)+wsFft(fftBuf,u.fftCount,.95))-1;
        x[19]=1.0; y[19]=a0*s*(wsFft(fftBuf,u.fftCount,.00)+wsFft(fftBuf,u.fftCount,1.00))-1;
        float col = 2*sin(s)+0.1;
        for (int i=0;i<=19;i++) wsWritePoint(cellIn, cellOut, x[i], y[i], col);
        break;
    }
    case 31: { // SOLs_Vinyl (waveshort.sky.h:770)
        uint rc = 0, rfold = 0;
        a[1] = sin(-3.14*.35); a[2] = cos(-3.14*.35);
        a[5] = .3 + wsRnd(instIdx, algo, u.seed, rc, rfold, .3);
        a[3] = 2 + wsRnd(instIdx, algo, u.seed, rc, rfold, 2.0);
        a[4] = a[3] * (.4 + wsRnd(instIdx, algo, u.seed, rc, rfold, .5));
        b[0] = sin(t*a[5]); b[1] = cos(t*a[5]);
        c[0] = 3*(wsMag(magBuf,u.magCount,s)*.35+.4)*cos(s*PI*2);
        c[1] = 3*(wsMag(magBuf,u.magCount,s)*.35+.4)*sin(s*PI*2);
        c[2]=c[0]*b[1]-c[1]*b[0]; c[3]=c[0]*b[0]+c[1]*b[1];
        c[4]=c[3]*a[2]; c[5]=a[3]-c[3]*a[1]; c[6]=a[3]-c[3]*.95*a[1]; c[7]=a[3]-c[3]*.9*a[1]; c[8]=a[3]-c[3]*.85*a[1];
        x[0]=a[4]*c[2]/c[5]; y[0]=a[4]*c[4]/c[5];
        x[1]=a[4]*c[2]*.95/c[6]; y[1]=a[4]*c[4]*.95/c[6];
        x[2]=a[4]*c[2]*.9/c[7]; y[2]=a[4]*c[4]*.9/c[7];
        x[3]=a[4]*c[2]*.85/c[8]; y[3]=a[4]*c[4]*.85/c[8];
        for (int i=0;i<=3;i++) wsWritePoint(cellIn, cellOut, x[i], y[i], 1.0);
        break;
    }
    case 32: { // Spin_Doctor (waveshort.sky.h:818)
        b[0] = .48*sin(t*.2)+.5;
        c[1]=2*s*(1-b[0]); c[2]=2*s*b[0]-1; c[0]=.4*wsMag(magBuf, u.magCount, s);
        x[0]=1-c[1]+c[0]; y[0]=-c[2];
        x[1]=c[2]; y[1]=1-c[1]+c[0];
        x[2]=c[1]-1+c[0]; y[2]=c[2];
        x[3]=-c[2]; y[3]=c[1]-1+c[0];
        for (int i=0;i<=3;i++) wsWritePoint(cellIn, cellOut, x[i], y[i], 1.0);
        break;
    }
    case 33: { // SpinIt (waveshort.sky.h:839)
        // NOTE(port): source reads c[0] stale before assigning it this pass
        // (same class of hazard as Critters, CallTree.md section 6 point 8);
        // c[0] is computed first here for a well-defined result.
        uint rc = 0, rfold = 0;
        a[0] = .25 + wsRnd(instIdx, algo, u.seed, rc, rfold, .4);
        b[0] = cos(a[0]*t*ux); b[1] = sin(a[0]*t*uy);
        c[0] = 2*s-1; c[1] = wsMag(magBuf, u.magCount, s)*0.6*c[0];
        x[0]=-b[0]*c[0]-b[1]*c[1]; y[0]=b[0]*c[1]-b[1]*c[0];
        x[1]=-b[0]*c[0]+b[1]*c[1]; y[1]=b[0]*c[1]+b[1]*c[0];
        for (int i=0;i<=1;i++) wsWritePoint(cellIn, cellOut, x[i], y[i], 1.0);
        break;
    }
    case 34: { // The_Eye (waveshort.sky.h:861)
        uint rc = 0, rfold = 0;
        a[0] = .3 + wsRnd(instIdx, algo, u.seed, rc, rfold, .3);
        b[0] = -sin(a[0]*t);
        c[0] = sin(s*PI)*b[0] + wsMag(magBuf, u.magCount, s)*0.3; c[1] = 2*s-1;
        x[0]=1.7*c[1]; y[0]=c[0];
        x[1]=c[0]; y[1]=c[1];
        x[2]=1.7*c[1]; y[2]=-c[0];
        x[3]=-c[0]; y[3]=c[1];
        for (int i=0;i<=3;i++) wsWritePoint(cellIn, cellOut, x[i], y[i], 1.0);
        break;
    }
    case 35: { // Threes_A_Crowd (waveshort.sky.h:879)
        a[0] = PI*2;
        b[0]=t*0.25; b[1]=.314*cos(b[0]); b[2]=.314*sin(b[0]);
        b[3]=.314*cos(b[0]+1.57); b[4]=.314*sin(b[0]+1.57);
        b[5]=.314*tan(b[0]-1.57); b[6]=.314*sin(b[0]-1.57);
        c[0]=uy*wsMag(magBuf, u.magCount, s)*0.157+.314; c[1]=s*b[0]*a[0];
        x[0]=c[0]*cos(c[1])+b[6]; y[0]=c[0]*sin(c[1])+b[5];
        x[1]=c[0]*cos(c[1])+b[4]; y[1]=c[0]*sin(c[1])+b[3];
        x[2]=c[0]*cos(c[1])+b[2]; y[2]=c[0]*sin(c[1])+b[1];
        float col = wsFft(fftBuf, u.fftCount, s);
        for (int i=0;i<=2;i++) wsWritePoint(cellIn, cellOut, x[i], y[i], col);
        break;
    }
    case 36: { // Thunderation (waveshort.sky.h:902) -- 2*fftSlots() baked
        uint rc = 0, rfold = 0;
        a[0] = 1 + wsRnd(instIdx, algo, u.seed, rc, rfold, 1.5);
        c[0]=s*2-1; c[1]=.5*wsFft(fftBuf, u.fftCount, 1 - ws_trwv(2*s));
        c[2]=cos(ws_clip(s*.471) - wsMag(magBuf, u.magCount, s)*4.71);
        x[0]=c[0]; y[0]=c[1];
        x[1]=c[0]; y[1]=-c[1];
        for (int i=0;i<=1;i++) wsWritePoint(cellIn, cellOut, x[i], y[i], c[2]);
        break;
    }
    case 37: { // Wave (waveshort.sky.h:919)
        b[0] = .3*sin(t);
        c[0]=.2+.4*wsMag(magBuf, u.magCount, s);
        c[1]=.06+cos(s*6.28)*c[0]; c[2]=b[0]+sin(s*6.28)*c[0];
        x[0]=3*s-1.5; y[0]=(b[0]*sin(s*ux*15)) + (0.05*sin(s*uy*100+t*8));
        x[1]=c[1]; y[1]=.5+c[2];
        x[2]=c[1]; y[2]=-.5+c[2];
        float col = (1+sin(s*10+t))/2;
        for (int i=0;i<=2;i++) wsWritePoint(cellIn, cellOut, x[i], y[i], col);
        break;
    }
    case 38: { // Darren_Doublehelix (waveshort.sky.h:937) -- Steps(-1)->300
        uint rc = 0, rfold = 0;
        a[0] = 0.08 + wsRnd(instIdx, algo, u.seed, rc, rfold, .15);
        a[1] = 0.2 + wsRnd(instIdx, algo, u.seed, rc, rfold, 1.0);
        a[2] = 12.0 + wsRnd(instIdx, algo, u.seed, rc, rfold, 12.0);
        a[3] = 0.1 + wsRnd(instIdx, algo, u.seed, rc, rfold, .3);
        b[0]=cos(t*a[0]); b[1]=sin(t*a[0]);
        c[0]=sin(a[2]*s+a[1]*t); c[1]=s*5-2.5;
        c[2]=(c[0]+ws_dabs(c[0])*wsMag(magBuf, u.magCount, s)*2)*a[3];
        x[0]=c[2]*b[0]+c[1]*b[1]; y[0]=c[1]*b[0]-c[2]*b[1];
        x[1]=c[1]*b[1]-c[2]*b[0]; y[1]=c[1]*b[0]+c[2]*b[1];
        for (int i=0;i<=1;i++) wsWritePoint(cellIn, cellOut, x[i], y[i], 1.0);
        break;
    }
    case 39: { // DT_Spectrum (waveshort.sky.h:966)
        c[0] = .4*(s-.5);
        x[5]=-.95; y[5]=c[0]*wsFft(fftBuf,u.fftCount,.05)+.3*sin(t+0);
        x[6]=-.78; y[6]=c[0]*wsFft(fftBuf,u.fftCount,.13)+.3*sin(t+0.4);
        x[7]=-.6;  y[7]=c[0]*wsFft(fftBuf,u.fftCount,.21)+.3*sin(t+0.8);
        x[3]=-.43; y[3]=c[0]*wsFft(fftBuf,u.fftCount,.3)+.3*sin(t+1.2);
        x[4]=-.26; y[4]=c[0]*wsFft(fftBuf,u.fftCount,.38)+.3*sin(t+1.6);
        x[0]=-.09; y[0]=c[0]*wsFft(fftBuf,u.fftCount,.46)+.3*sin(t+2);
        x[1]=.09;  y[1]=c[0]*wsFft(fftBuf,u.fftCount,.54)+.3*sin(t+2.4);
        x[2]=.26;  y[2]=c[0]*wsFft(fftBuf,u.fftCount,.62)+.3*sin(t+2.8);
        x[8]=.43;  y[8]=c[0]*wsFft(fftBuf,u.fftCount,.7)+.3*sin(t+3.2);
        x[9]=.6;   y[9]=c[0]*wsFft(fftBuf,u.fftCount,.79)+.3*sin(t+3.6);
        x[10]=.78; y[10]=c[0]*wsFft(fftBuf,u.fftCount,.87)+.3*sin(t+4);
        x[11]=.95; y[11]=c[0]*wsFft(fftBuf,u.fftCount,.95)+.3*sin(t+4.4);
        float col = 2*ws_dabs(s-.5)+.4;
        for (int i=0;i<=11;i++) wsWritePoint(cellIn, cellOut, x[i], y[i], col);
        break;
    }
    case 40: { // DT_Wild (waveshort.sky.h:987)
        c[0]=PI*2*s-1; c[1]=.5+.4*wsMag(magBuf, u.magCount, s);
        x[0]=c[1]*cos(sin(c[0])+t*0.5); y[0]=c[1]*sin(cos(c[0])+t);
        wsWritePoint(cellIn, cellOut, x[0], y[0], 1.0);
        break;
    }
    case 41: { // Splutterbug (waveshort.sky.h:997) -- Steps(-1)->300
        uint rc = 0, rfold = 0;
        a[0] = wsRnd(instIdx, algo, u.seed, rc, rfold, 1.3) + .2;
        a[1] = wsRnd(instIdx, algo, u.seed, rc, rfold, ws_clip(a[0])) + (1 - ws_clip(a[0]+.02));
        a[2] = wsRnd(instIdx, algo, u.seed, rc, rfold, 2*PI);
        a[3] = (wsRnd(instIdx, algo, u.seed, rc, rfold, .6) - .3) * ws_trnc(wsRnd(instIdx, algo, u.seed, rc, rfold, 1.0) + .7);
        a[4] = ws_trnc(wsRnd(instIdx, algo, u.seed, rc, rfold, 1.0) + .5);
        a[5] = a[0]*a[1];
        b[0] = t*0.0003;
        b[2] = (1 + ws_trnc(wsRnd(instIdx, algo, u.seed, rc, rfold, 1.0) + .02) * 4 * a[4]);
        c[0]=s*2*PI+b[0]; c[1]=wsMag(magBuf, u.magCount, s)*b[2] + .1*wsBeat();
        x[0]=c[1]*cos(c[0]); y[0]=c[1]*sin(c[0]);
        wsWritePoint(cellIn, cellOut, x[0], y[0], 1.0);
        break;
    }
    case 42: { // Orbiting_Stars (waveshort.sky.h:1022)
        // NOTE(port): source's b[]-array is a persistent 3-body gravity
        // accumulator that carries state frame-to-frame (see Port/CallTree.md
        // "Waves and Fields" -- shapes recompute every frame, but this one's
        // b[] terms self-reference across frames). SCATTER threads have no
        // persistent storage, so this port always evaluates the source's
        // "just selected" initializer branch (b0=1 gate) instead of the
        // decaying orbital-integration branch -- a stable rosette driven by
        // the a[]-array initial conditions, not genuine orbital drift. See
        // Port/B3.waves.notes.md divergence list.
        uint rc = 0, rfold = 0;
        a[1] = .09;
        a[2] = ws_flor(wsRnd(instIdx, algo, u.seed, rc, rfold, 2.0) + 2);
        a[3] = wsRnd(instIdx, algo, u.seed, rc, rfold, .075) + .025;
        a[4] = .00025;
        a[5] = wsRnd(instIdx, algo, u.seed, rc, rfold, PI);
        a[6] = a[5] + wsRnd(instIdx, algo, u.seed, rc, rfold, 1.0) + .6;
        a[7] = a[6] + wsRnd(instIdx, algo, u.seed, rc, rfold, 1.0) + .6;
        a[8] = wsRnd(instIdx, algo, u.seed, rc, rfold, .6) + .5;
        a[9] = wsRnd(instIdx, algo, u.seed, rc, rfold, .6) + .5;
        a[10] = wsRnd(instIdx, algo, u.seed, rc, rfold, .6) + .5;
        a[11] = wsRnd(instIdx, algo, u.seed, rc, rfold, 2*PI);
        a[12] = wsRnd(instIdx, algo, u.seed, rc, rfold, 2*PI);
        a[13] = wsRnd(instIdx, algo, u.seed, rc, rfold, 2*PI);
        a[14] = wsRnd(instIdx, algo, u.seed, rc, rfold, 2.0) - 1;
        a[15] = wsRnd(instIdx, algo, u.seed, rc, rfold, 2.0) - 1;
        a[16] = wsRnd(instIdx, algo, u.seed, rc, rfold, 2.0) - 1;
        a[17]=a[8]*cos(a[5]); a[18]=a[8]*sin(a[5]);
        a[19]=a[9]*cos(a[6]); a[20]=a[9]*sin(a[6]);
        a[21]=a[10]*cos(a[7]); a[22]=a[10]*sin(a[7]);
        a[23]=a[14]*cos(a[11]); a[24]=a[14]*sin(a[11]);
        a[25]=a[15]*cos(a[12]); a[26]=a[15]*sin(a[12]);
        a[27]=a[16]*cos(a[13]); a[28]=a[16]*sin(a[13]);
        a[29] = .2 + wsRnd(instIdx, algo, u.seed, rc, rfold, .7);
        a[30] = kSampleSteps * PI;
        // b0=1 (always "just selected") branch:
        b[2]=a[23]; b[3]=a[24];
        b[4]=a[17]+a[4]*b[2]; b[5]=a[18]+a[4]*b[3];
        b[6]=a[25]; b[7]=a[26];
        b[8]=a[19]+a[4]*b[6]; b[9]=a[20]+a[4]*b[7];
        b[10]=a[27]; b[11]=a[28];
        b[12]=a[21]+a[4]*b[10]; b[13]=a[22]+a[4]*b[11];
        b[23]=(b[4]+b[8]+b[12])/3; b[24]=(b[5]+b[9]+b[13])/3;
        c[0]=sqrt(wsFft(fftBuf, u.fftCount, a[2]*s+t*.25))*.25; c[1]=s*a[30];
        c[2]=c[0]*cos(c[1])+b[4]-b[23]; c[3]=c[0]*sin(c[1])+b[5]-b[24];
        c[4]=c[0]*cos(c[1])+b[8]-b[23]; c[5]=c[0]*sin(c[1])+b[9]-b[24];
        c[6]=c[0]*cos(c[1])+b[12]-b[23]; c[7]=c[0]*sin(c[1])+b[13]-b[24];
        x[0]=c[2]; y[0]=c[3];
        x[1]=c[4]; y[1]=c[5];
        x[2]=c[6]; y[2]=c[7];
        x[3]=-c[2]; y[3]=-c[3];
        x[4]=-c[4]; y[4]=-c[5];
        x[5]=-c[6]; y[5]=-c[7];
        for (int i=0;i<=5;i++) wsWritePoint(cellIn, cellOut, x[i], y[i], a[29]);
        break;
    }
    case 43: { // Sci_Fi_Expander (waveshort.sky.h:1130)
        uint rc = 0, rfold = 0;
        a[0] = 1 + wsRnd(instIdx, algo, u.seed, rc, rfold, 1.8);
        a[1] = ws_clip(.5 + wsRnd(instIdx, algo, u.seed, rc, rfold, .7));
        c[0] = .9*wsFft(fftBuf, u.fftCount, a[1]*ws_wrap(a[0]*s-t*ux));
        c[1] = .9*wsFft(fftBuf, u.fftCount, a[1]*ws_wrap(a[0]*s-t*.2));
        x[0]=s*sin(c[0]); y[0]=s*cos(c[0]);
        x[1]=-s*sin(c[0]); y[1]=s*cos(c[0]);
        x[2]=s*sin(c[0]); y[2]=-s*cos(c[0]);
        x[3]=-s*sin(c[0]); y[3]=-s*cos(c[0]);
        float col = 4*pow(max(c[0],0.0),1.4) + .4;
        for (int i=0;i<=3;i++) wsWritePoint(cellIn, cellOut, x[i], y[i], col);
        break;
    }
    case 44: { // Simple_Sine (waveshort.sky.h:1147)
        b[0]=PI*ux*4; b[1]=PI*uy;
        c[0]=b[1]*wsFft(fftBuf, u.fftCount, ws_wrap(s-.05));
        c[1]=.9*sin(s*b[0]+t*.3333);
        x[0]=c[1]; y[0]=2*s-1+c[0];
        x[1]=c[1]; y[1]=2*s-1-c[0];
        for (int i=0;i<=1;i++) wsWritePoint(cellIn, cellOut, x[i], y[i], 1.0);
        break;
    }
    case 45: { // Tension_II (waveshort.sky.h:1162) -- fftSlots() baked
        uint rc = 0, rfold = 0;
        a[0] = 1 / (ws_sgn(wsRnd(instIdx, algo, u.seed, rc, rfold, 2.0) - 1) * (wsRnd(instIdx, algo, u.seed, rc, rfold, 8.0) + 4));
        a[1] = PI/1.5; a[2] = PI/.75;
        c[0]=.97*s; c[1]=atan(3*wsFft(fftBuf, u.fftCount, 1-s))*.6;
        c[2]=c[1]+t*a[0]; c[3]=c[1]-t*a[0];
        x[0]=c[0]*sin(c[3]); y[0]=c[0]*cos(c[3]);
        x[1]=-c[0]*sin(c[2]); y[1]=c[0]*cos(c[2]);
        x[2]=-c[0]*sin(c[2]-a[1]); y[2]=c[0]*cos(c[2]-a[1]);
        x[3]=c[0]*sin(c[3]+a[1]); y[3]=c[0]*cos(c[3]+a[1]);
        x[4]=-c[0]*sin(c[2]-a[2]); y[4]=c[0]*cos(c[2]-a[2]);
        x[5]=c[0]*sin(c[3]+a[2]); y[5]=c[0]*cos(c[3]+a[2]);
        for (int i=0;i<=5;i++) wsWritePoint(cellIn, cellOut, x[i], y[i], 1.0);
        break;
    }
    case 46: { // Walls_of_Sound (waveshort.sky.h:1187) -- fftSlots() baked
        uint rc = 0, rfold = 0;
        a[0] = ws_sgn(wsRnd(instIdx, algo, u.seed, rc, rfold, 2.0) - 1) * (wsRnd(instIdx, algo, u.seed, rc, rfold, .12) + .03);
        a[1] = wsRnd(instIdx, algo, u.seed, rc, rfold, .4) + .55;
        a[2]=pow(a[1],2.0); a[3]=pow(a[1],3.0); a[4]=pow(a[1],4.0); a[5]=pow(a[1],5.0);
        c[0]=(3*s-1.5); c[1]=wsFft(fftBuf, u.fftCount, s+t*a[0])*.8-.8;
        x[0]=c[1]; y[0]=c[0];
        x[1]=-c[1]; y[1]=c[0];
        x[2]=c[1]*a[1]; y[2]=c[0]*a[1];
        x[3]=-c[1]*a[1]; y[3]=c[0]*a[1];
        x[4]=c[1]*a[2]; y[4]=c[0]*a[2];
        x[5]=-c[1]*a[2]; y[5]=c[0]*a[2];
        x[6]=c[1]*a[3]; y[6]=c[0]*a[3];
        x[7]=-c[1]*a[3]; y[7]=c[0]*a[3];
        x[8]=c[1]*a[4]; y[8]=c[0]*a[4];
        x[9]=-c[1]*a[4]; y[9]=c[0]*a[4];
        x[10]=c[1]*a[5]; y[10]=c[0]*a[5];
        x[11]=-c[1]*a[5]; y[11]=c[0]*a[5];
        float col = pow(sin(s*PI), 4.0);
        for (int i=0;i<=11;i++) wsWritePoint(cellIn, cellOut, x[i], y[i], col);
        break;
    }

    // ---- PartiShort.sky.h (active particle shortlist, algo 47..67) ----

    case 47: { // Sparkling_Table_Water (PartiShort.sky.h:1) -- selection anchor
        float a0 = u.selectT;
        b[8]=t-a0; b[9]=1+32*(1+sin(b[8]/320));
        b[0]=sin(b[8]/b[9]*PI)*.4; b[1]=sin(b[8]/b[9]*PI*4)*.4;
        b[3]=id/numF*PI*2; b[4]=cos(b[3])*b[0]; b[5]=sin(b[3])*b[0];
        x[0]=b[4]+cos(s*PI*2+t*.5)*b[1]; y[0]=b[5]+sin(s*PI*2+t*.5)*b[1];
        wsWritePoint(cellIn, cellOut, x[0], y[0], .5+uy/2);
        break;
    }
    case 48: { // Solala (PartiShort.sky.h:24) -- selection anchor, STEPS baked
        uint rc = 0, rfold = 0;
        float a0 = u.selectT;
        float a4 = 2 + wsRnd(instIdx, algo, u.seed, rc, rfold, 7.0);
        float a5 = .2 + wsRnd(instIdx, algo, u.seed, rc, rfold, .6);
        float b1 = 32.0;
        float b0 = .97*sin(a4*(t-a0)/b1);
        x[0]=sin(a5*t+s*PI*2)*b0; y[0]=cos(a5*t+s*PI*2)*b0;
        wsWritePoint(cellIn, cellOut, x[0], y[0], .5*uy/2);
        break;
    }
    case 49: { // Rotating_Pulsating_Oval (PartiShort.sky.h:54)
        b[0]=cos(t*(-.325)); b[1]=sin(t*(-.325));
        c[0]=cos(.35*t)*cos(s*6.28); c[1]=sin(.35*t)*sin(s*6.28);
        x[0]=-b[0]*c[1]-b[1]*c[0]; y[0]=b[0]*c[0]-b[1]*c[1];
        wsWritePoint(cellIn, cellOut, x[0], y[0], 1.0);
        break;
    }
    case 50: { // Colliders (PartiShort.sky.h:70) -- 10 instances
        uint rc = 0, rfold = 0;
        a[2] = 1.5; a[3] = 2*a[2];
        a[0] = wsRnd(instIdx, algo, u.seed, rc, rfold, .3) + .2;
        a[4] = wsRnd(instIdx, algo, u.seed, rc, rfold, .5) + .2;
        a[5] = 5.0;
        a[6] = wsRnd(instIdx, algo, u.seed, rc, rfold, .3) + .1;
        a[7] = 3 + wsRnd(instIdx, algo, u.seed, rc, rfold, 7.0);
        a[8] = .05 + wsRnd(instIdx, algo, u.seed, rc, rfold, .5);
        b[0]=sin(t*a[0]); b[1]=(ws_sgn(b[0])+1)*.5; b[2]=ws_dabs(b[1]-1);
        b[3]=t*a[4]; b[4]=cos(b[3]); b[5]=sin(b[3]);
        b[18]=-t*a[6]; b[19]=cos(b[18]); b[20]=sin(b[18]);
        b[6]=b[3]+2*PI/a[5]; b[7]=cos(b[6]); b[8]=sin(b[6]);
        b[9]=b[3]+4*PI/a[5]; b[10]=cos(b[9]); b[11]=sin(b[9]);
        b[12]=b[3]+6*PI/a[5]; b[13]=cos(b[12]); b[14]=sin(b[12]);
        b[15]=b[3]+8*PI/a[5]; b[16]=cos(b[15]); b[17]=sin(b[15]);
        c[0]=b[0]*(-a[2]+s*a[3]); c[1]=-1+id*(2/numF); c[2]=.5*c[0]; c[3]=c[1]+sin(t*8)*.1;
        c[4]=-b[5]*c[2]; c[5]=(b[4]*c[2])+c[1]; c[6]=c[0]*b[1]+c[4]*b[2]; c[7]=c[3]*b[1]+c[5]*b[2];
        x[0]=-b[19]*c[7]-b[20]*c[6]; y[0]=b[19]*c[6]-b[20]*c[7];
        c[8]=-b[8]*c[2]; c[9]=(b[7]*c[2])+c[1]; c[10]=c[0]*b[1]+c[8]*b[2]; c[11]=c[3]*b[1]+c[9]*b[2];
        x[1]=-b[19]*c[11]-b[20]*c[10]; y[1]=b[19]*c[10]-b[20]*c[11];
        c[12]=-b[11]*c[2]; c[13]=(b[10]*c[2])+c[1]; c[14]=c[0]*b[1]+c[12]*b[2]; c[15]=c[3]*b[1]+c[13]*b[2];
        x[2]=-b[19]*c[15]-b[20]*c[14]; y[2]=b[19]*c[14]-b[20]*c[15];
        c[16]=-b[14]*c[2]; c[17]=(b[13]*c[2])+c[1]; c[18]=c[0]*b[1]+c[16]*b[2]; c[19]=c[3]*b[1]+c[17]*b[2];
        x[3]=-b[19]*c[19]-b[20]*c[18]; y[3]=b[19]*c[18]-b[20]*c[19];
        c[20]=-b[17]*c[2]; c[21]=(b[16]*c[2])+c[1]; c[22]=c[0]*b[1]+c[20]*b[2]; c[23]=c[3]*b[1]+c[21]*b[2];
        x[4]=-b[19]*c[23]-b[20]*c[22]; y[4]=b[19]*c[22]-b[20]*c[23];
        for (int i=0;i<=4;i++) wsWritePoint(cellIn, cellOut, x[i], y[i], a[8]);
        break;
    }
    case 51: { // Dancing_String (PartiShort.sky.h:170)
        uint rc = 0, rfold = 0;
        float a1 = .7;
        float a3 = .1 + wsRnd(instIdx, algo, u.seed, rc, rfold, .7);
        b[0]=.4*t; b[1]=6.28*(1.3+sin(b[0]*0.414)); b[2]=6.28*(1.3+sin(b[0]*0.628));
        b[3]=b[0]*1.2754; b[4]=b[0]*1.435; b[5]=b[0]*1.643;
        x[0]=a1*cos(s*b[1])*sqrt(0.2*pow(sin(s*3.80+b[4]),2.0) + pow(cos(s*6.28+b[3]),2.0));
        y[0]=a1*sin(s*b[2])*sqrt(pow(sin(s*6.28+b[5]),2.0) + 0.2*pow(cos(s*6.28+b[0]),2.0));
        wsWritePoint(cellIn, cellOut, x[0], y[0], a3);
        break;
    }
    case 52: { // Orbiting_Rods_N_Sticks (PartiShort.sky.h:195)
        uint rc = 0, rfold = 0;
        a[0] = .5 + wsRnd(instIdx, algo, u.seed, rc, rfold, .6);
        a[1] = -.08 - wsRnd(instIdx, algo, u.seed, rc, rfold, .4);
        a[2] = .08 * (1 + wsRnd(instIdx, algo, u.seed, rc, rfold, 4.0));
        a[3] = .3 + wsRnd(instIdx, algo, u.seed, rc, rfold, 2.2);
        b[0] = a[1]*t + 2*PI*(id/numF); b[1] = a[3]*t;
        c[0] = a[2]*(s-.5)*cos(b[1]) + a[0]; c[1] = a[2]*(s-.5)*sin(b[1]);
        x[0] = c[0]*cos(b[0]) - c[1]*sin(b[0]); y[0] = c[1]*cos(b[0]) + c[0]*sin(b[0]);
        wsWritePoint(cellIn, cellOut, x[0], y[0], 1.0);
        break;
    }
    case 53: { // Miris_Ball (PartiShort.sky.h:217) -- STEPS baked representative
        uint rc = 0, rfold = 0;
        a[0] = wsRnd(instIdx, algo, u.seed, rc, rfold, .3) + .1;
        a[1] = wsRnd(instIdx, algo, u.seed, rc, rfold, .9);
        a[2] = wsRnd(instIdx, algo, u.seed, rc, rfold, .9);
        a[3] = ws_clip(.3 + wsRnd(instIdx, algo, u.seed, rc, rfold, .9));
        b[0]=t*a[1]; b[1]=sin(t*a[1]); b[2]=sin(t*a[2]); b[3]=id/numF;
        b[4]=b[3]*a[0]*sin(.8*t); b[5]=b[3]*a[0]*cos(.8*t);
        b[6]=(a[0]-(a[0]*b[3]))*cos(.8*t); b[7]=(a[0]-(a[0]*b[3]))*sin(.8*t);
        c[0]=b[7]*cos(s*PI*2+b[0])+b[1]; c[1]=b[6]*sin(s*PI*2+b[0])+b[2];
        x[0]=(c[0]+b[5])*.54; y[0]=(c[1]+b[4])*.84;
        x[1]=(c[0]-b[5])*.54; y[1]=(c[1]-b[4])*.84;
        for (int i=0;i<=1;i++) wsWritePoint(cellIn, cellOut, x[i], y[i], a[3]);
        break;
    }
    case 54: { // Waves (PartiShort.sky.h:253)
        uint rc = 0, rfold = 0;
        a[0] = 3*PI;
        a[1] = wsRnd(instIdx, algo, u.seed, rc, rfold, .6) + .3;
        a[2] = .8;
        a[3] = wsRnd(instIdx, algo, u.seed, rc, rfold, .3) + .2;
        a[4] = wsRnd(instIdx, algo, u.seed, rc, rfold, 1.5) + 1;
        b[0]=a[3]*t; b[1]=cos(b[0]); b[2]=sin(b[0]);
        c[0]=-1+s*2; c[1]=-.2+a[1]*sin(s*a[0]+t*a[4]);
        c[2]=-b[1]*c[1]-b[2]*c[0]; c[3]=b[1]*c[0]-b[2]*c[1];
        x[1]=pow(a[2],1.0)*c[2]; y[1]=pow(a[2],1.0)*c[3];
        x[2]=pow(a[2],2.0)*c[2]; y[2]=pow(a[2],2.0)*c[3];
        x[3]=pow(a[2],3.0)*c[2]; y[3]=pow(a[2],3.0)*c[3];
        x[4]=pow(a[2],4.0)*c[2]; y[4]=pow(a[2],4.0)*c[3];
        x[5]=pow(a[2],5.0)*c[2]; y[5]=pow(a[2],5.0)*c[3];
        x[6]=pow(a[2],6.0)*c[2]; y[6]=pow(a[2],6.0)*c[3];
        x[7]=pow(a[2],7.0)*c[2]; y[7]=pow(a[2],7.0)*c[3];
        x[8]=pow(a[2],8.0)*c[2]; y[8]=pow(a[2],8.0)*c[3];
        x[0]=pow(a[2],9.0)*c[2]; y[0]=pow(a[2],9.0)*c[3];
        float col = .5+uy;
        for (int i=0;i<=8;i++) wsWritePoint(cellIn, cellOut, x[i], y[i], col);
        break;
    }
    case 55: { // DNA_String (PartiShort.sky.h:287)
        uint rc = 0, rfold = 0;
        a[0]=4.0; a[1]=kSampleSteps/a[0]; a[2]=PI/4; a[3]=2*a[2]; a[4]=a[3]/a[1];
        a[5] = wsRnd(instIdx, algo, u.seed, rc, rfold, .4) + .4;
        a[6]=a[5]/(a[0]-1); a[7]=a[5]/2; a[8]=6.0; a[9]=a[8]*(.9);
        a[11] = wsRnd(instIdx, algo, u.seed, rc, rfold, .4) - .2;
        a[12] = (wsRnd(instIdx, algo, u.seed, rc, rfold, 1.0) + .5) * ws_sgn(wsRnd(instIdx, algo, u.seed, rc, rfold, 1.0) - .5);
        a[16] = .7 + wsRnd(instIdx, algo, u.seed, rc, rfold, .4);
        b[10]=PI/2+.3; b[13]=.25+ux; b[14]=cos(b[10]); b[15]=sin(b[10]);
        b[0]=t*a[11]; b[1]=cos(b[0]); b[2]=sin(b[0]);
        c[0]=ws_trnc(s*kSampleSteps/a[0]);
        c[1]=ws_trnc(s*kSampleSteps)-(a[0]*c[0]);
        c[2]=-a[7]+(c[1]*a[6]); c[3]=(t*a[12])+(c[0]*b[13]);
        c[4]=-sin(c[3])*c[2]; c[5]=cos(c[3])*c[2];
        c[6]=c[5]*b[14]; c[7]=a[8]-c[5]*b[15];
        c[8]=a[9]*c[4]/c[7]; c[9]=(a[9]*c[6]/c[7])-a[2]+c[0]*a[4];
        x[0]=-b[1]*c[9]-b[2]*c[8]; y[0]=b[1]*c[8]-b[2]*c[9];
        wsWritePoint(cellIn, cellOut, x[0], y[0], a[16]);
        break;
    }
    case 56: { // Sea_Surface (PartiShort.sky.h:343) -- STEPS baked representative
        uint rc = 0, rfold = 0;
        a[0] = ws_trnc(sqrt(kSampleSteps));
        a[1] = wsRnd(instIdx, algo, u.seed, rc, rfold, 2*PI);
        a[2] = (.6 + wsRnd(instIdx, algo, u.seed, rc, rfold, 1.0)) * cos(a[1]);
        a[3] = (.6 + wsRnd(instIdx, algo, u.seed, rc, rfold, 1.0)) * sin(a[1]);
        a[4] = 6.0; a[5] = a[4]*1.2;
        a[6] = 1.8 + wsRnd(instIdx, algo, u.seed, rc, rfold, .5);
        b[0]=t*.15; b[1]=cos(b[0]); b[2]=sin(b[0]); b[3]=sin(a[6]); b[4]=cos(a[6]);
        c[0]=2*(fmod(s*kSampleSteps-1,a[0]))/a[0]-1;
        c[1]=2*(ws_trnc((s*kSampleSteps-1)/a[0]))/a[0]-1;
        c[2]=.18*sin(6*c[0]+a[2]*t)*cos(6*c[1]+a[3]*t);
        c[3]=-b[1]*c[1]-b[2]*c[0]; c[4]=b[1]*c[0]-b[2]*c[1];
        c[5]=c[4]*b[4]+c[2]*b[3]; c[6]=a[4]-c[4]*b[3]+c[2]*b[4];
        x[0]=a[5]*c[3]/c[6]; y[0]=a[5]*c[5]/c[6];
        wsWritePoint(cellIn, cellOut, x[0], y[0], .5+uy);
        break;
    }
    case 57: { // Pollock_Dots (PartiShort.sky.h:390) -- selection anchor, 2 instances
        uint rc = 0, rfold = 0;
        float a0 = u.selectT; float a1 = 1.6;
        (void)wsRnd(instIdx, algo, u.seed, rc, rfold, 4.0); // a3: dot-size, width-only, dropped
        b[0]=1.5-a1*(t-a0); b[1]=sin(b[0])/4; b[2]=cos(1.3*sin(.3*(t-a0))+.3);
        x[0]=(2*s-1)+(b[1]*sgnid); y[0]=b[2]*sgnid+(0.04*sgnid);
        wsWritePoint(cellIn, cellOut, x[0], y[0], 1.0);
        break;
    }
    case 58: { // Pop_Circles (PartiShort.sky.h:410) -- selection anchor
        uint rc = 0, rfold = 0;
        float a0 = u.selectT;
        b[0]=t*.00025;
        (void)wsSeed(a0*id, rfold); // b1: side-effect only, unused value
        b[2]=wsRnd(instIdx, algo, u.seed, rc, rfold, 2.0)-1;
        b[3]=wsRnd(instIdx, algo, u.seed, rc, rfold, 2.0)-1;
        b[4]=wsRnd(instIdx, algo, u.seed, rc, rfold, 6.0)+4;
        b[5]=exp((t-a0-b[4])*2)+.01;
        c[0]=s*2*PI+b[0];
        x[0]=b[5]*cos(c[0])+b[2]; y[0]=b[5]*sin(c[0])+b[3];
        wsWritePoint(cellIn, cellOut, x[0], y[0], 1.0);
        break;
    }
    case 59: { // Raindrops (PartiShort.sky.h:431)
        uint rc = 0, rfold = 0;
        float col = pow(wsRnd(instIdx, algo, u.seed, rc, rfold, 1.0), 6.0) * 11 + 1;
        x[0] = wsRnd(instIdx, algo, u.seed, rc, rfold, 2.0) - 1;
        y[0] = wsRnd(instIdx, algo, u.seed, rc, rfold, 2.0) - 1;
        (void)col; // width-only in source; color argument was fixed .3
        wsWritePoint(cellIn, cellOut, x[0], y[0], .3);
        break;
    }
    case 60: { // Protozoan_Lovers (PartiShort.sky.h:442) -- selection anchor, STEPS baked
        uint rc = 0, rfold = 0;
        float a0 = u.selectT;
        (void)wsSeed(a0*(id/numF+5.5), rfold); // b0: side-effect only
        float b1 = wsRnd(instIdx, algo, u.seed, rc, rfold, .8) + .2;
        float b2 = wsRnd(instIdx, algo, u.seed, rc, rfold, .8) + .2;
        c[0] = .8*t - s/2;
        x[0] = sin(c[0]*b1)*0.90 + sin(c[0]*5)*0.075;
        y[0] = cos(c[0]*b2)*0.90 + cos(c[0]*6)*0.075;
        wsWritePoint(cellIn, cellOut, x[0], y[0], ws_clip(1.2-s));
        break;
    }
    case 61: { // Snakes (PartiShort.sky.h:463) -- selection anchor
        uint rc = 0, rfold = 0;
        float a0 = u.selectT;
        float b1 = ux*32.0; b1 = (fabs(b1) < 1e-4) ? ((b1 < 0.0) ? -1e-4 : 1e-4) : b1;
        (void)wsSeed(a0*id, rfold); // c0: side-effect only
        c[1]=wsRnd(instIdx, algo, u.seed, rc, rfold, 2.0)-1;
        c[2]=wsRnd(instIdx, algo, u.seed, rc, rfold, .3)+.2;
        c[3]=wsRnd(instIdx, algo, u.seed, rc, rfold, 1.0);
        c[4]=wsRnd(instIdx, algo, u.seed, rc, rfold, 3.141);
        c[5]=2*(t-a0)/b1-c[3]-s*c[2];
        c[6]=(c[1]+0.14*sin(18*c[5]/c[2]+t*8+c[4])*c[2])*3.141;
        c[7]=ws_pos(c[5])*2;
        x[0]=cos(c[6])*c[7]; y[0]=sin(c[6])*c[7];
        wsWritePoint(cellIn, cellOut, x[0], y[0], .6);
        break;
    }
    case 62: { // Spiral (PartiShort.sky.h:490)
        a[0] = 2*PI*15;
        b[0] = ws_sgn(sin(t*.2))*t*10; b[1] = .2*sin(t*.4);
        c[0]=s*a[0]+b[0]; c[1]=s*s+b[1];
        x[0]=cos(c[0])*c[1]; y[0]=sin(c[0])*c[1];
        wsWritePoint(cellIn, cellOut, x[0], y[0], ws_clip(1.1-pow(s,4.0)));
        break;
    }
    case 63: { // Tosser (PartiShort.sky.h:509)
        uint rc = 0, rfold = 0;
        a[0] = ws_trnc(sqrt(kSampleSteps));
        a[1] = sin(-2.14*.35 + ws_wrap(wsTimeEnd(u) - t));
        a[2] = cos(-2.14*.35 + ws_wrap(wsTimeEnd(u) - t));
        a[4] = 8 * (.4 + wsRnd(instIdx, algo, u.seed, rc, rfold, .7));
        a[5] = .7;
        a[7] = kSampleSteps - 1;
        b[0] = sin(t*a[5]); b[1] = cos(t*a[5]);
        float b8 = wsMag(magBuf, u.magCount, s)*ux*20; // NOTE(port): source samples `s`
        // in the frame-phase before the step loop defines it (stale-`s` read in the
        // original engine); this thread's own s is the only sensible stand-in.
        c[0]=2*(fmod(s*a[7]+.005,a[0]))/a[0]-1;
        c[1]=2*(ws_trnc(s*a[7]/a[0]))/a[0]-1;
        c[2]=c[0]*a[1]-c[1]*b[0]; c[3]=c[0]*b[0]+c[1]*b[1];
        c[4]=a[4]/(10-c[3]*a[1]);
        x[0]=c[2]*c[4]; y[0]=c[3]*a[2]*c[4];
        (void)b8; // width-only in source
        wsWritePoint(cellIn, cellOut, x[0], y[0], .5+uy);
        break;
    }
    case 64: { // Typhoon (PartiShort.sky.h:539)
        uint rc = 0, rfold = 0;
        a[0]=2*PI; a[1]=5*a[0]; a[2]=.8; a[3]=6.0; a[4]=a[3]*.9; a[5]=PI/2; a[6]=.7; a[7]=-.8;
        a[8]=ws_dabs(2*a[7])-.2;
        a[9]=wsRnd(instIdx, algo, u.seed, rc, rfold, .2)+.2;
        a[10]=.5; a[11]=a[5]+.3;
        b[0]=a[6]*t; b[1]=cos(b[0]); b[2]=sin(b[0]); b[3]=sin(a[11]); b[4]=cos(a[11]);
        b[5]=t*a[9]; b[6]=cos(b[5]); b[7]=sin(b[5]); b[8]=(t*b[7]*.000005)-a[5]; b[9]=cos(b[8]); b[10]=sin(b[8]);
        c[0]=s; c[1]=c[0]*a[1]; c[2]=cos(c[1]); c[3]=sin(c[1]); c[4]=c[0]*a[2];
        c[5]=c[4]*c[2]; c[6]=c[4]*c[3];
        c[7]=-b[1]*c[6]-b[2]*c[5]; c[8]=b[1]*c[5]-b[2]*c[6];
        c[9]=c[8]*b[4]; c[10]=a[3]-c[8]*b[3];
        c[11]=a[4]*c[7]/c[10]; c[12]=a[4]*c[9]/c[10]+c[0]*a[8];
        c[13]=-b[9]*c[12]-b[10]*c[11]; c[14]=b[9]*c[11]-b[10]*c[12];
        x[0]=c[13]+b[7]*a[10]; y[0]=c[14]+a[7];
        c[15]=20-((c[10]-5)*15);
        float col = wsFft(fftBuf, u.fftCount, s)*ux+uy;
        (void)c[15]; // width-only in source
        wsWritePoint(cellIn, cellOut, x[0], y[0], col);
        break;
    }
    case 65: { // Uber_Spirograph (PartiShort.sky.h:605)
        a[0] = PI*2;
        x[0] = .5*(sin(s*a[0])+sin(s*PI*t)); y[0] = .5*(cos(s*a[0])+cos(s*PI*t));
        wsWritePoint(cellIn, cellOut, x[0], y[0], .5+uy);
        break;
    }
    case 66: { // Crosshatch (PartiShort.sky.h:617)
        uint rc = 0, rfold = 0;
        a[0] = wsRnd(instIdx, algo, u.seed, rc, rfold, PI-1) + 2;
        a[1] = wsRnd(instIdx, algo, u.seed, rc, rfold, 8.0) + 2;
        a[2] = ws_sgn(wsRnd(instIdx, algo, u.seed, rc, rfold, 2.0) - 1);
        a[3] = wsRnd(instIdx, algo, u.seed, rc, rfold, 3.0) + 2;
        a[4] = wsRnd(instIdx, algo, u.seed, rc, rfold, 3.0) + 2;
        a[6] = .04 + wsRnd(instIdx, algo, u.seed, rc, rfold, .1);
        c[0]=s*a[1]+t/a[3]; c[1]=ws_trwv(c[0]); c[2]=sin(a[0]*c[0]+t/a[4]);
        x[0]=c[1]; y[0]=c[2];
        x[1]=-c[1]; y[1]=a[2]*c[2];
        for (int i=0;i<=1;i++) wsWritePoint(cellIn, cellOut, x[i], y[i], a[6]);
        break;
    }
    case 67: { // Juggler (PartiShort.sky.h:643)
        uint rc = 0, rfold = 0;
        a[0] = .4 + wsRnd(instIdx, algo, u.seed, rc, rfold, .6);
        a[1] = ws_sgn(wsRnd(instIdx, algo, u.seed, rc, rfold, 2.0) - 1) * (.1 + wsRnd(instIdx, algo, u.seed, rc, rfold, .3));
        a[2] = .08 * (1 + wsRnd(instIdx, algo, u.seed, rc, rfold, 7.0));
        a[3] = ws_sgn(wsRnd(instIdx, algo, u.seed, rc, rfold, 2.0) - 1) * (.5 + wsRnd(instIdx, algo, u.seed, rc, rfold, 1.0));
        a[4] = ws_trnc(wsRnd(instIdx, algo, u.seed, rc, rfold, 16.0) * 4 + 4) * PI / numF;
        b[0]=a[1]*t+2*PI*(id/numF); b[1]=a[3]*t;
        b[2]=a[0]*sin(t/2+a[4]*id); b[3]=a[2]*sin(t/2+a[4]*id);
        c[0]=b[3]*(s-.5)*cos(b[1])+b[2]; c[1]=b[3]*(s-.5)*sin(b[1]);
        x[0]=c[0]*cos(b[0])-c[1]*sin(b[0]); y[0]=c[1]*cos(b[0])+c[0]*sin(b[0]);
        wsWritePoint(cellIn, cellOut, x[0], y[0], 1.0);
        break;
    }

    default: break;
    }
}

