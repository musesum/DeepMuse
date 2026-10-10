#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct RouterSource {
    float4 route;  // front outputs, front z order, back outputs, back z order;
                   // outputs are a set of bits: 1 raw, 2 pal (the cell rule), 4 SD-Turbo
    float4 fade;   // front fade, has mask, has texture, back fade
    float4 part;   // front part, back part: 1 F the subject the mask cuts out,
                   // 2 B the rest of the frame, 3 F+B the whole frame unmasked
};
struct RouterUniforms {
    float4 pass;   // x = the output bit this pass composites: 1 real color, 2 cell rule;
                   // y camera, z album: 1 = its front and back drawn as one layer
    RouterSource draw;
    RouterSource camera;
    RouterSource album;
    float4 luma;   // the pal disk mix (LumaMix): x real key level, y pal key level,
                   // z 1 keys from the black end, 0 the white; w 0 unmixed, 1 real over
                   // pal, 2 pal over real (router pass only)
    float4 curve;  // the mix key's cut edge: x its half width (LumaMix.band)
    float4 range;  // each layer's measured luma range: x y real lo hi, z w pal lo hi
    float4 blend;  // canvas.mix's fade where pal is over a raw camera (router pass):
                   // x pal 0 to camera 1; y 1 = the pal layer thins over the camera
                   // by it, and the camera's paths come unfaded by it
};

/// is a path with these outputs composited by this pass
static bool routed(float outputs, float pass) {
    return (uint(outputs) & uint(pass)) != 0;
}

/// how much of the frame a path's part keeps at mask m: F the subject, B the
/// rest, F+B all of it, unmasked. No mask yet (Vision still running, or the
/// mask failed): any part shows the whole frame
static float cover(float part, float m, bool hasMask) {
    if (!hasMask || part > 2.5) return 1;
    return part < 1.5 ? m : 1 - m;
}

/// one route over `color`: the source cut to the part of the frame it carries,
/// faded by its own lane (its z, the layers slider = that path's opacity)
static float4 routeOver(float4 color, float4 src, float layer, float laneFade) {
    float a = laneFade * layer * src.a;
    return float4(mix(color.rgb, src.rgb, a), max(color.a, a));
}

/// the standard normal's cumulative: Abramowitz and Stegun 7.1.26 for erf,
/// within 1.5e-7
static float gaussCdf(float x) {
    float z = fabs(x) * 0.70710678;
    float t = 1 / (1 + 0.3275911 * z);
    float poly = ((((1.061405429 * t - 1.453152027) * t + 1.421413741) * t - 0.284496736) * t + 0.254829592) * t;
    return 0.5 * (1 + sign(x) * (1 - poly * exp(-z * z)));
}

/// one simdgroup's min and max into stats[i], stats[i+1], quantized 0…65535;
/// a pixel outside the layer offers nothing
static void lumaStat(device atomic_uint* stats, uint i, float luma, bool inside) {
    uint q = uint(luma * 65535);
    uint lo = simd_min(inside ? q : 65535u);
    uint hi = simd_max(inside ? q : 0u);
    if (simd_is_first()) {
        atomic_fetch_min_explicit(&stats[i], lo, memory_order_relaxed);
        atomic_fetch_max_explicit(&stats[i + 1], hi, memory_order_relaxed);
    }
}

/// the part of a layer the pal disk mix keeps: the OG luma key's cut, from
/// the white end (whites go first as the level drops) or the black end;
/// level 1 keeps it all, 0 none. The cut's edge is a Gaussian spread held to
/// `band` either side and rescaled to run 1…0 across it, so past the band
/// the layer is whole or gone as before: 1/32, the old smoothstep's, at
/// breadth 0, within 0.0102. LumaMix.keep
static float lumaOf(float3 rgb) { return saturate(dot(rgb, float3(0.299, 0.587, 0.114))); }

/// `range` the layer's own luma lo hi: the cut runs over what the layer holds
static float lumaKeep(float3 rgb, float level, bool black, float band, float2 range) {
    if (level >= 1) return 1;
    constexpr float a = 1.0 / 0.52773;    // band / sigma, LumaMix.sigmaPerBand
    float luma = saturate((lumaOf(rgb) - range.x) / max(range.y - range.x, 0.05));
    float u = black ? 1 - luma : luma;
    float c = level * (1 + 2 * band) - band;
    float x = (u - c) / max(band, 1e-4); // -1…1 across the edge
    if (x <= -1) return 1;
    if (x >= 1) return 0;
    float lo = gaussCdf(-a);
    return 1 - (gaussCdf(x * a) - lo) / (1 - 2 * lo);
}

/// real color built up premultiplied over clear: `a` of `rgb` over what is there
static float4 premulOver(float4 acc, float3 rgb, float a) {
    return float4(rgb * a + acc.rgb * (1 - a), a + acc.a * (1 - a));
}

/// a masked source's coverage at z in this pass, for the real layer: its front
/// and back lanes where each sits, or, joined, the one layer at the lower z
static float sourceAlpha(float4 src, float m, constant RouterSource& s,
                         bool joined, int z, float pass) {
    if (joined) {
        if (float(z) != min(s.route.y, s.route.w)) return 0;
        return (s.fade.x * cover(s.part.x, m, true) + s.fade.w * cover(s.part.y, m, true)) * src.a;
    }
    bool hasMask = s.fade.y > 0.5;
    float front = (s.route.y == z && routed(s.route.x, pass)) ? s.fade.x * cover(s.part.x, m, hasMask) * src.a : 0;
    float back  = (s.route.w == z && routed(s.route.z, pass)) ? s.fade.w * cover(s.part.y, m, hasMask) * src.a : 0;
    return 1 - (1 - front) * (1 - back);
}

/// a masked source's two lanes, each over `color` at its own z; or, joined
/// (RouterNode.joined: both lanes in this pass, one on F and one on B, no
/// visible route between them), one layer at the lower z with coverage
/// front·m + back·(1−m): nothing beneath shows through the mask's soft edge,
/// and front 1 back 1 is the whole frame. A lane on F+B is the frame unmasked
static float4 routeSource(float4 color, float4 src, float m, constant RouterSource& s,
                          bool joined, int z, float pass) {
    if (joined) {
        if (float(z) != min(s.route.y, s.route.w)) return color;
        float a = (s.fade.x * cover(s.part.x, m, true) + s.fade.w * cover(s.part.y, m, true)) * src.a;
        return float4(mix(color.rgb, src.rgb, a), max(color.a, a));
    }
    bool hasMask = s.fade.y > 0.5;
    if (s.route.y == z && routed(s.route.x, pass))
        color = routeOver(color, src, cover(s.part.x, m, hasMask), s.fade.x);
    if (s.route.w == z && routed(s.route.z, pass))
        color = routeOver(color, src, cover(s.part.y, m, hasMask), s.fade.w);
    return color;
}

kernel void routerKernel
(
 texture2d<float, access::read>  inTex     [[ texture(0) ]],
 texture2d<float, access::write> outTex    [[ texture(1) ]],
 texture2d<float>                drawTex   [[ texture(2) ]],
 texture2d<float>                camTex    [[ texture(3) ]],
 texture2d<float>                camMask   [[ texture(4) ]],
 texture2d<float>                albumTex  [[ texture(5) ]],
 texture2d<float>                albumMask [[ texture(6) ]],
 constant RouterUniforms&        u         [[ buffer(0) ]],
 device atomic_uint*             stats     [[ buffer(1) ]], // real lo hi, pal lo hi
 uint2 gid [[ thread_position_in_grid ]])
{
    float2 norm = (float2(gid) + 0.5) / float2(outTex.get_width(), outTex.get_height());
    constexpr sampler samplr(filter::linear, address::clamp_to_edge);
    float pass = u.pass.x;
    // in the router pass the base is the pal canvas — draw's back lane —
    // so it composites at its own z by its filter instead of always underlying
    bool palLane = pass == 1.0;
    float4 basePix = inTex.read(gid);
    float4 color = palLane ? float4(0) : basePix;

    float4 drawPix = u.draw.fade.z > 0.5 ? drawTex.sample(samplr, norm) : float4(0);
    float4 camPix = u.camera.fade.z > 0.5 ? camTex.sample(samplr, norm) : float4(0);
    float camM = u.camera.fade.y > 0.5 ? camMask.sample(samplr, norm).r : 0;
    float4 albumPix = u.album.fade.z > 0.5 ? albumTex.sample(samplr, norm) : float4(0);
    float albumM = u.album.fade.y > 0.5 ? albumMask.sample(samplr, norm).r : 0;
    // the pal disk mix (router pass): two whole layers over the black backdrop,
    // real = every real color route in its z order, pal = the pal canvas,
    // the one on top over the other, each at its lane opacity times the part
    // its own luma key's curve keeps; the pal canvas's z is the mix's to choose
    if (palLane && u.luma.w > 0.5) {
        float4 real = float4(0); // premultiplied over clear
        float camShare = 0;      // the camera's visible share of it: what is over it takes its part
        for (int z = 1; z <= 6; z++) {
            if (u.draw.fade.z > 0.5 && u.draw.route.y == z && routed(u.draw.route.x, pass)) {
                float a = u.draw.fade.x * drawPix.a;
                real = premulOver(real, drawPix.rgb, a);
                camShare *= 1 - a;
            }
            if (u.camera.fade.z > 0.5) {
                float a = sourceAlpha(camPix, camM, u.camera, u.pass.y > 0.5, z, pass);
                real = premulOver(real, camPix.rgb, a);
                camShare = a + camShare * (1 - a);
            }
            if (u.album.fade.z > 0.5) {
                float a = sourceAlpha(albumPix, albumM, u.album, u.pass.z > 0.5, z, pass);
                real = premulOver(real, albumPix.rgb, a);
                camShare *= 1 - a;
            }
        }
        bool black = u.luma.z > 0.5;
        float3 realRgb = real.a > 0 ? real.rgb / real.a : float3(0);
        float realA = real.a * lumaKeep(realRgb, u.luma.x, black, u.curve.x, u.range.xy);
        bool palShown = routed(u.draw.route.z, 3); // on raw, on pal, or on both
        float palA = palShown ? u.draw.fade.w * basePix.a * lumaKeep(basePix.rgb, u.luma.y, black, u.curve.x, u.range.zw) : 0;
        // canvas.mix's fade with pal over a raw camera: the pal thins over the
        // camera alone, pal·(1−x) + camera·x where the camera is whole; over the
        // strokes and the album it stays as it is. With real over pal the fade
        // is on the camera's paths already. RouterNode.palOverCamera
        if (u.blend.y > 0.5)
            palA *= 1 - u.blend.x * camShare;
        lumaStat(stats, 0, lumaOf(realRgb), real.a > 0.02);
        lumaStat(stats, 2, lumaOf(basePix.rgb), palShown && basePix.a > 0.02);
        float3 out = float3(0); // the backdrop
        if (u.luma.w < 1.5) {   // real over pal
            out = mix(out, basePix.rgb, palA);
            out = mix(out, realRgb, realA);
        } else {                // pal over real
            out = mix(out, realRgb, realA);
            out = mix(out, basePix.rgb, palA);
        }
        outTex.write(float4(out, 1), gid);
        return;
    }

    // bottom z first; six routes, each at its own z
    for (int z = 1; z <= 6; z++) {
        // draw: front = the real strokes, back = the pal canvas
        if (u.draw.fade.z > 0.5 && u.draw.route.y == z && routed(u.draw.route.x, pass))
            color = routeOver(color, drawPix, 1, u.draw.fade.x);
        // the pal canvas: composited whole, faded by the back lane's own z;
        // it is the cell rule's colored output, so Raw (1) and Pal (2) both show it
        if (palLane && u.draw.route.w == z && routed(u.draw.route.z, 3))
            color = routeOver(color, basePix, 1, u.draw.fade.w);
        // camera, then album
        if (u.camera.fade.z > 0.5)
            color = routeSource(color, camPix, camM, u.camera, u.pass.y > 0.5, z, pass);
        if (u.album.fade.z > 0.5)
            color = routeSource(color, albumPix, albumM, u.album, u.pass.z > 0.5, z, pass);
    }
    // the visible pass is the final image: opaque, so the render blend does not
    // multiply by alpha again; the feed pass keeps alpha, the index layer's data
    outTex.write(palLane ? float4(color.rgb, 1) : color, gid);
}
