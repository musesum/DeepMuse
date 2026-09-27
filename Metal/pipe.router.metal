#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct RouterSource {
    float4 route;  // front filter, front z order, back filter, back z order
    float4 fade;   // front fade, has mask, has texture, back fade
};
struct RouterUniforms {
    float4 pass;   // x = filter this pass composites: 1 real color, 3 cell rule;
                   // y camera, z album: 1 = its front and back drawn as one layer
    RouterSource draw;
    RouterSource camera;
    RouterSource album;
    float4 luma;   // the false disk mix (LumaMix): x real key level, y false key level,
                   // z 1 keys from the black end, 0 the white; w 0 unmixed, 1 real over
                   // false, 2 false over real (router pass only)
    float4 curve;  // the mix key's cut edge: x its half width (LumaMix.band)
};

/// one route over `color`: the source cut to its front or back by the mask,
/// faded by its own lane (its z, the layers slider = that path's opacity).
/// No mask yet (Vision still running, or the mask failed): either lane shows the whole frame
static float4 routeOver(float4 color, float4 src, float mask, bool hasMask, bool front,
                        float laneFade) {
    float layer = hasMask ? (front ? mask : 1 - mask) : 1;
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

/// the part of a layer the false disk mix keeps: the OG luma key's cut, from
/// the white end (whites go first as the level drops) or the black end;
/// level 1 keeps it all, 0 none. The cut's edge is a Gaussian spread held to
/// `band` either side and rescaled to run 1…0 across it, so past the band
/// the layer is whole or gone as before: 1/32, the old smoothstep's, at
/// breadth 0, within 0.0102. LumaMix.keep
static float lumaKeep(float3 rgb, float level, bool black, float band) {
    if (level >= 1) return 1;
    constexpr float a = 1.0 / 0.52773;    // band / sigma, LumaMix.sigmaPerBand
    float luma = saturate(dot(rgb, float3(0.299, 0.587, 0.114)));
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
        return (s.fade.x * m + s.fade.w * (1 - m)) * src.a;
    }
    bool hasMask = s.fade.y > 0.5;
    float front = (s.route.y == z && s.route.x == pass) ? s.fade.x * (hasMask ? m : 1) * src.a : 0;
    float back  = (s.route.w == z && s.route.z == pass) ? s.fade.w * (hasMask ? 1 - m : 1) * src.a : 0;
    return 1 - (1 - front) * (1 - back);
}

/// a masked source's two lanes, each over `color` at its own z; or, joined
/// (RouterNode.joined: both lanes in this pass, no visible route between them),
/// one layer at the lower z with coverage front·m + back·(1−m): nothing beneath
/// shows through the mask's soft edge, and front 1 back 1 is the whole frame
static float4 routeSource(float4 color, float4 src, float m, constant RouterSource& s,
                          bool joined, int z, float pass) {
    if (joined) {
        if (float(z) != min(s.route.y, s.route.w)) return color;
        float a = (s.fade.x * m + s.fade.w * (1 - m)) * src.a;
        return float4(mix(color.rgb, src.rgb, a), max(color.a, a));
    }
    bool hasMask = s.fade.y > 0.5;
    if (s.route.y == z && s.route.x == pass)
        color = routeOver(color, src, m, hasMask, true, s.fade.x);
    if (s.route.w == z && s.route.z == pass)
        color = routeOver(color, src, m, hasMask, false, s.fade.w);
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
 uint2 gid [[ thread_position_in_grid ]])
{
    float2 norm = (float2(gid) + 0.5) / float2(outTex.get_width(), outTex.get_height());
    constexpr sampler samplr(filter::linear, address::clamp_to_edge);
    float pass = u.pass.x;
    // in the router pass the base is the false canvas — draw's back lane —
    // so it composites at its own z by its filter instead of always underlying
    bool falseLane = pass == 1.0;
    float4 basePix = inTex.read(gid);
    float4 color = falseLane ? float4(0) : basePix;

    float4 drawPix = u.draw.fade.z > 0.5 ? drawTex.sample(samplr, norm) : float4(0);
    float4 camPix = u.camera.fade.z > 0.5 ? camTex.sample(samplr, norm) : float4(0);
    float camM = u.camera.fade.y > 0.5 ? camMask.sample(samplr, norm).r : 0;
    float4 albumPix = u.album.fade.z > 0.5 ? albumTex.sample(samplr, norm) : float4(0);
    float albumM = u.album.fade.y > 0.5 ? albumMask.sample(samplr, norm).r : 0;
    // the false disk mix (router pass): two whole layers over the black backdrop,
    // real = every real color route in its z order, false = the false canvas,
    // the one on top over the other, each at its lane opacity times the part
    // its own luma key's curve keeps; the false canvas's z is the mix's to choose
    if (falseLane && u.luma.w > 0.5) {
        float4 real = float4(0); // premultiplied over clear
        for (int z = 1; z <= 6; z++) {
            if (u.draw.fade.z > 0.5 && u.draw.route.y == z && u.draw.route.x == pass)
                real = premulOver(real, drawPix.rgb, u.draw.fade.x * drawPix.a);
            if (u.camera.fade.z > 0.5)
                real = premulOver(real, camPix.rgb, sourceAlpha(camPix, camM, u.camera, u.pass.y > 0.5, z, pass));
            if (u.album.fade.z > 0.5)
                real = premulOver(real, albumPix.rgb, sourceAlpha(albumPix, albumM, u.album, u.pass.z > 0.5, z, pass));
        }
        bool black = u.luma.z > 0.5;
        float3 realRgb = real.a > 0 ? real.rgb / real.a : float3(0);
        float realA = real.a * lumaKeep(realRgb, u.luma.x, black, u.curve.x);
        bool falseShown = u.draw.route.z == 1 || u.draw.route.z == 3;
        float falseA = falseShown ? u.draw.fade.w * basePix.a * lumaKeep(basePix.rgb, u.luma.y, black, u.curve.x) : 0;
        float3 out = float3(0); // the backdrop
        if (u.luma.w < 1.5) {   // real over false
            out = mix(out, basePix.rgb, falseA);
            out = mix(out, realRgb, realA);
        } else {                // false over real
            out = mix(out, realRgb, realA);
            out = mix(out, basePix.rgb, falseA);
        }
        outTex.write(float4(out, 1), gid);
        return;
    }

    // bottom z first; six routes, each at its own z
    for (int z = 1; z <= 6; z++) {
        // draw: front = the real strokes, back = the false canvas
        if (u.draw.fade.z > 0.5 && u.draw.route.y == z && u.draw.route.x == pass)
            color = routeOver(color, drawPix, 0, false, true, u.draw.fade.x);
        // the false canvas: composited whole, faded by the back lane's own z;
        // it is the cell rule's colored output, so Raw (1) and Cell (3) both show it
        if (falseLane && u.draw.route.w == z && (u.draw.route.z == 1 || u.draw.route.z == 3))
            color = routeOver(color, basePix, 0, false, true, u.draw.fade.w);
        // camera, then album
        if (u.camera.fade.z > 0.5)
            color = routeSource(color, camPix, camM, u.camera, u.pass.y > 0.5, z, pass);
        if (u.album.fade.z > 0.5)
            color = routeSource(color, albumPix, albumM, u.album, u.pass.z > 0.5, z, pass);
    }
    // the visible pass is the final image: opaque, so the render blend does not
    // multiply by alpha again; the feed pass keeps alpha, the index layer's data
    outTex.write(falseLane ? float4(color.rgb, 1) : color, gid);
}
