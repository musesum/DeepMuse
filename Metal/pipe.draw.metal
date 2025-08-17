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

    // same aspect/shift as drawKernel
    float sx, sy;
    switch (int(aspect)) {
    case 0  : sx =       shift.x; sy = shift.y; break;
    default : sx = 1.0 - shift.y; sy = shift.x; break;
    }
    int dx = int((sx - 0.5f) * 256.0f);
    int dy = int((0.5f - sy) * 256.0f);

    // always positive modulo for x,y position
    int x = (int(gid.x) + w + dx) % w;
    int y = (int(gid.y) + h + dy) % h;

    // draw dots (last entry wins)
    for (int i = int(dotCount) - 1; i >= 0; --i) {
        // encountered a fill command
        if (dots[i].radius < 0) {
            half c = min(255.0,dots[i].color*255.0);
            return outTex.write(half4(c,c,c,c), gid);
        }
        // test if inside set of dot radii
        int px = ((int)dots[i].p.x + w + dx) % w;
        int py = ((int)dots[i].p.y + h + dy) % h;
        float dx_ = abs(float(x - px));
        dx_ = min(dx_, float(w) - dx_); // wrap horizontally
        float dy_ = abs(float(y - py));
        dy_ = min(dy_, float(h) - dy_); // wrap vertically
        if (dx_ * dx_ + dy_ * dy_ <= dots[i].radius * dots[i].radius) {
            half c = min(255.0, dots[i].color);
            return outTex.write(half4(0,0,c,0), gid);
        }
    }
    // otherwise pass-through shifted input
    outTex.write(inTex.read(uint2(x, y)), gid);
}
