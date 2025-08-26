#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

kernel void colorKernel
(
 texture2d<half, access::read>  inTex     [[ texture(0) ]],
 texture2d<half, access::read>  palTex    [[ texture(1) ]],
 texture2d<half, access::write> colorTex  [[ texture(2) ]],
 texture2d<half, access::write> heightTex [[ texture(3) ]],
 constant float&                plane     [[ buffer(0) ]],
 constant float&                height    [[ buffer(1) ]],
 uint2 gid [[thread_position_in_grid]])
{{
    const half4 item = inTex.read(gid);
    
    // convert from half4 to UInt32?
    uint b8 = uint(item.b * 255.0);
    uint g8 = uint(item.g * 255.0) << 8;
    uint r8 = uint(item.r * 255.0) << 16;
    uint a8 = uint(item.a * 255.0) << 24;
    uint bgra = a8 + r8 + g8 + b8;
    
    // user switching to new bit plane can result in flashing screen, so
    // so mix palettes between bit planes to allow for smooth transition
    float shiftf = plane * 24;         // number of bit planes to shift
    float frac = shiftf - floor(shiftf);  // get fade between bitplanes
    uint shifti = int(shiftf);            // shift for first bitplane
    uint shiftj = shifti+1;                // shift for next bitplane
    uint bgrai = (bgra >> shifti) & 0xFF; // shifted index for first pal
    uint bgraj = (bgra >> shiftj) & 0xFF; // shifted index for next pal
    
    uint2 palIndexi = uint2(bgrai, 0);     // address for first pal color
    uint2 palIndexj = uint2(bgraj, 0);     // address for second pal color
    half4 palBgrai = palTex.read(palIndexi); // bgra for first pal
    half4 palBgraj = palTex.read(palIndexj); // bgra for second pal

    // use fractional part of bitplane address to fade between two palettes
    half4 color = (palBgrai * (1.0 - frac) +
                   palBgraj *        frac);

    colorTex.write(color, gid);
    float mono = (color.r) * height;
    heightTex.write(mono,gid);

}}
