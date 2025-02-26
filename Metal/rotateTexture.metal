// created by musesum on 11/13/24

#include <metal_stdlib>
using namespace metal;

kernel void rotateTexture
(
 texture2d<half, access::read>  inTex  [[ texture(0) ]],
 texture2d<half, access::write> outTex [[ texture(1) ]],
 constant uint&                 aspect [[ buffer(0)  ]],
 uint2 gid [[thread_position_in_grid]]
 )
{
    uint x = gid.x;
    uint y = gid.y;
    uint w = inTex.get_width()  - 1;
    uint h = inTex.get_height() - 1;
    half4 color = inTex.read(uint2(x, y));

    switch (aspect) {
    case 0  : outTex.write(color, uint2(  y, w-x)); break;
    case 1  : outTex.write(color, uint2(h-y,   x)); break;
    default : outTex.write(color, uint2(  x,   y));
    }
}
