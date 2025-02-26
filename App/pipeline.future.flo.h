pipeline {

    draw(on 1) {
        inTex  (_tex0 &) << cell.outTex
        outTex (_tex1 &+)
        draw  (_buf0, x 0…1~0.5, y 0…1~0.5)
        kernel(file "kernel.camera.metal") {{
            int xs = outTex.get_width();   // width
            int ys = outTex.get_height();  // height
            int x = (gid.x + xs + int((draw.x-0.5) * 256.)) % xs;
            int y = (gid.y + ys + int((0.5-draw.y) * 256.)) % ys;
            half4 item = inTex.read(uint2(x, y));
            outTex.write(item, gid);
        }}
    }
    camera(on 0) {
        camTex(_tex2 &+)
        frame (_buf1)
        front (%2~1)
        kernel(file "kernel.camera.metal") {{
            float x = frame.x; // x offset 0...n
            float y = frame.y; // y offset 0...n
            float w = frame.z; // width 0...n
            float h = frame.w; // height 0...n

            float ww = w - 2*x; // in fill width 0...n
            float wf = ww / w;  // in fill fraction of total 0...1
            float xx = x / ww;  // in offset 0...1

            float hh = h - 2*y; // in height 0...n - 2y
            float hf = hh / h;  // in height factor < 0...1
            float yy = y / hh;  // in y offset 0...1

            float2 norm = float2(gid) / float2(outTex.get_width(),
                                               outTex.get_height());
            float2 camOut = (x > y
                             ? float2(norm.x * wf + xx, norm.y * hf + yy)
                             : float2(norm.x * hf + yy, norm.y * wf + xx));

            constexpr sampler samplr(filter::linear);
            float4 camItem = camTex.sample(samplr, camOut);
            outTex.write(camItem, gid);
        }}
    }
    cell {
        inTex  (_tex0 &) << (draw.outTex, camera.camTex)
        outTex (_tex1 &+)

        rule {
            slide(on 1) {
                version(_buf0, x 0…7=3)
                loops(y 0…20)
                kernel(file "kernel.cell.slide.metal") {{
                    uint r = 0;
                    uint offset = uint(version); // * 7
                    for (int i=0, j=1; i<8; i++, j <<= 1) {
                        int k = (i^offset);
                        r += cells[k] & j;
                    }
                    uint r1 = r;
                    uint r2 = 256 - r1;
                    uint r3 = HiC;// + fmod(r1, 7);
                    float fa = float(r3 >> 8)   / 255.; // trunc(r3/255.) / 255.;
                    float fr = float(r3 & 0xff) / 255.; //mod(r3, 255.) / 255.;
                    float fg = float(r2) / 255.;
                    float fb = float(r1) / 255.;
                    float4 outItem = float4(fr, fg, fb, fa);
                    outTex.write(outItem, gid);
                }}
            }
            zha(on 0) {
                version(_buf0, x 0…6=2)
                bits   (_buf1, x 2…4=3)
                loops(11)
                kernel(file "kernel.cell.ave.metal") {{

                    int alarm  = (LoC >> shift) & 1;
                    int time   = (LoC >> 1) & mask;
                    int newself = time==0 ? 1 : 0;

                    if (time > 0) time --;
                    if (LoC & alarm & 1) {
                        time = mask; // reset countdown
                    }

                    int32_t sum = ((N&1)  + (S&1)  + (E&1)  + (W&1) +
                                   (NW&1) + (NE&1) + (SE&1) + (SW&1));

                    alarm = ((sum  > threshold) &&   // threshold
                             (sum != annealing));    // annealed

                    int r1 = (alarm << shift) | (time << 1) | newself;
                    uint r2 = 256 - r1;
                    uint r3 = HiC + (r1 & 0x80);

                    /** write result to output */
                    ua = (r3 >> 8) & 0xFF;
                    ur = r3 & 0xFF;
                    ug = r2 & 0xFF;
                    ub = r1 & 0xFF;

                    const float fa = float(ua)/255;
                    const float fr = float(ur)/255;
                    const float fg = float(ug)/255;
                    const float fb = float(ub)/255;

                    const half4 outItem = half4(fr, fg, fb, fa);
                    outTex.write(outItem, gid);
                }}
            }
            ave(on 0) {
                version(_buf0, x 0…1=0.5)
                loops(y 0…32)
                kernel(file "kernel.cell.ave.metal") {{
                    float r1 = fmax(0, inItem.b - (version/128.));
                    float r2 = 1.0 - r1;
                    float r3 = HiC + fmod(r1, 3. / 256.);
                    float fa = trunc(r3)/256.;
                    float fr = fract(r3);
                    float fg = r2;
                    float fb = r1;
                    const float4 outItem = float4(fr, fg, fb, fa);
                    outTex.write(outItem, gid);
                }}
            }
            fade(on 0) {
                version(_buf0, x 1.2…3)
                loops(0)
                kernel(file "kernel.cell.fade.metal") {{
                    float r1 = fmax(0, inItem.b - (version/128.));
                    float r2 = 1.0 - r1;
                    float r3 = HiC + fmod(r1, 3. / 256.);
                    float fa = trunc(r3)/256.;
                    float fr = fract(r3);
                    float fg = r2;
                    float fb = r1;
                    const float4 outItem = float4(fr, fg, fb, fa);
                    outTex.write(outItem, gid);
                }}
            }
            melt(on 0) {
                version(_buf0, x 0…1=0.5)
                loops(y 0…32)
                kernel(file "kernel.cell.melt.metal") {{
                    float r1 = (LoC + LoN + LoS + LoE + LoW) / 5;
                    float r2 = ((C / exp2(10+version*4)) + HiN + HiS + HiE + HiW) / (68 - 56 * version);
                    float d1 = (0xffff - r1) / exp2(9 - 4 * version);

                    r1 = Range(r1+d1, 0, 0xffff);
                    r2 = Range(r2   , 0, 0xffff);

                    float fa = trunc(r2/exp2(8.)) / 255.;
                    float fr = fmod(r2,     256.) / 255.;
                    float fg = trunc(r1/exp2(8.)) / 255.;
                    float fb = fmod(r1,     256.) / 255.;

                    half4 outItem = half4(fr, fg, fb, fa);
                    outTex.write(outItem, gid);
                }}
            }
            tunl(on 0) {
                version(_buf0, x 0…5=1)
                loops(y 0…32)
                kernel(file "kernel.cell.ave.metal") {{
                    uint parity;
                    switch (uint(version)) {
                    case 0: parity = ((nsew0  == 0) ? 0 : (nsew0  == 5) ? 0 : 1); break;
                    case 1: parity = ((nsew1  == 0) ? 0 : (nsew1  == 5) ? 0 : 1); break;
                    case 2: parity = ((nsew2  == 0) ? 0 : (nsew2  == 9) ? 0 : 1); break;
                    case 3: parity = ((nsewc0 == 0) ? 0 : (nsewc0 == 5) ? 0 : 1); break;
                    case 4: parity = ((nsewc1 == 0) ? 0 : (nsewc1 == 5) ? 0 : 1); break;
                    case 5: parity = ((nsewc2 == 0) ? 0 : (nsewc2 == 9) ? 0 : 1); break;
                    }
                    uint r1 = (parity ^ LoC1) | LoC2;
                    uint r2 = 256 - r1;
                    uint r3 = HiC + (r1 & 3);

                    ua = (r3 >> 8) & 0xFF;
                    ur = r3 & 0xFF;
                    ug = r2 & 0xFF;
                    ub = r1 & 0xFF;

                    float fa = float(ua)/255;
                    float fr = float(ur)/255;
                    float fg = float(ug)/255;
                    float fb = float(ub)/255;

                    half4 outItem = half4(fr, fg, fb, fa);
                    outTex.write(outItem, gid);
                }}
            }
            fred(on 0) {
                version(_buf0, x 0…4=4)
                loops(y 0…32)
                kernel(file "kernel.cell.fred.metal") {{
                    uint r1 = 0;
                    #define sum(v) ((c<<1) + ((c>>1) + v ) & v) & 0xff;
                    switch (versioni) {
                    case 0: r1 = sum( n  + e  + s  + w); break;
                    case 1: r1 = sum( nw + ne + se + sw); break;
                    case 2: r1 = sum( n  + e  + s  + w + c); break;
                    case 3: r1 = sum( nw + ne + se + sw + c); break;
                    case 4: r1 = sum( n  + e  + s  + w + nw + ne + se + sw); break;
                    }

                    r1 = r1 + (r1<<6);
                    uint r2 = 255 - r1;
                    uint r3 = HiC + (r1 & 0x03);

                    float fa = float(r3 >> 8) / 256.;
                    float fr = float(r3 & 0xff) / 256.;
                    float fg = float(r2) / 256.;
                    float fb = float(r1) / 256.;
                    half4 outItem = half4(fr, fg, fb, fa);
                    outTex.write(outItem, gid);
                }}
            }
            * >> *(on==1 0) // solo only one cell
            ˚version >> ..(on 1) // changing `version` auto switches cell
        }
    }
    color(on 1) {
        
        inTex (_tex0 &) << cell.outTex
        outTex(_tex1 &+)
        palTex(_tex2 &+)

        plane (_buf0, y 0…1)
        kernel(file "kernel.color.metal") {{
            // user switching to new bit plane can result in flashing screen, so
            // so mix palettes between bit planes to allow for smooth transition
            float shiftf = bitplane * 24;         // number of bit planes to shift
            float frac = shiftf - floor(shiftf);  // get fade between bitplanes
            uint shifti = int(shiftf);            // shift for first bitplane
            uint shiftj = shifti+1;               // shift for next bitplane
            uint bgrai = (bgra >> shifti) & 0xFF; // shifted index for first pal
            uint bgraj = (bgra >> shiftj) & 0xFF; // shifted index for next pal

            uint2 palIndexi = uint2(bgrai, 0);     // address for first pal color
            uint2 palIndexj = uint2(bgraj, 0);     // address for second pal color
            half4 palBgrai = palTex.read(palIndexi); // bgra for first pal
            half4 palBgraj = palTex.read(palIndexj); // bgra for second pal

            // use fractional part of bitplane address to fade between two palettes
            half4 fadeBgra = palBgrai * (1.0-frac) + palBgraj * frac;

            outTex.write(fadeBgra, gid);
        }}
    }
    camix(on 0) {
        inTex (_tex0) << color.outTex
        outTex(_tex1)
        camTex(_tex2) << camera.camTex
        mix   (_buf0, x 0…1~0.5)
        frame (_buf1)
        front (%2~1)
        kernel(file "kernel.camix.metal") {{
            float x = frame.x; // x offset 0...n
            float y = frame.y; // y offset 0...n
            float w = frame.z; // width 0...n
            float h = frame.w; // height 0...n

            float ww = w - 2*x; // in fill width 0...n
            float wf = ww / w;  // in fill fraction of total 0...1
            float xx = x / ww;  // in offset 0...1

            float hh = h - 2*y; // in height 0...n - 2y
            float hf = hh / h;  // in height factor < 0...1
            float yy = y / hh;  // in y offset 0...1

            float2 size = float2(outTex.get_width(),
                                 outTex.get_height());
            float2 norm = float2(gid) / size;
            float2 camOut = (x > y
                             ? float2(norm.x * wf + xx, norm.y * hf + yy)
                             : float2(norm.x * hf + yy, norm.y * wf + xx));

            constexpr sampler samplr(filter::linear);
            float4 camItem = camTex.sample(samplr, camOut);
            float4 inItem = inTex.read(gid);
            float4 mixItem = camItem * mix + inItem * (1 - mix);
            outTex.write(mixItem, gid);
        }}
    } << camera // camix(on) driven by camera
    tile(on 0) {
        inTex (_tex0 &) << (camix.outTex, color.outTex)
        outTex(_tex1 &+)
        repeat(_buf0, x -1…1~0, y -1…1~0)
        mirror(_buf1, x  0…1~0, y  0…1~0)
        kernel(file "kernel.tile.metal") {{
            constexpr sampler samplr(coord::normalized, filter::nearest, address::repeat);
            const float xs = outTex.get_width();   // width
            const float ys = outTex.get_height();  // height// height
            float2 gidf = float2(gid.x/xs,gid.y/ys);
            float2 mod;
            float2 rep = max(0.005, 1. - repeat);
            if (mirror.x < -0.5) {
                mod.x = fmod(gidf.x, rep.x);
            } else {
                // mirror rep x
                mod.x = fmod(gidf.x, rep.x * (1 + mirror.x));
                if (mod.x > rep.x) {
                    mod.x = ((rep.x * (1 + mirror.x) - mod.x)
                             / fmax(0.0001, mirror.x));
                }
            }
            if (mirror.y < -0.5) {
                mod.y = fmod(gidf.y, rep.y);
            } else {
                mod.y = fmod(gidf.y, rep.y * (1 + mirror.y));
                if (mod.y > rep.y) {
                    mod.y = ((rep.y * (1 + mirror.y) - mod.y)
                             / fmax(0.0001, mirror.y));
                }
            }
            float2 modNorm = mod / rep;
            half4 item = inTex.sample(samplr, modNorm);
            outTex.write(item, gid);
        }}
    }
    render {
        inTex (_tex0 &) << tile.outTex
        palTex(_tex2 &) << color.palTex
        eyes  (_buf15,mtl &+)

        map {
            flatmap(on 1) {
                vertex(file "render.flatmap.metal") {{
                    FlatOut flatOut;
                    float2 pos = flatIn[vertexId].position.xy;
                    float2 tex = flatIn[vertexId].texCoord.xy;
                    flatOut.position.xy = pos / (viewSize / 2.0); //(-1, -1) to (1, 1)
                    flatOut.position.z = 0.0;
                    flatOut.position.w = 1.0;
                    flatOut.texCoord = (tex + clipFrame.xy) * clipFrame.zw;
                    return flatOut;
                }}
                fragment(file "render.flatmap.metal") {{
                    float2 texCoord = flatOut.texCoord;
                    float2 reps = max(0.005, 1. - repeat);
                    float2 mod;

                    if (mirror.x < -0.5) {
                        mod.x = fmod(texCoord.x, reps.x);
                    } else {
                        // mirror repeati x
                        mod.x = fmod(texCoord.x, reps.x * (1 + mirror.x));
                        if (mod.x > reps.x) {
                            mod.x = ((reps.x * (1+mirror.x) - mod.x)
                                     / fmax(0.0001, mirror.x));
                        }
                    }
                    if (mirror.y < -0.5) {
                        mod.y = fmod(texCoord.y, reps.y);
                    } else {
                        mod.y = fmod(texCoord.y, reps.y * (1 + mirror.y));
                        if (mod.y > reps.y) {
                            mod.y = ((reps.y * (1+mirror.y) - mod.y)
                                     / fmax(0.0001, mirror.y));
                        }
                    }
                    constexpr sampler samplr(filter::linear, address::repeat);
                    float2 modCoord = mod / reps;
                    return inTex.sample(samplr, modCoord);
                }}
            }
            cubemap(on 0) {
                cubeTex (_tex3)
                vertex  (file "render.cubemap.metal") {{
                    CubeOut out;
                    UniformEye eye = eyes.eye[ampId]; // works with eye[1], eye[0]
                    float4 position = cubeIn[vertId].position;
                    out.position = (eye.projection * eye.viewModel * position);
                    out.texCoord = position;
                    return out;
                }}
                fragment(file "render.cubemap.metal") {{
                    float3 texCoord = float3(cubeOut.texCoord.x, cubeOut.texCoord.y, -cubeOut.texCoord.z);
                    constexpr sampler samplr(filter::linear, address::repeat);
                    half4 index = cubeTex.sample(samplr,texCoord);
                    float2 inCoord = float2(index.xy);
                    float2 mod;
                    float2 reps = max(0.005, 1. - repeat);

                    if (mirror.x < -0.5) {
                        mod.x = fmod(inCoord.x, reps.x);
                    } else {
                        // mirror repeati x
                        mod.x = fmod(inCoord.x, reps.x * (1 + mirror.x));
                        if (mod.x > reps.x) {
                            mod.x = ((reps.x * (1 + mirror.x) - mod.x)
                                     / fmax(0.0001, mirror.x));
                        }
                    }
                    if (mirror.y < -0.5) {
                        mod.y = fmod(inCoord.y, reps.y);
                    } else {
                        mod.y = fmod(inCoord.y, reps.y * (1 + mirror.y));
                        if (mod.y > reps.y) {
                            mod.y = ((reps.y * (1 + mirror.y) - mod.y)
                                     / fmax(0.0001, mirror.y));
                        }
                    }
                    return inTex.sample(samplr, mod / reps);
                }}
            }
        }
        plato(on 0) {
            palTex  (_tex2 &) << color.palTex
            cubeTex (_tex3 &) << map.cubemap.cubeTex
            platoIn (_buf0)
            uniforms(_buf1) // ?????
            vertex  (file "render.plato.metal") {{
                PlatoOut platoOut;
                UniformEye eye = eyes.eye[ampId];

                float3 pos0  = platoIn[vertId].pos0.xyz;
                float3 pos1  = platoIn[vertId].pos1.xyz;
                float3 norm0 = platoIn[vertId].norm0.xyz;
                float3 norm1 = platoIn[vertId].norm1.xyz;

                float range01 = uniforms.range;// 0...1 maps pv0...pv1
                float4 pos  = float4((pos0  + (pos1 - pos0) * range01), 1);
                float4 norm = float4((norm0 + (norm1-norm0) * range01), 0);

                float4 worldNorm = normalize(norm);
                float4 eyeDirection = normalize(pos);

                platoOut.position = eye.projection * eye.viewModel * pos;
                platoOut.texCoord = reflect(eyeDirection, worldNorm);
                platoOut.faceId = platoIn[vertId].faceId;
                platoOut.harmonic = platoIn[vertId].harmonic;

                return platoOut;
            }}
            fragment(file "render.plato.metal") {{
                constexpr sampler samplr(filter::linear, address::repeat);

                float palMod = fmod(platoOut.faceId, 256) / 256.0;
                float2 palPos = float2(palMod, 0.0);
                half4 palette = palTex.sample(samplr, palPos);

                float3 texCoord = float3(platoOut.texCoord.x, platoOut.texCoord.y, -platoOut.texCoord.z);
                half4 cubeIndex = cubeTex.sample(samplr, texCoord);

                half4 sampled = inTex.sample(samplr, float2(cubeIndex.xy));
                float reflect = max(uniforms.reflect, 0.001);
                const half3 mix = half3((sampled * reflect) + palette * (1.0 - reflect));

                const float count = 6;
                float alpha    = uniforms.alpha; // x-axis
                float depth    = uniforms.depth;
                float harmonic = platoOut.harmonic;
                float inverse  = uniforms.invert * count;
                float gradient = depth * abs(harmonic-inverse);
                half3 shaded   = mix * (1-gradient);
                return half4(shaded.xyz, 1 - alpha * gradient);
            }}
        }
    }
}

pipeline {

    draw(on 1) {
        inTex  (_tex0 &) << cell.outTex
        outTex (_tex1 &+)
        draw  (_buf0, x 0…1~0.5, y 0…1~0.5)
        kernel(file "kernel.camera.metal") {{}}
    }
    camera(on 0) {
        camTex(_tex2 &+)
        frame (_buf1)
        front (%2~1)
        kernel(file "kernel.camera.metal") {{}}
    }
    cell {
        inTex  (_tex0 &) << (draw.outTex, camera.camTex)
        outTex (_tex1 &+)

        _{
            slide(on 1) {
                version(_buf0, x 0…7=3)
                loops(y 0…20)
                kernel(file "kernel.cell.slide.metal") {{}}
            }
            zha(on 0) {
                version(_buf0, x 0…6=2)
                bits   (_buf1, x 2…4=3)
                loops(11)
                kernel(file "kernel.cell.ave.metal") {{}}
            }
            ave(on 0) {
                version(_buf0, x 0…1=0.5)
                loops(y 0…32)
                kernel(file "kernel.cell.ave.metal") {{}}
            }
            fade(on 0) {
                version(_buf0, x 1.2…3)
                loops(0)
                kernel(file "kernel.cell.fade.metal") {{}}
            }
            melt(on 0) {
                version(_buf0, x 0…1=0.5)
                loops(y 0…32)
                kernel(file "kernel.cell.melt.metal") {{}}
            }
            tunl(on 0) {
                version(_buf0, x 0…5=1)
                loops(y 0…32)
                kernel(file "kernel.cell.ave.metal") {{}}
            }
            fred(on 0) {
                version(_buf0, x 0…4=4)
                loops(y 0…32)
                kernel(file "kernel.cell.fred.metal") {{}}
            }
            * >> *(on==1 0) // solo only one cell
            ˚version >> ..(on 1) // changing `version` auto switches cell
        }
    }
    color(on 1) {

        inTex (_tex0 &) << cell.outTex
        outTex(_tex1 &+)
        palTex(_tex2 &+)

        plane (_buf0, y 0…1)
        kernel(file "kernel.color.metal") {{}}
    }
    camix(on 0) {

        inTex (_tex0 &) << color.outTex
        outTex(_tex1 &+)
        camTex(_tex2 &) << camera.camTex

        mix   (_buf0, x 0…1~0.5)
        frame (_buf1)
        front (%2~1)
        kernel(file "kernel.camix.metal") {{}}
    } << camera // camix(on) driven by camera

    tile(on 0) {
        
        inTex (_tex0 &) << (camix.outTex, color.outTex)
        outTex(_tex1 &+)

        repeat(_buf0, x -1…1~0, y -1…1~0)
        mirror(_buf1, x  0…1~0, y  0…1~0)

        kernel(file "kernel.tile.metal") {{}}
    }
    render {

        inTex   (_tex0 &) << tile.outTex
        palTex  (_tex2 &) << color.palTex
        cubeTex (_tex3 &+)
        eyes    (_buf15)

        flatmap(on 1) {
            vertex  (file "render.flatmap.metal") {{}}
            fragment(file "render.flatmap.metal") {{}}
        }
        cubemap(on 0) {
            vertex  (file "render.cubemap.metal") {{}}
            fragment(file "render.cubemap.metal") {{}}
        }

        plato(on 0) {
            platoIn (_buf0)
            uniforms(_buf1) // ?????

            vertex  (file "render.plato.metal") {{}}
            fragment(file "render.plato.metal") {{}}
        }
    }
}
