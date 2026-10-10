#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

// Dot overlay data (color = 0..255)
struct Dot {
    float2 p;       // center in pixels (after shift space)
    float radius;  // -1 index-layer fill, -2 real-layer clear, 0...64 size
    float color;   // 0..255 palette index
};

kernel void drawDotKernel
(
 texture2d<half, access::read>   inTex   [[ texture(0) ]],
 texture2d<half, access::write>  outTex  [[ texture(1) ]],
 constant float2&                shift   [[ buffer(0) ]], // canvas.shift / pipe.draw.shift, index (pal) layer
 constant uint&                  aspect  [[ buffer(1) ]],
 device const Dot*               dots    [[ buffer(2) ]],
 constant uint&                  dotCount[[ buffer(3) ]],
 uint2 gid [[thread_position_in_grid]]
 )
{
    int w = inTex.get_width();
    int h = inTex.get_height();
    float width = (float)w;
    float height = (float)h;

    // adjust shift based on aspect
    float aspectX, aspectY;
    aspectX = shift.x;
    aspectY = shift.y;
    // map 0…1 to -1…1 to shift either direction
    float shiftX = (aspectX - 0.5f) * 256.0f;
    float shiftY = (0.5f - aspectY) * 256.0f;

    // always positive modulo for x,y position
    float pixelX = fmod(float(gid.x) + width  + shiftX, width);
    float pixelY = fmod(float(gid.y) + height + shiftY, height);

    // maybe draw part of a dot (last entry wins)
    for (int i = int(dotCount) - 1; i >= 0; --i) {
        // encountered a fill command
        if (dots[i].radius < 0) {
            half c = dots[i].color;
            return outTex.write(half4(c,c,c,c), gid);
        }
        // test if pixel is inside set of dots
        int dotX = fmod(dots[i].p.x + width  + shiftX, width);
        int dotY = fmod(dots[i].p.y + height + shiftY, height);
        float distanceX = abs(pixelX - dotX);
        float distanceY = abs(pixelY - dotY);
        float wrapX = min(distanceX, width  - distanceX);
        float wrapY = min(distanceY, height - distanceY);
        if (wrapX * wrapX + wrapY * wrapY <= dots[i].radius * dots[i].radius) {
            // brush index 1…255 into the unorm blue channel; pipe.color reads it back as b * 255
            half c = min(255.0, dots[i].color) / 255.0;
            return outTex.write(half4(0,0,c,0), gid);
        }
    }
    // otherwise pass-through (shifted) input
    outTex.write(inTex.read(uint2(pixelX, pixelY)), gid);
}

/// real color layer: shifted pass-through of the rgba strokes plus this frame's
/// dots in `rgba`; a clear (radius -2, the only negative radius this buffer
/// ever carries) clears the layer to transparent.
/// `cover` marks the pixels the open stroke already coated: one stroke lays one
/// consistent coat however its dots overlap; the next stroke mixes over it
kernel void drawRealKernel
(
 texture2d<float, access::read>  inTex    [[ texture(0) ]],
 texture2d<float, access::write> outTex   [[ texture(1) ]],
 texture2d<float, access::read>  coverIn  [[ texture(2) ]],
 texture2d<float, access::write> coverOut [[ texture(3) ]],
 constant float2&                shift    [[ buffer(0) ]], // canvas.shiftReal / pipe.draw.shiftReal, real layer
 constant uint&                  aspect   [[ buffer(1) ]],
 device const Dot*               dots     [[ buffer(2) ]],
 constant uint&                  dotCount [[ buffer(3) ]],
 constant float4&                rgba     [[ buffer(4) ]],
 constant uint&                  newStroke[[ buffer(5) ]],
 uint2 gid [[thread_position_in_grid]]
 )
{
    float width  = (float)inTex.get_width();
    float height = (float)inTex.get_height();
    float shiftX = (shift.x - 0.5f) * 256.0f;
    float shiftY = (0.5f - shift.y) * 256.0f;
    float pixelX = fmod(float(gid.x) + width  + shiftX, width);
    float pixelY = fmod(float(gid.y) + height + shiftY, height);
    uint2 wrap = uint2(pixelX, pixelY);
    float covered = newStroke > 0 ? 0.0f : coverIn.read(wrap).r;

    for (int i = int(dotCount) - 1; i >= 0; --i) {
        if (dots[i].radius < 0) {
            // clear: the real layer goes transparent, the pal layer shows through
            coverOut.write(float4(0), gid);
            return outTex.write(float4(0), gid);
        }
        int dotX = fmod(dots[i].p.x + width  + shiftX, width);
        int dotY = fmod(dots[i].p.y + height + shiftY, height);
        float distanceX = abs(pixelX - dotX);
        float distanceY = abs(pixelY - dotY);
        float wrapX = min(distanceX, width  - distanceX);
        float wrapY = min(distanceY, height - distanceY);
        if (wrapX * wrapX + wrapY * wrapY <= dots[i].radius * dots[i].radius) {
            coverOut.write(float4(1), gid);
            if (covered > 0.5f) {
                // this stroke already coated the pixel: keep its one coat
                return outTex.write(inTex.read(wrap), gid);
            }
            // first touch of this stroke here: mix over what the layer holds
            float4 dst = inTex.read(wrap);
            float a = rgba.a + dst.a * (1.0f - rgba.a);
            float3 rgb = a > 0.0f
                ? (rgba.rgb * rgba.a + dst.rgb * dst.a * (1.0f - rgba.a)) / a
                : float3(0);
            return outTex.write(float4(rgb, a), gid);
        }
    }
    coverOut.write(float4(covered), gid);
    outTex.write(inTex.read(wrap), gid);
}
