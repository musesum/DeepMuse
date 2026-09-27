#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

/// tile-style mirror inside one frame: 0 none … 1 full reflection
static float mirrored(float t, float m) {
    float span = 1 + m;
    float u = fmod(t * span, span);
    if (u > 1) { u = (span - u) / fmax(0.0001, m); }
    return u;
}

/// photo strip: up to 8 frames side by side (axis 0) or stacked (axis 1), each at its
/// own aspect scaled to the strip's across span (units: across span = 1). The output
/// is a window of that strip; offset.x slides the window along the strip and wraps at
/// the strip's end, offset.y slides across and wraps — a continuous feed on the torus.
kernel void stripKernel
(
 texture2d<float, access::write>  outTex  [[ texture(1) ]],
 array<texture2d<float>, 8>       frames  [[ texture(2) ]],
 constant float&                  axis    [[ buffer(0)  ]], // 0 horizontal, 1 vertical
 constant float2&                 offset  [[ buffer(1)  ]],
 constant float&                  count   [[ buffer(2)  ]],
 constant float2&                 mirror  [[ buffer(3)  ]],
 constant float*                  aspects [[ buffer(4)  ]], // width / height per frame
 uint2 gid [[ thread_position_in_grid ]])
{
    float2 outSize = float2(outTex.get_width(), outTex.get_height());
    float2 norm = (float2(gid) + 0.5) / outSize;
    int n = clamp(int(count), 1, 8);
    bool horizontal = axis < 0.5;
    float along  = horizontal ? norm.x : norm.y;
    float across = horizontal ? norm.y : norm.x;
    float window = horizontal ? outSize.x / outSize.y : outSize.y / outSize.x;

    float lens[8];
    float total = 0;
    for (int i = 0; i < n; i++) {
        float a = fmax(0.01, aspects[i]);
        lens[i] = horizontal ? a : 1 / a;
        total += lens[i];
    }
    float pos = fmod(along * window + offset.x, total);
    if (pos < 0) { pos += total; }
    int idx = 0;
    float start = 0;
    for (int i = 0; i < n; i++) {
        if (pos < start + lens[i] || i == n - 1) { idx = i; break; }
        start += lens[i];
    }
    float u = clamp((pos - start) / lens[idx], 0.0, 1.0);
    float v = fract(across + offset.y);
    float2 local = horizontal ? float2(u, v) : float2(v, u);
    local.x = mirrored(local.x, mirror.x);
    local.y = mirrored(local.y, mirror.y);
    constexpr sampler samplr(filter::linear, address::clamp_to_edge);
    outTex.write(frames[idx].sample(samplr, local), gid);
}
