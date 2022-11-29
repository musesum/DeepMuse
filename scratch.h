
sky { // visual music synth
    main { // main controls
        fps(1…60=60) // frames per second
        run(1) // currently running
    }
    pipeline { // default metal pipeline at atartup
        draw("draw") // drawing layer
        ave("compute") // compute layer
        color("color") // colorizing layer
        render("render") // render layer al
    }
    color { // false color mapping palette
        pal0("roygbik") // palette 0: (r)ed (o)range (y)ellow …
        pal1("wKZ") // palette 1: (w)hite blac(K) fractali(Z)e
        xfade(val 0…1=0.5)
    }
    input { // phone and tablet pencil input
        azimuth(x -0.2…0.2, y -0.2…0.2)>>shader.model.pipe.draw
        accel(x -0.3…0.3, y -0.3…0.3, z -0.3…0.3) { // accelerometer
            on(0…1)
        }
        radius(1…92=9) // finger silhouette
        tilt(0…1) // use tilt
        force(0…0.5)>>sky.draw.brush.size // pen pressure
    }
    draw { // draw on metal layer
        screen { // fill 32 bit universe
            fill(0) // all zeros 0x00000000
        }
        brush { // type of brush and range
            size(1…64=10) // range of radius
            press(0…1=1) // pressure changes size
            index(1…255=127) // index in 256 color palette
                             // <<(osc.tuio.z osc.manos˚z) // redirect from OSC
        }
        line { // place holder for line drawing
            prev(x 0…1, y 0…1) // staring point of segment
            next(x 0…1, y 0…1) // endint point of segment
        }
        dot(x, y, z)
    }
}
shader {
    model {
        cell {
            fade(0…1=0.5) {
                on(0…1=0)>>(shader.model.cell.fade.on(0), shader.model.cell.ave.on(0), shader.model.cell.melt.on(0), shader.model.cell.tunl.on(0), shader.model.cell.slide.on(0), shader.model.cell.fred.on(0), shader.model.cell.zha.on(0))<<shader.model.cell.fade
            }
            ave(0…1=0.5) {
                on(0…1=1)>>(shader.model.cell.fade.on(0), shader.model.cell.ave.on(0), shader.model.cell.melt.on(0), shader.model.cell.tunl.on(0), shader.model.cell.slide.on(0), shader.model.cell.fred.on(0), shader.model.cell.zha.on(0))<<shader.model.cell.ave
            }
            melt(0…1=0.5) {
                on(0…1=0)>>(shader.model.cell.fade.on(0), shader.model.cell.ave.on(0), shader.model.cell.melt.on(0), shader.model.cell.tunl.on(0), shader.model.cell.slide.on(0), shader.model.cell.fred.on(0), shader.model.cell.zha.on(0))<<shader.model.cell.melt
            }
            tunl(0…5=1) {
                on(0…1=0)>>(shader.model.cell.fade.on(0), shader.model.cell.ave.on(0), shader.model.cell.melt.on(0), shader.model.cell.tunl.on(0), shader.model.cell.slide.on(0), shader.model.cell.fred.on(0), shader.model.cell.zha.on(0))<<shader.model.cell.tunl
            }
            slide(0…7=3) {
                on(0…1=0)>>(shader.model.cell.fade.on(0), shader.model.cell.ave.on(0), shader.model.cell.melt.on(0), shader.model.cell.tunl.on(0), shader.model.cell.slide.on(0), shader.model.cell.fred.on(0), shader.model.cell.zha.on(0))<<shader.model.cell.slide
            }
            fred(0…4=4) {
                on(0…1=0)>>(shader.model.cell.fade.on(0), shader.model.cell.ave.on(0), shader.model.cell.melt.on(0), shader.model.cell.tunl.on(0), shader.model.cell.slide.on(0), shader.model.cell.fred.on(0), shader.model.cell.zha.on(0))<<shader.model.cell.fred
            }
            zha(0…6=2) {
                on(0…1=0)>>(shader.model.cell.fade.on(0), shader.model.cell.ave.on(0), shader.model.cell.melt.on(0), shader.model.cell.tunl.on(0), shader.model.cell.slide.on(0), shader.model.cell.fred.on(0), shader.model.cell.zha.on(0))<<shader.model.cell.zha
                bits(2…4=3)
                loops(11)
            }
        }
        pipe {
            draw(x 0…1=0.5, y 0…1=0.5) {
                on(0…1=0)
            }
            record {
                on(0…1=0)
            }
            camera {
                on(0…1=0)
                flip(0)
            }
            camix {
                on(0…1=0)
                mix(0)
            }
            color(val 0…1=0.1) // bitplane
            render {
                frame(x 0, y 0, w 1080, h 1920)
                repeat(x, y)
                mirror(x, y)
            }
        }
    }
    file {
        cell {
            fade("cell.fader.metal")
            ave("cell.ave.metal")
            melt("cell.melt.metal")
            tunl("cell.tunl.metal")
            slide("cell.slide.metal")
            fred("cell.fred.metal")
            zha("cell.zha.metal")
        }
        pipe {
            record camera("cell.camera.metal")
            camix("cell.camix.metal")
            draw("pipe.draw.metal")
            render("pipe.render.metal")
            color("pipe.color.metal")
        }
    }
}
menu {
    SW {
        view(depth 0, touch 1000001) {
            canvas(symbol "photo.artframe", touch 0) {
                tile(image "icon.shader.tile.png", touch 0) {
                    mirror(symbol "arrowtriangle.left.and.line.vertical.and.arrowtriangle.right", touch 0)
                    repeat(symbol "rectangle.grid.2x2", touch 0)
                    shift(image "icon.cell.scroll", touch 0)
                    tilt(image "icon.pen.tilt", touch 0)
                }
                color(image "icon.pal.main", touch 0) {
                    fade(symbol "slider.horizontal.below.rectangle", touch 0)
                    plane(symbol "square.3.layers.3d.down.right", touch 0)
                    zero(symbol "drop", touch 0)
                    one(symbol "drop.fill", touch 0)
                }
                speed(image "icon.speed", touch 0) {
                    fps(symbol "speedometer", touch 0)
                    run(symbol "goforward", touch 0)
                }
            }
            brush(symbol "paintbrush.pointed", touch 0) {
                size(symbol "circle.circle", touch 0)
                press(image "icon.pen.press", touch 0)
                tilt(image "icon.pen.tilt", touch 0) //(symbol "angle", touch 0)
            }
            cell(symbol "circle.grid.3x3", touch 1000002) {
                fade(image "icon.cell.fade", touch 0)
                ave(image "icon.cell.ave", touch 0)
                melt(image "icon.cell.melt", touch 0)
                tunl(image "icon.cell.tunl", touch 0)
                zha(image "icon.cell.zha", touch 0)
                slide(image "icon.cell.slide", touch 0)
                fred(image "icon.cell.fred", touch 0)
            }
            cam(symbol "camera", touch 0) {
                snap(symbol "camera.shutter.button", touch 0)
                fake(symbol "face.dashed", touch 0)
                real(symbol "face.smiling", touch 0)
                face(symbol "arrow.triangle.2.circlepath.camera", touch 0)
                mix(symbol "slider.horizontal.below.rectangle", touch 0)
            }
        }
        model {
            canvas {
                tile {
                    mirror(x 0…1=0, y 0…1=0)<>shader.model.pipe.render.mirror
                    repeat(x -1…1=0.5, y -1…1=0.5)<>shader.model.pipe.render.repeat
                    shift(x 0…1=0.5, y 0…1=0.5)<>shader.model.pipe.draw
                    tilt(tog 0…1=0)<>sky.input.tilt
                }
                color {
                    fade(val 0…1=0)<>sky.color.xfade
                    plane(val 0…1=0)<>shader.model.pipe.color
                    zero(tap 0…1=0)>>sky.draw.screen.fill(0)
                    one(tap 0…1=0)>>sky.draw.screen.fill(1)
                }
                speed {
                    fps(seg 0…60=60)<>sky.main.fps
                    run(tog 0…1=1)<>sky.main.run
                }
            }
            brush {
                size(val 0…1=0.5)>>(sky.draw.brush.size, menu.SW.model.brush.press(0))
                press(tog 0…1=1)>>sky.draw.brush.press
                tilt(tog 0…1=1)<>sky.input.tilt
            }
            cell {
                fade(val 2…3=2.2)>>shader.model.cell.fade
                ave(val 0…1=0.5)>>shader.model.cell.ave
                melt(val 0…1=0.5)>>shader.model.cell.melt
                tunl(seg 0…5=1)>>shader.model.cell.tunl
                zha(seg 0…6=2)>>shader.model.cell.zha
                slide(seg 0…7=3)>>shader.model.cell.slide
                fred(seg 0…4=4)>>shader.model.cell.fred
            }
            cam {
                snap(tap 0…1=0)
                fake(tog 0…1=0) <>shader.model.pipe.camix.on
                real(tog 0…1=1) <>shader.model.pipe.camera.on
                face(tog 0…1=1) <>shader.model.pipe.camera.flip
                mix(val 0…1=0.5)<>shader.model.pipe.camix.mix
            }
        }
    }
    SE @SW { // copy southwest corner
        view(depth 0, touch 1000001) {
            canvas(symbol "photo.artframe", touch 0) {
                tile(image "icon.shader.tile.png", touch 0) {
                    mirror(symbol "arrowtriangle.left.and.line.vertical.and.arrowtriangle.right", touch 0)
                    repeat(symbol "rectangle.grid.2x2", touch 0)
                    shift(image "icon.cell.scroll", touch 0)
                    tilt(image "icon.pen.tilt", touch 0)
                }
                color(image "icon.pal.main", touch 0) {
                    fade(symbol "slider.horizontal.below.rectangle", touch 0)
                    plane(symbol "square.3.layers.3d.down.right", touch 0)
                    zero(symbol "drop", touch 0)
                    one(symbol "drop.fill", touch 0)
                }
                speed(image "icon.speed", touch 0) {
                    fps(symbol "speedometer", touch 0)
                    run(symbol "goforward", touch 0)
                }
            }
            brush(symbol "paintbrush.pointed", touch 0) {
                size(symbol "circle.circle", touch 0)
                press(image "icon.pen.press", touch 0)
                tilt(image "icon.pen.tilt", touch 0) //(symbol "angle", touch 0)
            }
            cell(symbol "circle.grid.3x3", touch 1000002) {
                fade(image "icon.cell.fade", touch 0)
                ave(image "icon.cell.ave", touch 0)
                melt(image "icon.cell.melt", touch 0)
                tunl(image "icon.cell.tunl", touch 0)
                zha(image "icon.cell.zha", touch 0)
                slide(image "icon.cell.slide", touch 0)
                fred(image "icon.cell.fred", touch 0)
            }
            cam(symbol "camera", touch 0) {
                snap(symbol "camera.shutter.button", touch 0)
                fake(symbol "face.dashed", touch 0)
                real(symbol "face.smiling", touch 0)
                face(symbol "arrow.triangle.2.circlepath.camera", touch 0)
                mix(symbol "slider.horizontal.below.rectangle", touch 0)
            }
        }
        model {
            canvas {
                tile {
                    mirror(x 0…1=0, y 0…1=0)<>shader.model.pipe.render.mirror
                    repeat(x -1…1=0.5, y -1…1=0.5)<>shader.model.pipe.render.repeat
                    shift(x 0…1=0.5, y 0…1=0.5)<>shader.model.pipe.draw
                    tilt(tog 0…1=0)<>sky.input.tilt
                }
                color {
                    fade(val 0…1=0)<>sky.color.xfade
                    plane(val 0…1=0)<>shader.model.pipe.color
                    zero(tap 0…1=0)>>sky.draw.screen.fill(0)
                    one(tap 0…1=0)>>sky.draw.screen.fill(1)
                }
                speed {
                    fps(seg 0…60=60)<>sky.main.fps
                    run(tog 0…1=1)<>sky.main.run
                }
            }
            brush {
                size(val 0…1=0.5)>>(sky.draw.brush.size, menu.SE.model.brush.press(0))
                press(tog 0…1=1)>>sky.draw.brush.press
                tilt(tog 0…1=1)<>sky.input.tilt
            }
            cell {
                fade(val 2…3=2.2)>>shader.model.cell.fade
                ave(val 0…1=0.5)>>shader.model.cell.ave
                melt(val 0…1=0.5)>>shader.model.cell.melt
                tunl(seg 0…5=1)>>shader.model.cell.tunl
                zha(seg 0…6=2)>>shader.model.cell.zha
                slide(seg 0…7=3)>>shader.model.cell.slide
                fred(seg 0…4=4)>>shader.model.cell.fred
            }
            cam {
                snap(tap 0…1=0)
                fake(tog 0…1=0)>>shader.model.pipe.camix.on
                real(tog 0…1=1)>>shader.model.pipe.camera.on
                face(tog 0…1=1)>>shader.model.pipe.camera.flip
                mix(val 0…1=0.5)>>shader.model.pipe.camix.mix
            }
        }
    }
}
midi { // musical instrument device interface
    input { // midi input
        note { // note on/off from 0 thru 127
            on(num 0…127, velo 0…127, chan 1…32, port 1…16, time)>>(midi.notes.dot, midi.output.note.on)
            off(num 0…127, velo 0…127, chan 1…32, port 1…16, time)>>(midi.input.note.on, midi.output.note.off)
        }
        controller(cc 0…127, val 0…127, chan 1…32, port 1…16, time)>>(midi.cc.skypad.plane, midi.cc.skypad.xfade, midi.cc.roli.lightpad.x, midi.cc.roli.lightpad.y, midi.cc.roli.lightpad.z, midi.cc.roli.loopblock.mode, midi.cc.roli.loopblock.mute, midi.cc.roli.loopblock.metro, midi.cc.roli.loopblock.skip, midi.cc.roli.loopblock.back, midi.cc.roli.loopblock.play, midi.cc.roli.loopblock.record, midi.cc.roli.loopblock.learn, midi.cc.roli.loopblock.prev, midi.cc.roli.loopblock.next)
        afterTouch(num 0…127, val 0…127, chan 1…32, port 1…16, time)
        pitchBend(val 0…16384=8192, chan 1…32, port 1…16, time)
        programChange(num 0…255, chan 1…32, port 1…16, time) //1, 632, 255
        nrpn(num 0…16383, val 0…1, chan, time)>>(midi.skypad.plane, midi.skypad.xfade)
    }
    output @input {
        note { // note on/off from 0 thru 127
            on(num 0…127, velo 0…127, chan 1…32, port 1…16, time)>>(midi.notes.dot, midi.output.note.on)
            off(num 0…127, velo 0…127, chan 1…32, port 1…16, time)>>(midi.input.note.on, midi.output.note.off)
        }
        controller(cc 0…127, val 0…127, chan 1…32, port 1…16, time)>>(midi.cc.skypad.plane, midi.cc.skypad.xfade, midi.cc.roli.lightpad.x, midi.cc.roli.lightpad.y, midi.cc.roli.lightpad.z, midi.cc.roli.loopblock.mode, midi.cc.roli.loopblock.mute, midi.cc.roli.loopblock.metro, midi.cc.roli.loopblock.skip, midi.cc.roli.loopblock.back, midi.cc.roli.loopblock.play, midi.cc.roli.loopblock.record, midi.cc.roli.loopblock.learn, midi.cc.roli.loopblock.prev, midi.cc.roli.loopblock.next)
        afterTouch(num 0…127, val 0…127, chan 1…32, port 1…16, time)
        pitchBend(val 0…16384=8192, chan 1…32, port 1…16, time)
        programChange(num 0…255, chan 1…32, port 1…16, time) //1, 632, 255
        nrpn(num 0…16383, val 0…1, chan, time)>>(midi.skypad.plane, midi.skypad.xfade)
    }
    skypad {
        plane(num == 129, val 0…1, chan, time)<>shader.model.pipe.color
        xfade(num == 130, val 0…1, chan, time)<>sky.color.xfade
    }
    cc {
        skypad {
            plane(cc == 11, val 0…127, chan, time)<>shader.model.pipe.color
            xfade(cc == 10, val 0…127, chan, time)<>sky.color.xfade
        }
        roli {
            lightpad {
                x(cc == 114, val 0…127, chan, time)
                y(cc == 113, val 0…127, chan, time)
                z(cc == 115, val 0…127, chan, time)
            }
            loopblock {
                mode(cc == 102, val 0…127, chan, time)
                mute(cc == 103, val 0…127, chan, time)
                metro(cc == 104, val 0…127, chan, time)
                skip(cc == 105, val 0…127, chan, time)
                back(cc == 106, val 0…127, chan, time)
                play(cc == 107, val 0…127, chan, time)
                record(cc == 108, val 0…127, chan, time)
                learn(cc == 109, val 0…127, chan, time)
                prev(cc == 110, val 0…127, chan, time)
                next(cc == 111, val 0…127, chan, time)
            }
        }
    }
    notes {
        dot(x : num % 12, y : num _/ 12, z : velo)>>sky.draw.dot
    }
    _cc {
        main {
            modWheel(num == 1, val, chan, time)
            volume(num == 7, val, chan, time)
            balance(num == 8, val, chan, time)
            panPosition(num == 10, val, chan, time)
            expression(num == 11, val, chan, time)
            controller(num in 32…63, val, chan, time) // controller 0…31
            portamento {
                time(num == 5, val, chan, time)
                amount(num == 84, val, chan, time)
            }
        }
        pedal {
            hold(num == 64, val, chan, time)
            porta(num == 65, val, chan, time)
            sosta(num == 66, val, chan, time)
            _soft(num == 67, val, chan, time)
            _legato(num == 68, val, chan, time)
            _hold2(num == 69, val, chan, time)
        }
        _cc {
            _main2 {
                bankSelect(num == 0, val, chan, time)
                breathCtrl(num == 2, val, chan, time)
                footPedal(num == 4, val, chan, time)
                dataEntry(num == 6, val, chan, time)
                effectControl1(num == 12, val, chan, time)
                effectControl2(num == 13, val, chan, time)
            }
            _sound {
                soundVariation(num == 70, val, chan, time)
                resonance(num == 71, val, chan, time)
                soundReleaseTime(num == 72, val, chan, time)
                soundAttackTime(num == 73, val, chan, time)
                frequencyCutoff(num == 74, val, chan, time)
                timbre(num == 71, val, chan, time)
                brightness(num == 74, val, chan, time)
            }
            _button {
                button1(num == 80, val, chan, time)
                button2(num == 81, val, chan, time)
                button3(num == 82, val, chan, time)
                button4(num == 83, val, chan, time)
                decayor(num == 80, val, chan, time)
                hiPassFilter(num == 81, val, chan, time)
                generalPurpose82(num == 82, val, chan, time)
                generalPurpose83(num == 83, val, chan, time)
            }
            _roland {
                rolandToneLevel1(num == 80, val, chan, time)
                rolandToneLevel2(num == 81, val, chan, time)
                rolandToneLevel3(num == 82, val, chan, time)
                rolandToneLevel4(num == 83, val, chan, time)
            }
            _level {
                reverbLevel(num == 91, val, chan, time)
                tremoloLevel(num == 92, val, chan, time)
                chorusLevel(num == 93, val, chan, time)
                detuneLevel(num == 94, val, chan, time)
                phaserLevel(num == 95, val, chan, time)
            }
            _parameter {
                dataButtonIncrement(num == 96, val, chan, time)
                dataButtonDecrement(num == 97, val, chan, time)
                nonregisteredParameterLSB(num == 98, val, chan, time)
                nonregisteredParameterMSB(num == 99, val, chan, time)
                registeredParameterLSB(num == 100, val, chan, time)
                registeredParameterMSB(num == 101, val, chan, time)
            }
            _soundControl {
                soundControl6(num == 75, val, chan, time)
                soundControl7(num == 76, val, chan, time)
                soundControl8(num == 77, val, chan, time)
                soundControl9(num == 78, val, chan, time)
                soundControl10(num == 79, val, chan, time)
            }
            _undefined {
                undefined_3(num == 3, val, chan, time)
                undefined_9(num == 9, val, chan, time)
                undefined_14_31(num in 14…31, val, chan, time)
                undefined_85_90(num in 85…90, val, chan, time)
                undefined_102_119(num in 102…119, val, chan, time)
            }
            _mode {
                allSoundOff(num == 120, val, chan, time)
                allControllersOff(num == 121, val, chan, time)
                localKeyboard(num == 122, val, chan, time)
                allNotesOff(num == 123, val, chan, time)
                monoOperation(num == 126, val, chan, time)
                polyMode(num == 127, val, chan, time)
            }
            _omni {
                omniModeOff(num == 124, val, chan, time)
                omniModeOn(num == 125, val, chan, time)
                omniMode(0…1)<<(midi._cc._cc._omni.omniModeOff(0), midi._cc._cc._omni.omniModeOn(1))
            }
        }
    }
}



scriptNow ⟹
sky {
    input {
        radius(1…92=9:17.618905)
        force(0…0.5:0.131811)
    }
    draw.brush.size(1…64=10:17.618905)
}
shader.model.cell {
    ave.on(0…1=1:0)
    melt.on(0…1=0:0.5)
}
menu.SW.view(depth 0, touch 1000001).cell(symbol "circle.grid.3x3", touch 1000002)


*** radius [def, now, compact, parens, delta].[thru, min, max, dflt, now] : 17.618905488774015
*** force [def, now, compact, parens, delta].[thru, min, max, now] : 0.13181118899766792
*** size [def, now, compact, parens, delta].[thru, min, max, dflt, now] : 17.618905488774015
*** on [def, now, compact, parens, delta].[thru, min, max, dflt, now] : 0.0
*** on [def, now, compact, parens, delta].[thru, min, max, dflt, now] : 0.5



scriptDef ⟹
sky { // visual music synth
    main { // main controls
        fps(1…60=60) // frames per second
        run(1) // currently running
    }
    pipeline { // default metal pipeline at atartup
        draw("draw") // drawing layer
        ave("compute") // compute layer
        color("color") // colorizing layer
        render("render") // render layer al
    }
    color { // false color mapping palette
        pal0("roygbik") // palette 0: (r)ed (o)range (y)ellow …
        pal1("wKZ") // palette 1: (w)hite blac(K) fractali(Z)e
        xfade(val 0…1=0.5)
    }
    input { // phone and tablet pencil input
        azimuth(x -0.2…0.2, y -0.2…0.2)>>shader.model.pipe.draw
        accel(x -0.3…0.3, y -0.3…0.3, z -0.3…0.3) { // accelerometer
            on(0…1)
        }
        radius(1…92=9) // finger silhouette
        tilt(0…1) // use tilt
        force(0…0.5)>>sky.draw.brush.size // pen pressure
    }
    draw { // draw on metal layer
        screen { // fill 32 bit universe
            fill(0) // all zeros 0x00000000
        }
        brush { // type of brush and range
            size(1…64=10) // range of radius
            press(0…1=1) // pressure changes size
            index(1…255=127) // index in 256 color palette
                             // <<(osc.tuio.z osc.manos˚z) // redirect from OSC
        }
        line { // place holder for line drawing
            prev(x 0…1, y 0…1) // staring point of segment
            next(x 0…1, y 0…1) // endint point of segment
        }
        dot(x, y, z)
    }
}
shader {
    model {
        cell {
            fade(0…1=0.5) {
                on(0…1=0)>>(shader.model.cell.fade.on(0), shader.model.cell.ave.on(0), shader.model.cell.melt.on(0), shader.model.cell.tunl.on(0), shader.model.cell.slide.on(0), shader.model.cell.fred.on(0), shader.model.cell.zha.on(0))<<shader.model.cell.fade
            }
            ave(0…1=0.5) {
                on(0…1=1)>>(shader.model.cell.fade.on(0), shader.model.cell.ave.on(0), shader.model.cell.melt.on(0), shader.model.cell.tunl.on(0), shader.model.cell.slide.on(0), shader.model.cell.fred.on(0), shader.model.cell.zha.on(0))<<shader.model.cell.ave
            }
            melt(0…1=0.5) {
                on(0…1=0)>>(shader.model.cell.fade.on(0), shader.model.cell.ave.on(0), shader.model.cell.melt.on(0), shader.model.cell.tunl.on(0), shader.model.cell.slide.on(0), shader.model.cell.fred.on(0), shader.model.cell.zha.on(0))<<shader.model.cell.melt
            }
            tunl(0…5=1) {
                on(0…1=0)>>(shader.model.cell.fade.on(0), shader.model.cell.ave.on(0), shader.model.cell.melt.on(0), shader.model.cell.tunl.on(0), shader.model.cell.slide.on(0), shader.model.cell.fred.on(0), shader.model.cell.zha.on(0))<<shader.model.cell.tunl
            }
            slide(0…7=3) {
                on(0…1=0)>>(shader.model.cell.fade.on(0), shader.model.cell.ave.on(0), shader.model.cell.melt.on(0), shader.model.cell.tunl.on(0), shader.model.cell.slide.on(0), shader.model.cell.fred.on(0), shader.model.cell.zha.on(0))<<shader.model.cell.slide
            }
            fred(0…4=4) {
                on(0…1=0)>>(shader.model.cell.fade.on(0), shader.model.cell.ave.on(0), shader.model.cell.melt.on(0), shader.model.cell.tunl.on(0), shader.model.cell.slide.on(0), shader.model.cell.fred.on(0), shader.model.cell.zha.on(0))<<shader.model.cell.fred
            }
            zha(0…6=2) {
                on(0…1=0)>>(shader.model.cell.fade.on(0), shader.model.cell.ave.on(0), shader.model.cell.melt.on(0), shader.model.cell.tunl.on(0), shader.model.cell.slide.on(0), shader.model.cell.fred.on(0), shader.model.cell.zha.on(0))<<shader.model.cell.zha
                bits(2…4=3)
                loops(11)
            }
        }
        pipe {
            draw(x 0…1=0.5, y 0…1=0.5) {
                on(0…1=0)
            }
            record {
                on(0…1=0)
            }
            camera {
                on(0…1=0)
                flip(0)
            }
            camix {
                on(0…1=0)
                mix(0)
            }
            color(val 0…1=0.1) // bitplane
            render {
                frame(x 0, y 0, w 1080, h 1920)
                repeat(x, y)
                mirror(x, y)
            }
        }
    }
    file {
        cell {
            fade("cell.fader.metal")
            ave("cell.ave.metal")
            melt("cell.melt.metal")
            tunl("cell.tunl.metal")
            slide("cell.slide.metal")
            fred("cell.fred.metal")
            zha("cell.zha.metal")
        }
        pipe {
            record camera("cell.camera.metal")
            camix("cell.camix.metal")
            draw("pipe.draw.metal")
            render("pipe.render.metal")
            color("pipe.color.metal")
        }
    }
}
menu {
    SW {
        view(depth 0, touch 1000001) {
            canvas(symbol "photo.artframe", touch 0) {
                tile(image "icon.shader.tile.png", touch 0) {
                    mirror(symbol "arrowtriangle.left.and.line.vertical.and.arrowtriangle.right", touch 0)
                    repeat(symbol "rectangle.grid.2x2", touch 0)
                    shift(image "icon.cell.scroll", touch 0)
                    tilt(image "icon.pen.tilt", touch 0)
                }
                color(image "icon.pal.main", touch 0) {
                    fade(symbol "slider.horizontal.below.rectangle", touch 0)
                    plane(symbol "square.3.layers.3d.down.right", touch 0)
                    zero(symbol "drop", touch 0)
                    one(symbol "drop.fill", touch 0)
                }
                speed(image "icon.speed", touch 0) {
                    fps(symbol "speedometer", touch 0)
                    run(symbol "goforward", touch 0)
                }
            }
            brush(symbol "paintbrush.pointed", touch 0) {
                size(symbol "circle.circle", touch 0)
                press(image "icon.pen.press", touch 0)
                tilt(image "icon.pen.tilt", touch 0) //(symbol "angle", touch 0)
            }
            cell(symbol "circle.grid.3x3", touch 1000002) {
                fade(image "icon.cell.fade", touch 0)
                ave(image "icon.cell.ave", touch 0)
                melt(image "icon.cell.melt", touch 0)
                tunl(image "icon.cell.tunl", touch 0)
                zha(image "icon.cell.zha", touch 0)
                slide(image "icon.cell.slide", touch 0)
                fred(image "icon.cell.fred", touch 0)
            }
            cam(symbol "camera", touch 0) {
                snap(symbol "camera.shutter.button", touch 0)
                fake(symbol "face.dashed", touch 0)
                real(symbol "face.smiling", touch 0)
                face(symbol "arrow.triangle.2.circlepath.camera", touch 0)
                mix(symbol "slider.horizontal.below.rectangle", touch 0)
            }
        }
        model {
            canvas {
                tile {
                    mirror(x 0…1=0, y 0…1=0)<>shader.model.pipe.render.mirror
                    repeat(x -1…1=0.5, y -1…1=0.5)<>shader.model.pipe.render.repeat
                    shift(x 0…1=0.5, y 0…1=0.5)<>shader.model.pipe.draw
                    tilt(tog 0…1=0)<>sky.input.tilt
                }
                color {
                    fade(val 0…1=0)<>sky.color.xfade
                    plane(val 0…1=0)<>shader.model.pipe.color
                    zero(tap 0…1=0)>>sky.draw.screen.fill(0)
                    one(tap 0…1=0)>>sky.draw.screen.fill(1)
                }
                speed {
                    fps(seg 0…60=60)<>sky.main.fps
                    run(tog 0…1=1)<>sky.main.run
                }
            }
            brush {
                size(val 0…1=0.5)>>(sky.draw.brush.size, menu.SW.model.brush.press(0))
                press(tog 0…1=1)>>sky.draw.brush.press
                tilt(tog 0…1=1)<>sky.input.tilt
            }
            cell {
                fade(val 2…3=2.2)>>shader.model.cell.fade
                ave(val 0…1=0.5)>>shader.model.cell.ave
                melt(val 0…1=0.5)>>shader.model.cell.melt
                tunl(seg 0…5=1)>>shader.model.cell.tunl
                zha(seg 0…6=2)>>shader.model.cell.zha
                slide(seg 0…7=3)>>shader.model.cell.slide
                fred(seg 0…4=4)>>shader.model.cell.fred
            }
            cam {
                snap(tap 0…1=0)
                fake(tog 0…1=0)>>shader.model.pipe.camix.on
                real(tog 0…1=1)>>shader.model.pipe.camera.on
                face(tog 0…1=1)>>shader.model.pipe.camera.flip
                mix(val 0…1=0.5)>>shader.model.pipe.camix.mix
            }
        }
    }
    SE @SW { // copy southwest corner
        view(depth 0, touch 1000001) {
            canvas(symbol "photo.artframe", touch 0) {
                tile(image "icon.shader.tile.png", touch 0) {
                    mirror(symbol "arrowtriangle.left.and.line.vertical.and.arrowtriangle.right", touch 0)
                    repeat(symbol "rectangle.grid.2x2", touch 0)
                    shift(image "icon.cell.scroll", touch 0)
                    tilt(image "icon.pen.tilt", touch 0)
                }
                color(image "icon.pal.main", touch 0) {
                    fade(symbol "slider.horizontal.below.rectangle", touch 0)
                    plane(symbol "square.3.layers.3d.down.right", touch 0)
                    zero(symbol "drop", touch 0)
                    one(symbol "drop.fill", touch 0)
                }
                speed(image "icon.speed", touch 0) {
                    fps(symbol "speedometer", touch 0)
                    run(symbol "goforward", touch 0)
                }
            }
            brush(symbol "paintbrush.pointed", touch 0) {
                size(symbol "circle.circle", touch 0)
                press(image "icon.pen.press", touch 0)
                tilt(image "icon.pen.tilt", touch 0) //(symbol "angle", touch 0)
            }
            cell(symbol "circle.grid.3x3", touch 1000002) {
                fade(image "icon.cell.fade", touch 0)
                ave(image "icon.cell.ave", touch 0)
                melt(image "icon.cell.melt", touch 0)
                tunl(image "icon.cell.tunl", touch 0)
                zha(image "icon.cell.zha", touch 0)
                slide(image "icon.cell.slide", touch 0)
                fred(image "icon.cell.fred", touch 0)
            }
            cam(symbol "camera", touch 0) {
                snap(symbol "camera.shutter.button", touch 0)
                fake(symbol "face.dashed", touch 0)
                real(symbol "face.smiling", touch 0)
                face(symbol "arrow.triangle.2.circlepath.camera", touch 0)
                mix(symbol "slider.horizontal.below.rectangle", touch 0)
            }
        }
        model {
            canvas {
                tile {
                    mirror(x 0…1=0, y 0…1=0)<>shader.model.pipe.render.mirror
                    repeat(x -1…1=0.5, y -1…1=0.5)<>shader.model.pipe.render.repeat
                    shift(x 0…1=0.5, y 0…1=0.5)<>shader.model.pipe.draw
                    tilt(tog 0…1=0)<>sky.input.tilt
                }
                color {
                    fade(val 0…1=0)<>sky.color.xfade
                    plane(val 0…1=0)<>shader.model.pipe.color
                    zero(tap 0…1=0)>>sky.draw.screen.fill(0)
                    one(tap 0…1=0)>>sky.draw.screen.fill(1)
                }
                speed {
                    fps(seg 0…60=60)<>sky.main.fps
                    run(tog 0…1=1)<>sky.main.run
                }
            }
            brush {
                size(val 0…1=0.5)>>(sky.draw.brush.size, menu.SE.model.brush.press(0))
                press(tog 0…1=1)>>sky.draw.brush.press
                tilt(tog 0…1=1)<>sky.input.tilt
            }
            cell {
                fade(val 2…3=2.2)>>shader.model.cell.fade
                ave(val 0…1=0.5)>>shader.model.cell.ave
                melt(val 0…1=0.5)>>shader.model.cell.melt
                tunl(seg 0…5=1)>>shader.model.cell.tunl
                zha(seg 0…6=2)>>shader.model.cell.zha
                slide(seg 0…7=3)>>shader.model.cell.slide
                fred(seg 0…4=4)>>shader.model.cell.fred
            }
            cam {
                snap(tap 0…1=0)
                fake(tog 0…1=0)>>shader.model.pipe.camix.on
                real(tog 0…1=1)>>shader.model.pipe.camera.on
                face(tog 0…1=1)>>shader.model.pipe.camera.flip
                mix(val 0…1=0.5)>>shader.model.pipe.camix.mix
            }
        }
    }
}
midi { // musical instrument device interface
    input { // midi input
        note { // note on/off from 0 thru 127
            on(num 0…127, velo 0…127, chan 1…32, port 1…16, time)>>(midi.notes.dot, midi.output.note.on)
            off(num 0…127, velo 0…127, chan 1…32, port 1…16, time)>>(midi.input.note.on, midi.output.note.off)
        }
        controller(cc 0…127, val 0…127, chan 1…32, port 1…16, time)>>(midi.cc.skypad.plane, midi.cc.skypad.xfade, midi.cc.roli.lightpad.x, midi.cc.roli.lightpad.y, midi.cc.roli.lightpad.z, midi.cc.roli.loopblock.mode, midi.cc.roli.loopblock.mute, midi.cc.roli.loopblock.metro, midi.cc.roli.loopblock.skip, midi.cc.roli.loopblock.back, midi.cc.roli.loopblock.play, midi.cc.roli.loopblock.record, midi.cc.roli.loopblock.learn, midi.cc.roli.loopblock.prev, midi.cc.roli.loopblock.next)
        afterTouch(num 0…127, val 0…127, chan 1…32, port 1…16, time)
        pitchBend(val 0…16384=8192, chan 1…32, port 1…16, time)
        programChange(num 0…255, chan 1…32, port 1…16, time) //1, 632, 255
        nrpn(num 0…16383, val 0…1, chan, time)>>(midi.skypad.plane, midi.skypad.xfade)
    }
    output @input {
        note { // note on/off from 0 thru 127
            on(num 0…127, velo 0…127, chan 1…32, port 1…16, time)>>(midi.notes.dot, midi.output.note.on)
            off(num 0…127, velo 0…127, chan 1…32, port 1…16, time)>>(midi.input.note.on, midi.output.note.off)
        }
        controller(cc 0…127, val 0…127, chan 1…32, port 1…16, time)>>(midi.cc.skypad.plane, midi.cc.skypad.xfade, midi.cc.roli.lightpad.x, midi.cc.roli.lightpad.y, midi.cc.roli.lightpad.z, midi.cc.roli.loopblock.mode, midi.cc.roli.loopblock.mute, midi.cc.roli.loopblock.metro, midi.cc.roli.loopblock.skip, midi.cc.roli.loopblock.back, midi.cc.roli.loopblock.play, midi.cc.roli.loopblock.record, midi.cc.roli.loopblock.learn, midi.cc.roli.loopblock.prev, midi.cc.roli.loopblock.next)
        afterTouch(num 0…127, val 0…127, chan 1…32, port 1…16, time)
        pitchBend(val 0…16384=8192, chan 1…32, port 1…16, time)
        programChange(num 0…255, chan 1…32, port 1…16, time) //1, 632, 255
        nrpn(num 0…16383, val 0…1, chan, time)>>(midi.skypad.plane, midi.skypad.xfade)
    }
    skypad {
        plane(num == 129, val 0…1, chan, time)<>shader.model.pipe.color
        xfade(num == 130, val 0…1, chan, time)<>sky.color.xfade
    }
    cc {
        skypad {
            plane(cc == 11, val 0…127, chan, time)<>shader.model.pipe.color
            xfade(cc == 10, val 0…127, chan, time)<>sky.color.xfade
        }
        roli {
            lightpad {
                x(cc == 114, val 0…127, chan, time)
                y(cc == 113, val 0…127, chan, time)
                z(cc == 115, val 0…127, chan, time)
            }
            loopblock {
                mode(cc == 102, val 0…127, chan, time)
                mute(cc == 103, val 0…127, chan, time)
                metro(cc == 104, val 0…127, chan, time)
                skip(cc == 105, val 0…127, chan, time)
                back(cc == 106, val 0…127, chan, time)
                play(cc == 107, val 0…127, chan, time)
                record(cc == 108, val 0…127, chan, time)
                learn(cc == 109, val 0…127, chan, time)
                prev(cc == 110, val 0…127, chan, time)
                next(cc == 111, val 0…127, chan, time)
            }
        }
    }
    notes {
        dot(x : num % 12, y : num _/ 12, z : velo)>>sky.draw.dot
    }
    _cc {
        main {
            modWheel(num == 1, val, chan, time)
            volume(num == 7, val, chan, time)
            balance(num == 8, val, chan, time)
            panPosition(num == 10, val, chan, time)
            expression(num == 11, val, chan, time)
            controller(num in 32…63, val, chan, time) // controller 0…31
            portamento {
                time(num == 5, val, chan, time)
                amount(num == 84, val, chan, time)
            }
        }
        pedal {
            hold(num == 64, val, chan, time)
            porta(num == 65, val, chan, time)
            sosta(num == 66, val, chan, time)
            _soft(num == 67, val, chan, time)
            _legato(num == 68, val, chan, time)
            _hold2(num == 69, val, chan, time)
        }
        _cc {
            _main2 {
                bankSelect(num == 0, val, chan, time)
                breathCtrl(num == 2, val, chan, time)
                footPedal(num == 4, val, chan, time)
                dataEntry(num == 6, val, chan, time)
                effectControl1(num == 12, val, chan, time)
                effectControl2(num == 13, val, chan, time)
            }
            _sound {
                soundVariation(num == 70, val, chan, time)
                resonance(num == 71, val, chan, time)
                soundReleaseTime(num == 72, val, chan, time)
                soundAttackTime(num == 73, val, chan, time)
                frequencyCutoff(num == 74, val, chan, time)
                timbre(num == 71, val, chan, time)
                brightness(num == 74, val, chan, time)
            }
            _button {
                button1(num == 80, val, chan, time)
                button2(num == 81, val, chan, time)
                button3(num == 82, val, chan, time)
                button4(num == 83, val, chan, time)
                decayor(num == 80, val, chan, time)
                hiPassFilter(num == 81, val, chan, time)
                generalPurpose82(num == 82, val, chan, time)
                generalPurpose83(num == 83, val, chan, time)
            }
            _roland {
                rolandToneLevel1(num == 80, val, chan, time)
                rolandToneLevel2(num == 81, val, chan, time)
                rolandToneLevel3(num == 82, val, chan, time)
                rolandToneLevel4(num == 83, val, chan, time)
            }
            _level {
                reverbLevel(num == 91, val, chan, time)
                tremoloLevel(num == 92, val, chan, time)
                chorusLevel(num == 93, val, chan, time)
                detuneLevel(num == 94, val, chan, time)
                phaserLevel(num == 95, val, chan, time)
            }
            _parameter {
                dataButtonIncrement(num == 96, val, chan, time)
                dataButtonDecrement(num == 97, val, chan, time)
                nonregisteredParameterLSB(num == 98, val, chan, time)
                nonregisteredParameterMSB(num == 99, val, chan, time)
                registeredParameterLSB(num == 100, val, chan, time)
                registeredParameterMSB(num == 101, val, chan, time)
            }
            _soundControl {
                soundControl6(num == 75, val, chan, time)
                soundControl7(num == 76, val, chan, time)
                soundControl8(num == 77, val, chan, time)
                soundControl9(num == 78, val, chan, time)
                soundControl10(num == 79, val, chan, time)
            }
            _undefined {
                undefined_3(num == 3, val, chan, time)
                undefined_9(num == 9, val, chan, time)
                undefined_14_31(num in 14…31, val, chan, time)
                undefined_85_90(num in 85…90, val, chan, time)
                undefined_102_119(num in 102…119, val, chan, time)
            }
            _mode {
                allSoundOff(num == 120, val, chan, time)
                allControllersOff(num == 121, val, chan, time)
                localKeyboard(num == 122, val, chan, time)
                allNotesOff(num == 123, val, chan, time)
                monoOperation(num == 126, val, chan, time)
                polyMode(num == 127, val, chan, time)
            }
            _omni {
                omniModeOff(num == 124, val, chan, time)
                omniModeOn(num == 125, val, chan, time)
                omniMode(0…1)<<(midi._cc._cc._omni.omniModeOff(0), midi._cc._cc._omni.omniModeOn(1))
            }
        }
    }
}



scriptNow ⟹
sky {
    input {
        radius(1…92=9:17.618905)
        force(0…0.5:0.131811)
    }
    draw.brush.size(1…64=10:17.618905)
}
shader.model.cell {
    ave.on(0…1=1:0)
    melt.on(0…1=0:0.5)
}
menu.SW.view(depth 0, touch 1000001).cell(symbol "circle.grid.3x3", touch 1000002)


🅢 Midi Setup change
*** radius [def, now, compact, parens, delta].[thru, min, max, dflt, now] : 17.618905488774015
*** force [def, now, compact, parens, delta].[thru, min, max, now] : 0.13181118899766792
*** size [def, now, compact, parens, delta].[thru, min, max, dflt, now] : 17.618905488774015
*** on [def, now, compact, parens, delta].[thru, min, max, dflt, now] : 0.0
*** on [def, now, compact, parens, delta].[thru, min, max, dflt, now] : 0.5



scriptDef ⟹
sky { // visual music synth
    main { // main controls
        fps(1…60=60) // frames per second
        run(1) // currently running
    }
    pipeline { // default metal pipeline at atartup
        draw("draw") // drawing layer
        ave("compute") // compute layer
        color("color") // colorizing layer
        render("render") // render layer al
    }
    color { // false color mapping palette
        pal0("roygbik") // palette 0: (r)ed (o)range (y)ellow …
        pal1("wKZ") // palette 1: (w)hite blac(K) fractali(Z)e
        xfade(val 0…1=0.5)
    }
    input { // phone and tablet pencil input
        azimuth(x -0.2…0.2, y -0.2…0.2)>>shader.model.pipe.draw
        accel(x -0.3…0.3, y -0.3…0.3, z -0.3…0.3) { // accelerometer
            on(0…1)
        }
        radius(1…92=9) // finger silhouette
        tilt(0…1) // use tilt
        force(0…0.5)>>sky.draw.brush.size // pen pressure
    }
    draw { // draw on metal layer
        screen { // fill 32 bit universe
            fill(0) // all zeros 0x00000000
        }
        brush { // type of brush and range
            size(1…64=10) // range of radius
            press(0…1=1) // pressure changes size
            index(1…255=127) // index in 256 color palette
                             // <<(osc.tuio.z osc.manos˚z) // redirect from OSC
        }
        line { // place holder for line drawing
            prev(x 0…1, y 0…1) // staring point of segment
            next(x 0…1, y 0…1) // endint point of segment
        }
        dot(x, y, z)
    }
}
shader {
    model {
        cell {
            fade(0…1=0.5) {
                on(0…1=0)>>(shader.model.cell.fade.on(0), shader.model.cell.ave.on(0), shader.model.cell.melt.on(0), shader.model.cell.tunl.on(0), shader.model.cell.slide.on(0), shader.model.cell.fred.on(0), shader.model.cell.zha.on(0))<<shader.model.cell.fade
            }
            ave(0…1=0.5) {
                on(0…1=1)>>(shader.model.cell.fade.on(0), shader.model.cell.ave.on(0), shader.model.cell.melt.on(0), shader.model.cell.tunl.on(0), shader.model.cell.slide.on(0), shader.model.cell.fred.on(0), shader.model.cell.zha.on(0))<<shader.model.cell.ave
            }
            melt(0…1=0.5) {
                on(0…1=0)>>(shader.model.cell.fade.on(0), shader.model.cell.ave.on(0), shader.model.cell.melt.on(0), shader.model.cell.tunl.on(0), shader.model.cell.slide.on(0), shader.model.cell.fred.on(0), shader.model.cell.zha.on(0))<<shader.model.cell.melt
            }
            tunl(0…5=1) {
                on(0…1=0)>>(shader.model.cell.fade.on(0), shader.model.cell.ave.on(0), shader.model.cell.melt.on(0), shader.model.cell.tunl.on(0), shader.model.cell.slide.on(0), shader.model.cell.fred.on(0), shader.model.cell.zha.on(0))<<shader.model.cell.tunl
            }
            slide(0…7=3) {
                on(0…1=0)>>(shader.model.cell.fade.on(0), shader.model.cell.ave.on(0), shader.model.cell.melt.on(0), shader.model.cell.tunl.on(0), shader.model.cell.slide.on(0), shader.model.cell.fred.on(0), shader.model.cell.zha.on(0))<<shader.model.cell.slide
            }
            fred(0…4=4) {
                on(0…1=0)>>(shader.model.cell.fade.on(0), shader.model.cell.ave.on(0), shader.model.cell.melt.on(0), shader.model.cell.tunl.on(0), shader.model.cell.slide.on(0), shader.model.cell.fred.on(0), shader.model.cell.zha.on(0))<<shader.model.cell.fred
            }
            zha(0…6=2) {
                on(0…1=0)>>(shader.model.cell.fade.on(0), shader.model.cell.ave.on(0), shader.model.cell.melt.on(0), shader.model.cell.tunl.on(0), shader.model.cell.slide.on(0), shader.model.cell.fred.on(0), shader.model.cell.zha.on(0))<<shader.model.cell.zha
                bits(2…4=3)
                loops(11)
            }
        }
        pipe {
            draw(x 0…1=0.5, y 0…1=0.5) {
                on(0…1=0)
            }
            record {
                on(0…1=0)
            }
            camera {
                on(0…1=0)
                flip(0)
            }
            camix {
                on(0…1=0)
                mix(0)
            }
            color(val 0…1=0.1) // bitplane
            render {
                frame(x 0, y 0, w 1080, h 1920)
                repeat(x, y)
                mirror(x, y)
            }
        }
    }
    file {
        cell {
            fade("cell.fader.metal")
            ave("cell.ave.metal")
            melt("cell.melt.metal")
            tunl("cell.tunl.metal")
            slide("cell.slide.metal")
            fred("cell.fred.metal")
            zha("cell.zha.metal")
        }
        pipe {
            record camera("cell.camera.metal")
            camix("cell.camix.metal")
            draw("pipe.draw.metal")
            render("pipe.render.metal")
            color("pipe.color.metal")
        }
    }
}
menu {
    SW {
        view(depth 0, touch 1000001) {
            canvas(symbol "photo.artframe", touch 0) {
                tile(image "icon.shader.tile.png", touch 0) {
                    mirror(symbol "arrowtriangle.left.and.line.vertical.and.arrowtriangle.right", touch 0)
                    repeat(symbol "rectangle.grid.2x2", touch 0)
                    shift(image "icon.cell.scroll", touch 0)
                    tilt(image "icon.pen.tilt", touch 0)
                }
                color(image "icon.pal.main", touch 0) {
                    fade(symbol "slider.horizontal.below.rectangle", touch 0)
                    plane(symbol "square.3.layers.3d.down.right", touch 0)
                    zero(symbol "drop", touch 0)
                    one(symbol "drop.fill", touch 0)
                }
                speed(image "icon.speed", touch 0) {
                    fps(symbol "speedometer", touch 0)
                    run(symbol "goforward", touch 0)
                }
            }
            brush(symbol "paintbrush.pointed", touch 0) {
                size(symbol "circle.circle", touch 0)
                press(image "icon.pen.press", touch 0)
                tilt(image "icon.pen.tilt", touch 0) //(symbol "angle", touch 0)
            }
            cell(symbol "circle.grid.3x3", touch 1000002) {
                fade(image "icon.cell.fade", touch 0)
                ave(image "icon.cell.ave", touch 0)
                melt(image "icon.cell.melt", touch 0)
                tunl(image "icon.cell.tunl", touch 0)
                zha(image "icon.cell.zha", touch 0)
                slide(image "icon.cell.slide", touch 0)
                fred(image "icon.cell.fred", touch 0)
            }
            cam(symbol "camera", touch 0) {
                snap(symbol "camera.shutter.button", touch 0)
                fake(symbol "face.dashed", touch 0)
                real(symbol "face.smiling", touch 0)
                face(symbol "arrow.triangle.2.circlepath.camera", touch 0)
                mix(symbol "slider.horizontal.below.rectangle", touch 0)
            }
        }
        model {
            canvas {
                tile {
                    mirror(x 0…1=0, y 0…1=0)<>shader.model.pipe.render.mirror
                    repeat(x -1…1=0.5, y -1…1=0.5)<>shader.model.pipe.render.repeat
                    shift(x 0…1=0.5, y 0…1=0.5)<>shader.model.pipe.draw
                    tilt(tog 0…1=0)<>sky.input.tilt
                }
                color {
                    fade(val 0…1=0)<>sky.color.xfade
                    plane(val 0…1=0)<>shader.model.pipe.color
                    zero(tap 0…1=0)>>sky.draw.screen.fill(0)
                    one(tap 0…1=0)>>sky.draw.screen.fill(1)
                }
                speed {
                    fps(seg 0…60=60)<>sky.main.fps
                    run(tog 0…1=1)<>sky.main.run
                }
            }
            brush {
                size(val 0…1=0.5)>>(sky.draw.brush.size, menu.SW.model.brush.press(0))
                press(tog 0…1=1)>>sky.draw.brush.press
                tilt(tog 0…1=1)<>sky.input.tilt
            }
            cell {
                fade(val 2…3=2.2)>>shader.model.cell.fade
                ave(val 0…1=0.5)>>shader.model.cell.ave
                melt(val 0…1=0.5)>>shader.model.cell.melt
                tunl(seg 0…5=1)>>shader.model.cell.tunl
                zha(seg 0…6=2)>>shader.model.cell.zha
                slide(seg 0…7=3)>>shader.model.cell.slide
                fred(seg 0…4=4)>>shader.model.cell.fred
            }
            cam {
                snap(tap 0…1=0)
                fake(tog 0…1=0)>>shader.model.pipe.camix.on
                real(tog 0…1=1)>>shader.model.pipe.camera.on
                face(tog 0…1=1)>>shader.model.pipe.camera.flip
                mix(val 0…1=0.5)>>shader.model.pipe.camix.mix
            }
        }
    }
    SE @SW { // copy southwest corner
        view(depth 0, touch 1000001) {
            canvas(symbol "photo.artframe", touch 0) {
                tile(image "icon.shader.tile.png", touch 0) {
                    mirror(symbol "arrowtriangle.left.and.line.vertical.and.arrowtriangle.right", touch 0)
                    repeat(symbol "rectangle.grid.2x2", touch 0)
                    shift(image "icon.cell.scroll", touch 0)
                    tilt(image "icon.pen.tilt", touch 0)
                }
                color(image "icon.pal.main", touch 0) {
                    fade(symbol "slider.horizontal.below.rectangle", touch 0)
                    plane(symbol "square.3.layers.3d.down.right", touch 0)
                    zero(symbol "drop", touch 0)
                    one(symbol "drop.fill", touch 0)
                }
                speed(image "icon.speed", touch 0) {
                    fps(symbol "speedometer", touch 0)
                    run(symbol "goforward", touch 0)
                }
            }
            brush(symbol "paintbrush.pointed", touch 0) {
                size(symbol "circle.circle", touch 0)
                press(image "icon.pen.press", touch 0)
                tilt(image "icon.pen.tilt", touch 0) //(symbol "angle", touch 0)
            }
            cell(symbol "circle.grid.3x3", touch 1000002) {
                fade(image "icon.cell.fade", touch 0)
                ave(image "icon.cell.ave", touch 0)
                melt(image "icon.cell.melt", touch 0)
                tunl(image "icon.cell.tunl", touch 0)
                zha(image "icon.cell.zha", touch 0)
                slide(image "icon.cell.slide", touch 0)
                fred(image "icon.cell.fred", touch 0)
            }
            cam(symbol "camera", touch 0) {
                snap(symbol "camera.shutter.button", touch 0)
                fake(symbol "face.dashed", touch 0)
                real(symbol "face.smiling", touch 0)
                face(symbol "arrow.triangle.2.circlepath.camera", touch 0)
                mix(symbol "slider.horizontal.below.rectangle", touch 0)
            }
        }
        model {
            canvas {
                tile {
                    mirror(x 0…1=0, y 0…1=0)<>shader.model.pipe.render.mirror
                    repeat(x -1…1=0.5, y -1…1=0.5)<>shader.model.pipe.render.repeat
                    shift(x 0…1=0.5, y 0…1=0.5)<>shader.model.pipe.draw
                    tilt(tog 0…1=0)<>sky.input.tilt
                }
                color {
                    fade(val 0…1=0)<>sky.color.xfade
                    plane(val 0…1=0)<>shader.model.pipe.color
                    zero(tap 0…1=0)>>sky.draw.screen.fill(0)
                    one(tap 0…1=0)>>sky.draw.screen.fill(1)
                }
                speed {
                    fps(seg 0…60=60)<>sky.main.fps
                    run(tog 0…1=1)<>sky.main.run
                }
            }
            brush {
                size(val 0…1=0.5)>>(sky.draw.brush.size, menu.SE.model.brush.press(0))
                press(tog 0…1=1)>>sky.draw.brush.press
                tilt(tog 0…1=1)<>sky.input.tilt
            }
            cell {
                fade(val 2…3=2.2)>>shader.model.cell.fade
                ave(val 0…1=0.5)>>shader.model.cell.ave
                melt(val 0…1=0.5)>>shader.model.cell.melt
                tunl(seg 0…5=1)>>shader.model.cell.tunl
                zha(seg 0…6=2)>>shader.model.cell.zha
                slide(seg 0…7=3)>>shader.model.cell.slide
                fred(seg 0…4=4)>>shader.model.cell.fred
            }
            cam {
                snap(tap 0…1=0)
                fake(tog 0…1=0)>>shader.model.pipe.camix.on
                real(tog 0…1=1)>>shader.model.pipe.camera.on
                face(tog 0…1=1)>>shader.model.pipe.camera.flip
                mix(val 0…1=0.5)>>shader.model.pipe.camix.mix
            }
        }
    }
}
midi { // musical instrument device interface
    input { // midi input
        note { // note on/off from 0 thru 127
            on(num 0…127, velo 0…127, chan 1…32, port 1…16, time)>>(midi.notes.dot, midi.output.note.on)
            off(num 0…127, velo 0…127, chan 1…32, port 1…16, time)>>(midi.input.note.on, midi.output.note.off)
        }
        controller(cc 0…127, val 0…127, chan 1…32, port 1…16, time)>>(midi.cc.skypad.plane, midi.cc.skypad.xfade, midi.cc.roli.lightpad.x, midi.cc.roli.lightpad.y, midi.cc.roli.lightpad.z, midi.cc.roli.loopblock.mode, midi.cc.roli.loopblock.mute, midi.cc.roli.loopblock.metro, midi.cc.roli.loopblock.skip, midi.cc.roli.loopblock.back, midi.cc.roli.loopblock.play, midi.cc.roli.loopblock.record, midi.cc.roli.loopblock.learn, midi.cc.roli.loopblock.prev, midi.cc.roli.loopblock.next)
        afterTouch(num 0…127, val 0…127, chan 1…32, port 1…16, time)
        pitchBend(val 0…16384=8192, chan 1…32, port 1…16, time)
        programChange(num 0…255, chan 1…32, port 1…16, time) //1, 632, 255
        nrpn(num 0…16383, val 0…1, chan, time)>>(midi.skypad.plane, midi.skypad.xfade)
    }
    output @input {
        note { // note on/off from 0 thru 127
            on(num 0…127, velo 0…127, chan 1…32, port 1…16, time)>>(midi.notes.dot, midi.output.note.on)
            off(num 0…127, velo 0…127, chan 1…32, port 1…16, time)>>(midi.input.note.on, midi.output.note.off)
        }
        controller(cc 0…127, val 0…127, chan 1…32, port 1…16, time)>>(midi.cc.skypad.plane, midi.cc.skypad.xfade, midi.cc.roli.lightpad.x, midi.cc.roli.lightpad.y, midi.cc.roli.lightpad.z, midi.cc.roli.loopblock.mode, midi.cc.roli.loopblock.mute, midi.cc.roli.loopblock.metro, midi.cc.roli.loopblock.skip, midi.cc.roli.loopblock.back, midi.cc.roli.loopblock.play, midi.cc.roli.loopblock.record, midi.cc.roli.loopblock.learn, midi.cc.roli.loopblock.prev, midi.cc.roli.loopblock.next)
        afterTouch(num 0…127, val 0…127, chan 1…32, port 1…16, time)
        pitchBend(val 0…16384=8192, chan 1…32, port 1…16, time)
        programChange(num 0…255, chan 1…32, port 1…16, time) //1, 632, 255
        nrpn(num 0…16383, val 0…1, chan, time)>>(midi.skypad.plane, midi.skypad.xfade)
    }
    skypad {
        plane(num == 129, val 0…1, chan, time)<>shader.model.pipe.color
        xfade(num == 130, val 0…1, chan, time)<>sky.color.xfade
    }
    cc {
        skypad {
            plane(cc == 11, val 0…127, chan, time)<>shader.model.pipe.color
            xfade(cc == 10, val 0…127, chan, time)<>sky.color.xfade
        }
        roli {
            lightpad {
                x(cc == 114, val 0…127, chan, time)
                y(cc == 113, val 0…127, chan, time)
                z(cc == 115, val 0…127, chan, time)
            }
            loopblock {
                mode(cc == 102, val 0…127, chan, time)
                mute(cc == 103, val 0…127, chan, time)
                metro(cc == 104, val 0…127, chan, time)
                skip(cc == 105, val 0…127, chan, time)
                back(cc == 106, val 0…127, chan, time)
                play(cc == 107, val 0…127, chan, time)
                record(cc == 108, val 0…127, chan, time)
                learn(cc == 109, val 0…127, chan, time)
                prev(cc == 110, val 0…127, chan, time)
                next(cc == 111, val 0…127, chan, time)
            }
        }
    }
    notes {
        dot(x : num % 12, y : num _/ 12, z : velo)>>sky.draw.dot
    }
    _cc {
        main {
            modWheel(num == 1, val, chan, time)
            volume(num == 7, val, chan, time)
            balance(num == 8, val, chan, time)
            panPosition(num == 10, val, chan, time)
            expression(num == 11, val, chan, time)
            controller(num in 32…63, val, chan, time) // controller 0…31
            portamento {
                time(num == 5, val, chan, time)
                amount(num == 84, val, chan, time)
            }
        }
        pedal {
            hold(num == 64, val, chan, time)
            porta(num == 65, val, chan, time)
            sosta(num == 66, val, chan, time)
            _soft(num == 67, val, chan, time)
            _legato(num == 68, val, chan, time)
            _hold2(num == 69, val, chan, time)
        }
        _cc {
            _main2 {
                bankSelect(num == 0, val, chan, time)
                breathCtrl(num == 2, val, chan, time)
                footPedal(num == 4, val, chan, time)
                dataEntry(num == 6, val, chan, time)
                effectControl1(num == 12, val, chan, time)
                effectControl2(num == 13, val, chan, time)
            }
            _sound {
                soundVariation(num == 70, val, chan, time)
                resonance(num == 71, val, chan, time)
                soundReleaseTime(num == 72, val, chan, time)
                soundAttackTime(num == 73, val, chan, time)
                frequencyCutoff(num == 74, val, chan, time)
                timbre(num == 71, val, chan, time)
                brightness(num == 74, val, chan, time)
            }
            _button {
                button1(num == 80, val, chan, time)
                button2(num == 81, val, chan, time)
                button3(num == 82, val, chan, time)
                button4(num == 83, val, chan, time)
                decayor(num == 80, val, chan, time)
                hiPassFilter(num == 81, val, chan, time)
                generalPurpose82(num == 82, val, chan, time)
                generalPurpose83(num == 83, val, chan, time)
            }
            _roland {
                rolandToneLevel1(num == 80, val, chan, time)
                rolandToneLevel2(num == 81, val, chan, time)
                rolandToneLevel3(num == 82, val, chan, time)
                rolandToneLevel4(num == 83, val, chan, time)
            }
            _level {
                reverbLevel(num == 91, val, chan, time)
                tremoloLevel(num == 92, val, chan, time)
                chorusLevel(num == 93, val, chan, time)
                detuneLevel(num == 94, val, chan, time)
                phaserLevel(num == 95, val, chan, time)
            }
            _parameter {
                dataButtonIncrement(num == 96, val, chan, time)
                dataButtonDecrement(num == 97, val, chan, time)
                nonregisteredParameterLSB(num == 98, val, chan, time)
                nonregisteredParameterMSB(num == 99, val, chan, time)
                registeredParameterLSB(num == 100, val, chan, time)
                registeredParameterMSB(num == 101, val, chan, time)
            }
            _soundControl {
                soundControl6(num == 75, val, chan, time)
                soundControl7(num == 76, val, chan, time)
                soundControl8(num == 77, val, chan, time)
                soundControl9(num == 78, val, chan, time)
                soundControl10(num == 79, val, chan, time)
            }
            _undefined {
                undefined_3(num == 3, val, chan, time)
                undefined_9(num == 9, val, chan, time)
                undefined_14_31(num in 14…31, val, chan, time)
                undefined_85_90(num in 85…90, val, chan, time)
                undefined_102_119(num in 102…119, val, chan, time)
            }
            _mode {
                allSoundOff(num == 120, val, chan, time)
                allControllersOff(num == 121, val, chan, time)
                localKeyboard(num == 122, val, chan, time)
                allNotesOff(num == 123, val, chan, time)
                monoOperation(num == 126, val, chan, time)
                polyMode(num == 127, val, chan, time)
            }
            _omni {
                omniModeOff(num == 124, val, chan, time)
                omniModeOn(num == 125, val, chan, time)
                omniMode(0…1)<<(midi._cc._cc._omni.omniModeOff(0), midi._cc._cc._omni.omniModeOn(1))
            }
        }
    }
}



scriptNow ⟹
sky {
    input {
        radius(1…92=9:17.618905)
        force(0…0.5:0.131811)
    }
    draw.brush.size(1…64=10:17.618905)
}
shader.model.cell {
    ave.on(0…1=1:0)
    melt.on(0…1=0:0.5)
}
menu.SW.view(depth 0, touch 1000001).cell(symbol "circle.grid.3x3", touch 1000002)


*** radius [def, now, compact, parens, delta].[thru, min, max, dflt, now] : 17.618905488774015
*** force [def, now, compact, parens, delta].[thru, min, max, now] : 0.13181118899766792
*** size [def, now, compact, parens, delta].[thru, min, max, dflt, now] : 17.618905488774015
*** on [def, now, compact, parens, delta].[thru, min, max, dflt, now] : 0.0
*** on [def, now, compact, parens, delta].[thru, min, max, dflt, now] : 0.5



scriptDef ⟹
sky { // visual music synth
    main { // main controls
        fps(1…60=60) // frames per second
        run(1) // currently running
    }
    pipeline { // default metal pipeline at atartup
        draw("draw") // drawing layer
        ave("compute") // compute layer
        color("color") // colorizing layer
        render("render") // render layer al
    }
    color { // false color mapping palette
        pal0("roygbik") // palette 0: (r)ed (o)range (y)ellow …
        pal1("wKZ") // palette 1: (w)hite blac(K) fractali(Z)e
        xfade(val 0…1=0.5)
    }
    input { // phone and tablet pencil input
        azimuth(x -0.2…0.2, y -0.2…0.2)>>shader.model.pipe.draw
        accel(x -0.3…0.3, y -0.3…0.3, z -0.3…0.3) { // accelerometer
            on(0…1)
        }
        radius(1…92=9) // finger silhouette
        tilt(0…1) // use tilt
        force(0…0.5)>>sky.draw.brush.size // pen pressure
    }
    draw { // draw on metal layer
        screen { // fill 32 bit universe
            fill(0) // all zeros 0x00000000
        }
        brush { // type of brush and range
            size(1…64=10) // range of radius
            press(0…1=1) // pressure changes size
            index(1…255=127) // index in 256 color palette
                             // <<(osc.tuio.z osc.manos˚z) // redirect from OSC
        }
        line { // place holder for line drawing
            prev(x 0…1, y 0…1) // staring point of segment
            next(x 0…1, y 0…1) // endint point of segment
        }
        dot(x, y, z)
    }
}
shader {
    model {
        cell {
            fade(0…1=0.5) {
                on(0…1=0)>>(shader.model.cell.fade.on(0), shader.model.cell.ave.on(0), shader.model.cell.melt.on(0), shader.model.cell.tunl.on(0), shader.model.cell.slide.on(0), shader.model.cell.fred.on(0), shader.model.cell.zha.on(0))<<shader.model.cell.fade
            }
            ave(0…1=0.5) {
                on(0…1=1)>>(shader.model.cell.fade.on(0), shader.model.cell.ave.on(0), shader.model.cell.melt.on(0), shader.model.cell.tunl.on(0), shader.model.cell.slide.on(0), shader.model.cell.fred.on(0), shader.model.cell.zha.on(0))<<shader.model.cell.ave
            }
            melt(0…1=0.5) {
                on(0…1=0)>>(shader.model.cell.fade.on(0), shader.model.cell.ave.on(0), shader.model.cell.melt.on(0), shader.model.cell.tunl.on(0), shader.model.cell.slide.on(0), shader.model.cell.fred.on(0), shader.model.cell.zha.on(0))<<shader.model.cell.melt
            }
            tunl(0…5=1) {
                on(0…1=0)>>(shader.model.cell.fade.on(0), shader.model.cell.ave.on(0), shader.model.cell.melt.on(0), shader.model.cell.tunl.on(0), shader.model.cell.slide.on(0), shader.model.cell.fred.on(0), shader.model.cell.zha.on(0))<<shader.model.cell.tunl
            }
            slide(0…7=3) {
                on(0…1=0)>>(shader.model.cell.fade.on(0), shader.model.cell.ave.on(0), shader.model.cell.melt.on(0), shader.model.cell.tunl.on(0), shader.model.cell.slide.on(0), shader.model.cell.fred.on(0), shader.model.cell.zha.on(0))<<shader.model.cell.slide
            }
            fred(0…4=4) {
                on(0…1=0)>>(shader.model.cell.fade.on(0), shader.model.cell.ave.on(0), shader.model.cell.melt.on(0), shader.model.cell.tunl.on(0), shader.model.cell.slide.on(0), shader.model.cell.fred.on(0), shader.model.cell.zha.on(0))<<shader.model.cell.fred
            }
            zha(0…6=2) {
                on(0…1=0)>>(shader.model.cell.fade.on(0), shader.model.cell.ave.on(0), shader.model.cell.melt.on(0), shader.model.cell.tunl.on(0), shader.model.cell.slide.on(0), shader.model.cell.fred.on(0), shader.model.cell.zha.on(0))<<shader.model.cell.zha
                bits(2…4=3)
                loops(11)
            }
        }
        pipe {
            draw(x 0…1=0.5, y 0…1=0.5) {
                on(0…1=0)
            }
            record {
                on(0…1=0)
            }
            camera {
                on(0…1=0)
                flip(0)
            }
            camix {
                on(0…1=0)
                mix(0)
            }
            color(val 0…1=0.1) // bitplane
            render {
                frame(x 0, y 0, w 1080, h 1920)
                repeat(x, y)
                mirror(x, y)
            }
        }
    }
    file {
        cell {
            fade("cell.fader.metal")
            ave("cell.ave.metal")
            melt("cell.melt.metal")
            tunl("cell.tunl.metal")
            slide("cell.slide.metal")
            fred("cell.fred.metal")
            zha("cell.zha.metal")
        }
        pipe {
            record camera("cell.camera.metal")
            camix("cell.camix.metal")
            draw("pipe.draw.metal")
            render("pipe.render.metal")
            color("pipe.color.metal")
        }
    }
}
menu {
    SW {
        view(depth 0, touch 1000001) {
            canvas(symbol "photo.artframe", touch 0) {
                tile(image "icon.shader.tile.png", touch 0) {
                    mirror(symbol "arrowtriangle.left.and.line.vertical.and.arrowtriangle.right", touch 0)
                    repeat(symbol "rectangle.grid.2x2", touch 0)
                    shift(image "icon.cell.scroll", touch 0)
                    tilt(image "icon.pen.tilt", touch 0)
                }
                color(image "icon.pal.main", touch 0) {
                    fade(symbol "slider.horizontal.below.rectangle", touch 0)
                    plane(symbol "square.3.layers.3d.down.right", touch 0)
                    zero(symbol "drop", touch 0)
                    one(symbol "drop.fill", touch 0)
                }
                speed(image "icon.speed", touch 0) {
                    fps(symbol "speedometer", touch 0)
                    run(symbol "goforward", touch 0)
                }
            }
            brush(symbol "paintbrush.pointed", touch 0) {
                size(symbol "circle.circle", touch 0)
                press(image "icon.pen.press", touch 0)
                tilt(image "icon.pen.tilt", touch 0) //(symbol "angle", touch 0)
            }
            cell(symbol "circle.grid.3x3", touch 1000002) {
                fade(image "icon.cell.fade", touch 0)
                ave(image "icon.cell.ave", touch 0)
                melt(image "icon.cell.melt", touch 0)
                tunl(image "icon.cell.tunl", touch 0)
                zha(image "icon.cell.zha", touch 0)
                slide(image "icon.cell.slide", touch 0)
                fred(image "icon.cell.fred", touch 0)
            }
            cam(symbol "camera", touch 0) {
                snap(symbol "camera.shutter.button", touch 0)
                fake(symbol "face.dashed", touch 0)
                real(symbol "face.smiling", touch 0)
                face(symbol "arrow.triangle.2.circlepath.camera", touch 0)
                mix(symbol "slider.horizontal.below.rectangle", touch 0)
            }
        }
        model {
            canvas {
                tile {
                    mirror(x 0…1=0, y 0…1=0)<>shader.model.pipe.render.mirror
                    repeat(x -1…1=0.5, y -1…1=0.5)<>shader.model.pipe.render.repeat
                    shift(x 0…1=0.5, y 0…1=0.5)<>shader.model.pipe.draw
                    tilt(tog 0…1=0)<>sky.input.tilt
                }
                color {
                    fade(val 0…1=0)<>sky.color.xfade
                    plane(val 0…1=0)<>shader.model.pipe.color
                    zero(tap 0…1=0)>>sky.draw.screen.fill(0)
                    one(tap 0…1=0)>>sky.draw.screen.fill(1)
                }
                speed {
                    fps(seg 0…60=60)<>sky.main.fps
                    run(tog 0…1=1)<>sky.main.run
                }
            }
            brush {
                size(val 0…1=0.5)>>(sky.draw.brush.size, menu.SW.model.brush.press(0))
                press(tog 0…1=1)>>sky.draw.brush.press
                tilt(tog 0…1=1)<>sky.input.tilt
            }
            cell {
                fade(val 2…3=2.2)>>shader.model.cell.fade
                ave(val 0…1=0.5)>>shader.model.cell.ave
                melt(val 0…1=0.5)>>shader.model.cell.melt
                tunl(seg 0…5=1)>>shader.model.cell.tunl
                zha(seg 0…6=2)>>shader.model.cell.zha
                slide(seg 0…7=3)>>shader.model.cell.slide
                fred(seg 0…4=4)>>shader.model.cell.fred
            }
            cam {
                snap(tap 0…1=0)
                fake(tog 0…1=0)>>shader.model.pipe.camix.on
                real(tog 0…1=1)>>shader.model.pipe.camera.on
                face(tog 0…1=1)>>shader.model.pipe.camera.flip
                mix(val 0…1=0.5)>>shader.model.pipe.camix.mix
            }
        }
    }
    SE @SW { // copy southwest corner
        view(depth 0, touch 1000001) {
            canvas(symbol "photo.artframe", touch 0) {
                tile(image "icon.shader.tile.png", touch 0) {
                    mirror(symbol "arrowtriangle.left.and.line.vertical.and.arrowtriangle.right", touch 0)
                    repeat(symbol "rectangle.grid.2x2", touch 0)
                    shift(image "icon.cell.scroll", touch 0)
                    tilt(image "icon.pen.tilt", touch 0)
                }
                color(image "icon.pal.main", touch 0) {
                    fade(symbol "slider.horizontal.below.rectangle", touch 0)
                    plane(symbol "square.3.layers.3d.down.right", touch 0)
                    zero(symbol "drop", touch 0)
                    one(symbol "drop.fill", touch 0)
                }
                speed(image "icon.speed", touch 0) {
                    fps(symbol "speedometer", touch 0)
                    run(symbol "goforward", touch 0)
                }
            }
            brush(symbol "paintbrush.pointed", touch 0) {
                size(symbol "circle.circle", touch 0)
                press(image "icon.pen.press", touch 0)
                tilt(image "icon.pen.tilt", touch 0) //(symbol "angle", touch 0)
            }
            cell(symbol "circle.grid.3x3", touch 1000002) {
                fade(image "icon.cell.fade", touch 0)
                ave(image "icon.cell.ave", touch 0)
                melt(image "icon.cell.melt", touch 0)
                tunl(image "icon.cell.tunl", touch 0)
                zha(image "icon.cell.zha", touch 0)
                slide(image "icon.cell.slide", touch 0)
                fred(image "icon.cell.fred", touch 0)
            }
            cam(symbol "camera", touch 0) {
                snap(symbol "camera.shutter.button", touch 0)
                fake(symbol "face.dashed", touch 0)
                real(symbol "face.smiling", touch 0)
                face(symbol "arrow.triangle.2.circlepath.camera", touch 0)
                mix(symbol "slider.horizontal.below.rectangle", touch 0)
            }
        }
        model {
            canvas {
                tile {
                    mirror(x 0…1=0, y 0…1=0)<>shader.model.pipe.render.mirror
                    repeat(x -1…1=0.5, y -1…1=0.5)<>shader.model.pipe.render.repeat
                    shift(x 0…1=0.5, y 0…1=0.5)<>shader.model.pipe.draw
                    tilt(tog 0…1=0)<>sky.input.tilt
                }
                color {
                    fade(val 0…1=0)<>sky.color.xfade
                    plane(val 0…1=0)<>shader.model.pipe.color
                    zero(tap 0…1=0)>>sky.draw.screen.fill(0)
                    one(tap 0…1=0)>>sky.draw.screen.fill(1)
                }
                speed {
                    fps(seg 0…60=60)<>sky.main.fps
                    run(tog 0…1=1)<>sky.main.run
                }
            }
            brush {
                size(val 0…1=0.5)>>(sky.draw.brush.size, menu.SE.model.brush.press(0))
                press(tog 0…1=1)>>sky.draw.brush.press
                tilt(tog 0…1=1)<>sky.input.tilt
            }
            cell {
                fade(val 2…3=2.2)>>shader.model.cell.fade
                ave(val 0…1=0.5)>>shader.model.cell.ave
                melt(val 0…1=0.5)>>shader.model.cell.melt
                tunl(seg 0…5=1)>>shader.model.cell.tunl
                zha(seg 0…6=2)>>shader.model.cell.zha
                slide(seg 0…7=3)>>shader.model.cell.slide
                fred(seg 0…4=4)>>shader.model.cell.fred
            }
            cam {
                snap(tap 0…1=0)
                fake(tog 0…1=0)>>shader.model.pipe.camix.on
                real(tog 0…1=1)>>shader.model.pipe.camera.on
                face(tog 0…1=1)>>shader.model.pipe.camera.flip
                mix(val 0…1=0.5)>>shader.model.pipe.camix.mix
            }
        }
    }
}
midi { // musical instrument device interface
    input { // midi input
        note { // note on/off from 0 thru 127
            on(num 0…127, velo 0…127, chan 1…32, port 1…16, time)>>(midi.notes.dot, midi.output.note.on)
            off(num 0…127, velo 0…127, chan 1…32, port 1…16, time)>>(midi.input.note.on, midi.output.note.off)
        }
        controller(cc 0…127, val 0…127, chan 1…32, port 1…16, time)>>(midi.cc.skypad.plane, midi.cc.skypad.xfade, midi.cc.roli.lightpad.x, midi.cc.roli.lightpad.y, midi.cc.roli.lightpad.z, midi.cc.roli.loopblock.mode, midi.cc.roli.loopblock.mute, midi.cc.roli.loopblock.metro, midi.cc.roli.loopblock.skip, midi.cc.roli.loopblock.back, midi.cc.roli.loopblock.play, midi.cc.roli.loopblock.record, midi.cc.roli.loopblock.learn, midi.cc.roli.loopblock.prev, midi.cc.roli.loopblock.next)
        afterTouch(num 0…127, val 0…127, chan 1…32, port 1…16, time)
        pitchBend(val 0…16384=8192, chan 1…32, port 1…16, time)
        programChange(num 0…255, chan 1…32, port 1…16, time) //1, 632, 255
        nrpn(num 0…16383, val 0…1, chan, time)>>(midi.skypad.plane, midi.skypad.xfade)
    }
    output @input {
        note { // note on/off from 0 thru 127
            on(num 0…127, velo 0…127, chan 1…32, port 1…16, time)>>(midi.notes.dot, midi.output.note.on)
            off(num 0…127, velo 0…127, chan 1…32, port 1…16, time)>>(midi.input.note.on, midi.output.note.off)
        }
        controller(cc 0…127, val 0…127, chan 1…32, port 1…16, time)>>(midi.cc.skypad.plane, midi.cc.skypad.xfade, midi.cc.roli.lightpad.x, midi.cc.roli.lightpad.y, midi.cc.roli.lightpad.z, midi.cc.roli.loopblock.mode, midi.cc.roli.loopblock.mute, midi.cc.roli.loopblock.metro, midi.cc.roli.loopblock.skip, midi.cc.roli.loopblock.back, midi.cc.roli.loopblock.play, midi.cc.roli.loopblock.record, midi.cc.roli.loopblock.learn, midi.cc.roli.loopblock.prev, midi.cc.roli.loopblock.next)
        afterTouch(num 0…127, val 0…127, chan 1…32, port 1…16, time)
        pitchBend(val 0…16384=8192, chan 1…32, port 1…16, time)
        programChange(num 0…255, chan 1…32, port 1…16, time) //1, 632, 255
        nrpn(num 0…16383, val 0…1, chan, time)>>(midi.skypad.plane, midi.skypad.xfade)
    }
    skypad {
        plane(num == 129, val 0…1, chan, time)<>shader.model.pipe.color
        xfade(num == 130, val 0…1, chan, time)<>sky.color.xfade
    }
    cc {
        skypad {
            plane(cc == 11, val 0…127, chan, time)<>shader.model.pipe.color
            xfade(cc == 10, val 0…127, chan, time)<>sky.color.xfade
        }
        roli {
            lightpad {
                x(cc == 114, val 0…127, chan, time)
                y(cc == 113, val 0…127, chan, time)
                z(cc == 115, val 0…127, chan, time)
            }
            loopblock {
                mode(cc == 102, val 0…127, chan, time)
                mute(cc == 103, val 0…127, chan, time)
                metro(cc == 104, val 0…127, chan, time)
                skip(cc == 105, val 0…127, chan, time)
                back(cc == 106, val 0…127, chan, time)
                play(cc == 107, val 0…127, chan, time)
                record(cc == 108, val 0…127, chan, time)
                learn(cc == 109, val 0…127, chan, time)
                prev(cc == 110, val 0…127, chan, time)
                next(cc == 111, val 0…127, chan, time)
            }
        }
    }
    notes {
        dot(x : num % 12, y : num _/ 12, z : velo)>>sky.draw.dot
    }
    _cc {
        main {
            modWheel(num == 1, val, chan, time)
            volume(num == 7, val, chan, time)
            balance(num == 8, val, chan, time)
            panPosition(num == 10, val, chan, time)
            expression(num == 11, val, chan, time)
            controller(num in 32…63, val, chan, time) // controller 0…31
            portamento {
                time(num == 5, val, chan, time)
                amount(num == 84, val, chan, time)
            }
        }
        pedal {
            hold(num == 64, val, chan, time)
            porta(num == 65, val, chan, time)
            sosta(num == 66, val, chan, time)
            _soft(num == 67, val, chan, time)
            _legato(num == 68, val, chan, time)
            _hold2(num == 69, val, chan, time)
        }
        _cc {
            _main2 {
                bankSelect(num == 0, val, chan, time)
                breathCtrl(num == 2, val, chan, time)
                footPedal(num == 4, val, chan, time)
                dataEntry(num == 6, val, chan, time)
                effectControl1(num == 12, val, chan, time)
                effectControl2(num == 13, val, chan, time)
            }
            _sound {
                soundVariation(num == 70, val, chan, time)
                resonance(num == 71, val, chan, time)
                soundReleaseTime(num == 72, val, chan, time)
                soundAttackTime(num == 73, val, chan, time)
                frequencyCutoff(num == 74, val, chan, time)
                timbre(num == 71, val, chan, time)
                brightness(num == 74, val, chan, time)
            }
            _button {
                button1(num == 80, val, chan, time)
                button2(num == 81, val, chan, time)
                button3(num == 82, val, chan, time)
                button4(num == 83, val, chan, time)
                decayor(num == 80, val, chan, time)
                hiPassFilter(num == 81, val, chan, time)
                generalPurpose82(num == 82, val, chan, time)
                generalPurpose83(num == 83, val, chan, time)
            }
            _roland {
                rolandToneLevel1(num == 80, val, chan, time)
                rolandToneLevel2(num == 81, val, chan, time)
                rolandToneLevel3(num == 82, val, chan, time)
                rolandToneLevel4(num == 83, val, chan, time)
            }
            _level {
                reverbLevel(num == 91, val, chan, time)
                tremoloLevel(num == 92, val, chan, time)
                chorusLevel(num == 93, val, chan, time)
                detuneLevel(num == 94, val, chan, time)
                phaserLevel(num == 95, val, chan, time)
            }
            _parameter {
                dataButtonIncrement(num == 96, val, chan, time)
                dataButtonDecrement(num == 97, val, chan, time)
                nonregisteredParameterLSB(num == 98, val, chan, time)
                nonregisteredParameterMSB(num == 99, val, chan, time)
                registeredParameterLSB(num == 100, val, chan, time)
                registeredParameterMSB(num == 101, val, chan, time)
            }
            _soundControl {
                soundControl6(num == 75, val, chan, time)
                soundControl7(num == 76, val, chan, time)
                soundControl8(num == 77, val, chan, time)
                soundControl9(num == 78, val, chan, time)
                soundControl10(num == 79, val, chan, time)
            }
            _undefined {
                undefined_3(num == 3, val, chan, time)
                undefined_9(num == 9, val, chan, time)
                undefined_14_31(num in 14…31, val, chan, time)
                undefined_85_90(num in 85…90, val, chan, time)
                undefined_102_119(num in 102…119, val, chan, time)
            }
            _mode {
                allSoundOff(num == 120, val, chan, time)
                allControllersOff(num == 121, val, chan, time)
                localKeyboard(num == 122, val, chan, time)
                allNotesOff(num == 123, val, chan, time)
                monoOperation(num == 126, val, chan, time)
                polyMode(num == 127, val, chan, time)
            }
            _omni {
                omniModeOff(num == 124, val, chan, time)
                omniModeOn(num == 125, val, chan, time)
                omniMode(0…1)<<(midi._cc._cc._omni.omniModeOff(0), midi._cc._cc._omni.omniModeOn(1))
            }
        }
    }
}



scriptNow ⟹
sky {
    input {
        radius(1…92=9:17.618905)
        force(0…0.5:0.131811)
    }
    draw.brush.size(1…64=10:17.618905)
}
shader.model.cell {
    ave.on(0…1=1:0)
    melt.on(0…1=0:0.5)
}
menu.SW.view(depth 0, touch 1000001).cell(symbol "circle.grid.3x3", touch 1000002)


