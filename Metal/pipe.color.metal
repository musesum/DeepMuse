#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

kernel void colorKernel
(
 texture2d<half, access::read>  inTex    [[ texture(0) ]],
 texture2d<half, access::read>  palTex   [[ texture(1) ]],
 texture2d<half, access::write> colorTex [[ texture(2) ]],
 constant float&                plane    [[ buffer(0) ]],
 constant float&                height   [[ buffer(1) ]],
 constant float&                pairMix  [[ buffer(2) ]],
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

    // rows 10 and 11 hold two occupants per pixel over their later frames: count in
    // red, first occupant in blue, second in green, alpha at one flagging that form.
    // their earlier frames hold four lanes per pixel, a lane storing (value + 1)/512,
    // so no lane channel passes 0.5 and the flag reads false there. both forms are
    // decoded below, so colour follows the occupants a pixel holds from the first
    // frame on. zero here keeps the plain path everywhere. plane addresses a bit of
    // the packed word, which neither form carries, so this branch never reads plane.
    // (0,0) is bookkeeping in both forms and is taken first, since its alpha is the
    // counter's high byte rather than the flag.
    if (pairMix > 0.0) {

        if (gid.x == 0 && gid.y == 0) {   // (0,0) carries the frame counter, not a count

            // alpha at (0,0) is the counter's high byte, so the form is read off the
            // neighbour (1, 0): alpha there is one in the pair form only, and no lane
            // channel passes 0.5.
            const half4 nbr = inTex.read(uint2(1, 0));

            uint parked = 0;
            if (nbr.a > 0.75h) {                               // pair form: its occupant byte
                parked = uint(float(item.b) * 255.0 + 0.5);
            } else {                                           // lane form: (value + 1) / 512
                const int g = int(float(item.g) * 512.0 + 0.5);
                const int b = int(float(item.b) * 512.0 + 0.5);
                const int code = (g >= 1) ? g : b;             // its parked lane, 0 and 3 being the counter
                parked = (code >= 1) ? uint(min(code - 1, 255)) : 0u;
            }
            color = palTex.read(uint2(parked, 0));

        } else if (item.a > 0.75h) {      // two occupants fit in one pixel

            uint pairCount = uint(float(item.r) * 255.0 + 0.5);
            uint occupant1 = uint(float(item.b) * 255.0 + 0.5);
            uint occupant2 = uint(float(item.g) * 255.0 + 0.5);

            if (pairCount >= 2) {         // two occupants read as their sum
                half4 palOne = palTex.read(uint2(occupant1, 0));
                half4 palTwo = palTex.read(uint2(occupant2, 0));
                color = clamp(palOne + palTwo, half4(0.0h), half4(1.0h));

            } else if (pairCount == 1) {  // one occupant
                color = palTex.read(uint2(occupant1, 0));

            } else {                      // empty
                color = half4(0.0h, 0.0h, 0.0h, 1.0h);
            }

        } else {                          // lane form: a lane per channel, (value + 1)/512

            int lane[4];
            lane[0] = int(float(item.r) * 512.0 + 0.5);
            lane[1] = int(float(item.g) * 512.0 + 0.5);
            lane[2] = int(float(item.b) * 512.0 + 0.5);
            lane[3] = int(float(item.a) * 512.0 + 0.5);

            uint count = 0, occupant1 = 0, occupant2 = 0;
            for (int i = 0; i < 4; i++) {
                if (lane[i] < 1) continue;                 // that lane is empty
                uint v = uint(min(lane[i] - 1, 255));
                if      (count == 0) occupant1 = v;
                else if (count == 1) occupant2 = v;
                count += 1;
            }

            if (count >= 2) {             // two occupants read as their sum
                half4 palOne = palTex.read(uint2(occupant1, 0));
                half4 palTwo = palTex.read(uint2(occupant2, 0));
                color = clamp(palOne + palTwo, half4(0.0h), half4(1.0h));

            } else if (count == 1) {      // one occupant
                color = palTex.read(uint2(occupant1, 0));

            } else {                      // empty
                color = half4(0.0h, 0.0h, 0.0h, 1.0h);
            }
        }
    }

    colorTex.write(color, gid);
    // float mono = (color.r) * height;
    // heightTex.write(mono,gid);

}}
