#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

kernel void drawKernel
(
 texture2d<half, access::read>  inTex  [[ texture(0) ]],
 texture2d<half, access::write> outTex [[ texture(1) ]],
 constant float2&               shift  [[ buffer(0)  ]],
 constant uint&                 aspect [[ buffer(1)  ]],
 uint2 gid [[thread_position_in_grid]])
{

    int w = inTex.get_width();   // width
    int h = inTex.get_height();  // height

    // shift x and y is flipped for changing aspect
    float sx, sy;
    switch (int(aspect)) {
    case 0  : sx =   shift.x; sy = shift.y; break;
    default : sx = 1-shift.x; sy = shift.y; break;
    }

    int dx = int((sx-0.5) * 256.); // delta x
    int dy = int((0.5-sy) * 256.); // delta y

    // always positive modulo for x,y position
    int x = (gid.x + w + dx) % w;
    int y = (gid.y + h + dy) % h;

    half4 item = inTex.read(uint2(x, y));

    outTex.write(item, gid);
}
