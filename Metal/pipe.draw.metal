#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

// Dot overlay data (color = 0..255)
struct Dot {
    float2 p;       // center in pixels (after shift space)
    float radius;  // -1 fill, 0...64, size
    float color;   // 0..255 palette index
};

kernel void drawDotKernel
(
 texture2d<half, access::read>   inTex   [[ texture(0) ]],
 texture2d<half, access::write>  outTex  [[ texture(1) ]],
 constant float2&                shift   [[ buffer(0) ]],
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
    if (aspect < 1) {
        aspectX = shift.x;
        aspectY = shift.y;
    } else {
        aspectX = 1.0 - shift.y;
        aspectY = shift.x;
    }
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
            half c = min(255.0, dots[i].color);
            return outTex.write(half4(0,0,c,0), gid);
        }
    }
    // otherwise pass-through (shifted) input
    outTex.write(inTex.read(uint2(pixelX, pixelY)), gid);
}
