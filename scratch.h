


scriptDef ⟹
sky { // visual music synth
    main { // main controls
        fps(1…60=60) // frames per second
        run( 1) // currently running
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
        radius(1…92=9:31.24) // finger silhouette
        tilt(0…1) // use tilt
        force(0…0.5:0.239394)>>sky.draw.brush.size // pen pressure
    }
    draw { // draw on metal layer
        screen { // fill 32 bit universe
            fill( 0) // all zeros 0x00000000
        }
        brush { // type of brush and range
            size(1…64=10:31.24) // range of radius
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
shader { model { cell { fade(0…1=0.5) { on(0…1=0)>>(shader.model.cell.fade.on( 0), shader.model.cell.ave.on( 0), shader.model.cell.melt.on( 0), shader.model.cell.tunl.on( 0), shader.model.cell.slide.on( 0), shader.model.cell.fred.on( 0), shader.model.cell.zha.on( 0))<<shader.model.cell.fade
}
    ave(0…1=0.5) { on(0…1=1)>>(shader.model.cell.fade.on( 0), shader.model.cell.ave.on( 0), shader.model.cell.melt.on( 0), shader.model.cell.tunl.on( 0), shader.model.cell.slide.on( 0), shader.model.cell.fred.on( 0), shader.model.cell.zha.on( 0))<<shader.model.cell.ave
    }
    melt(0…1=0.5) { on(0…1=0)>>(shader.model.cell.fade.on( 0), shader.model.cell.ave.on( 0), shader.model.cell.melt.on( 0), shader.model.cell.tunl.on( 0), shader.model.cell.slide.on( 0), shader.model.cell.fred.on( 0), shader.model.cell.zha.on( 0))<<shader.model.cell.melt
    }
    tunl(0…5=1) { on(0…1=0)>>(shader.model.cell.fade.on( 0), shader.model.cell.ave.on( 0), shader.model.cell.melt.on( 0), shader.model.cell.tunl.on( 0), shader.model.cell.slide.on( 0), shader.model.cell.fred.on( 0), shader.model.cell.zha.on( 0))<<shader.model.cell.tunl
    }
    slide(0…7=3) { on(0…1=0)>>(shader.model.cell.fade.on( 0), shader.model.cell.ave.on( 0), shader.model.cell.melt.on( 0), shader.model.cell.tunl.on( 0), shader.model.cell.slide.on( 0), shader.model.cell.fred.on( 0), shader.model.cell.zha.on( 0))<<shader.model.cell.slide
    }
    fred(0…4=4) { on(0…1=0)>>(shader.model.cell.fade.on( 0), shader.model.cell.ave.on( 0), shader.model.cell.melt.on( 0), shader.model.cell.tunl.on( 0), shader.model.cell.slide.on( 0), shader.model.cell.fred.on( 0), shader.model.cell.zha.on( 0))<<shader.model.cell.fred
    }
    zha(0…6=2) { on(0…1=0)>>(shader.model.cell.fade.on( 0), shader.model.cell.ave.on( 0), shader.model.cell.melt.on( 0), shader.model.cell.tunl.on( 0), shader.model.cell.slide.on( 0), shader.model.cell.fred.on( 0), shader.model.cell.zha.on( 0))<<shader.model.cell.zha
        bits(2…4=3)
        loops( 11)
    }
}
    pipe { draw(x 0…1=0.5, y 0…1=0.5) { on(0…1=0)
    }
        record { on(0…1=0)
        }
        camera { on(0…1=0)
            flip( 0)
        }
        camix { on(0…1=0)
            mix( 0)
        }
        color(0…1=0.1) // bitplane
        render { frame(x  0, y  0, w  1080, h  1920)
            repeat(x, y)
            mirror(x, y)
        }
    }
}
    file { cell { fade("cell.fader.metal")
        ave("cell.ave.metal")
        melt("cell.melt.metal")
        tunl("cell.tunl.metal")
        slide("cell.slide.metal")
        fred("cell.fred.metal")
        zha("cell.zha.metal")
    }
        pipe { record camera("cell.camera.metal")
            camix("cell.camix.metal")
            draw("pipe.draw.metal")
            render("pipe.render.metal")
            color("pipe.color.metal")
        }
    }
}
menu { view { canvas(symbol "photo.artframe") { tile(image "icon.shader.tile.png") { mirror(symbol "arrowtriangle.left.and.line.vertical.and.arrowtriangle.right")
    repeat(symbol "rectangle.grid.2x2")
    shift(image "icon.cell.scroll")
    tilt(image "icon.pen.tilt")
}
    color(image "icon.pal.main") { fade(symbol "slider.horizontal.below.rectangle")
        plane(symbol "square.3.layers.3d.down.right")
        zero(symbol "drop")
        one(symbol "drop.fill")
    }
    speed(image "icon.speed") { fps(symbol "speedometer")
        run(symbol "goforward")
    }
}
    brush(symbol "paintbrush.pointed") { size(symbol "circle.circle")
        press(image "icon.pen.press")
        tilt(image "icon.pen.tilt") //(symbol "angle")
    }
    cell(symbol "circle.grid.3x3") { fade(image "icon.cell.fade")
        ave(image "icon.cell.ave")
        melt(image "icon.cell.melt")
        tunl(image "icon.cell.tunl")
        zha(image "icon.cell.zha")
        slide(image "icon.cell.slide")
        fred(image "icon.cell.fred")
    }
    cam(symbol "camera") { snap(symbol "camera.shutter.button")
        fake(symbol "face.dashed")
        real(symbol "face.smiling")
        face(symbol "arrow.triangle.2.circlepath.camera")
        mix(symbol "slider.horizontal.below.rectangle")
    }
}
    model { canvas { tile { mirror(x 0…1=0, y 0…1=0)>>shader.model.pipe.render.mirror
        repeat(x -1…1=0.5, y -1…1=0.5)>>shader.model.pipe.render.repeat
        shift(x 0…1=0.5, y 0…1=0.5)<>shader.model.pipe.draw
        tilt(tog 0…1=0)<>sky.input.tilt
    }
        color { fade(val 0…1=0)<>sky.color.xfade
            plane(val 0…1=0)<>shader.model.pipe.color
            zero(tap 0…1=0)>>sky.draw.screen.fill( 0)
            one(tap 0…1=0)>>sky.draw.screen.fill( 1)
        }
        speed { fps(seg 0…60=60)>>sky.main.fps
            run(tog 0…1=1)>>sky.main.run
        }
    }
        brush { size(val 0…1=0.5)>>(sky.draw.brush.size, menu.model.brush.press( 0))
            press(tog 0…1=1)>>sky.draw.brush.press
            tilt(tog 0…1=1)<>sky.input.tilt
        }
        cell { fade(val 2…3=2.2)>>shader.model.cell.fade
            ave(val 0…1=0.5)>>shader.model.cell.ave
            melt(val 0…1=0.5)>>shader.model.cell.melt
            tunl(seg 0…5=1)>>shader.model.cell.tunl
            zha(seg 0…6=2)>>shader.model.cell.zha
            slide(seg 0…7=3)>>shader.model.cell.slide
            fred(seg 0…4=4)>>shader.model.cell.fred
        }
        cam { snap(tap 0…1=0)
            fake(tog 0…1=0)>>shader.model.pipe.camix.on
            real(tog 0…1=1)>>shader.model.pipe.camera.on
            face(tog 0…1=1)>>shader.model.pipe.camera.flip
            mix(val 0…1=0.5)>>shader.model.pipe.camix.mix
        }
    }
}
midi { // musical instrument device interface
    input { // midi input
        note { // note on/off from 0 thru 127
            on(num 0…127, velo 0…127, chan 1…32, port 1…16, time  0)>>(midi.notes.dot, midi.output.note.on)
            off(num 0…127, velo 0…127, chan 1…32, port 1…16, time  0)>>(midi.input.note.on, midi.output.note.off)
        }
        controller(cc 0…127, val 0…127, chan 1…32, port 1…16, time  0)>>(midi.cc.skypad.plane, midi.cc.skypad.xfade, midi.cc.roli.lightpad.x, midi.cc.roli.lightpad.y, midi.cc.roli.lightpad.z, midi.cc.roli.loopblock.mode, midi.cc.roli.loopblock.mute, midi.cc.roli.loopblock.metro, midi.cc.roli.loopblock.skip, midi.cc.roli.loopblock.back, midi.cc.roli.loopblock.play, midi.cc.roli.loopblock.record, midi.cc.roli.loopblock.learn, midi.cc.roli.loopblock.prev, midi.cc.roli.loopblock.next)
        afterTouch(num 0…127, val 0…127, chan 1…32, port 1…16, time  0)
        pitchBend(val 0…16384=8192, chan 1…32, port 1…16, time  0)
        programChange(num 0…255, chan 1…32, port 1…16, time  0) //1, 632, 255
        nrpn(num 0…16383, val 0…1, chan, time)>>(midi.skypad.plane, midi.skypad.xfade)
    }
    output @input { note { // note on/off from 0 thru 127
        on(num 0…127, velo 0…127, chan 1…32, port 1…16, time  0)>>(midi.notes.dot, midi.output.note.on)
        off(num 0…127, velo 0…127, chan 1…32, port 1…16, time  0)>>(midi.input.note.on, midi.output.note.off)
    }
        controller(cc 0…127, val 0…127, chan 1…32, port 1…16, time  0)>>(midi.cc.skypad.plane, midi.cc.skypad.xfade, midi.cc.roli.lightpad.x, midi.cc.roli.lightpad.y, midi.cc.roli.lightpad.z, midi.cc.roli.loopblock.mode, midi.cc.roli.loopblock.mute, midi.cc.roli.loopblock.metro, midi.cc.roli.loopblock.skip, midi.cc.roli.loopblock.back, midi.cc.roli.loopblock.play, midi.cc.roli.loopblock.record, midi.cc.roli.loopblock.learn, midi.cc.roli.loopblock.prev, midi.cc.roli.loopblock.next)
        afterTouch(num 0…127, val 0…127, chan 1…32, port 1…16, time  0)
        pitchBend(val 0…16384=8192, chan 1…255, chan 1…32, port 1…16, time  0) //1, 632, 255
        nrpn(num 0…16383, val 0…1, chan, time)>>(midi.skypad.plane, midi.skypad.xfade)
    }
    output @input { note { // note on/off from 0 thru 127
        on(num 0…127, velo 0…127, chan 1…32, port 1…16, time  0)>>(midi.notes.dot, midi.output.note.on)
        off(num 0…127, velo 0…127, chan 1…32, port 1…16, time  0)>>(midi.input.note.on, midi.output.note.off)
    }
        controller(cc 0…127, val 0…127, chan 1…32, port 1…16, time  0)>>(midi.cc.skypad.plane, midi.cc.skypad.xfade, midi.cc.roli.lightpad.x, midi.cc.roli.lightpad.y, midi.cc.roli.lightpad.z, midi.cc.roli.loopblock.mode, midi.cc.roli.loopblock.mute, midi.cc.roli.loopblock.metro, midi.cc.roli.loopblock.skip, midi.cc.roli.loopblock.back, midi.cc.roli.loopblock.play, midi.cc.roli.loopblock.record, midi.cc.roli.loopblock.learn, midi.cc.roli.loopblock.prev, midi.cc.roli.loopblock.next)
        afterTouch(num 0…127, val 0…127, chan 1…32, port 1…16, time  0)
        pitchBend(val 0…16384=8192, chan 1\342\200…32, port 1…16, time  0)
        programChange(num 0…255, chan 1…32, port 1…16, time  0) //1, 632, 255
        nrpn(num 0…16383, val 0…1, chan, time)>>(midi.skypad.plane, midi.skypad.xfade)
    }
    skypad { plane(num ==  129, val 0…1, chan, time)<>menu.model.canvas.color.plane
        xfade(num ==  130, val 0…1, chan, time)<>sky.color.xfade
    }
    cc { skypad { plane(cc ==  11, val 0…127, chan, ma time)<>menu.model.canvas.color.plane
        xfade(cc ==  10, val 0…127, chan, time)<>sky.color.xfade
    }
        roli { lightpad { x(cc ==  114, val 0…127, chan, time)
            y(cc ==  113, val 0…127, chan, time)
            z(cc ==  115, val 0…127, chan, time)
        }
            loopblock { mode(cc ==  102, val 0…127, chan, time)
                mute(cc ==  103, val 0…127, chan, time)
                metro(cc ==  104, val 0…127, chan, time)
                skip(cc ==  105, val 0…127, chan, time)
                back(cc ==  106, val 0…127, chan, time)
                play(cc ==  107, val 0…127, chan, time)
                record(cc ==  108, val 0…127, chan, time)
                learn(cc ==  109, val 0…127, chan, time)
                prev(cc ==  110, val 0…127, chan, time)
                next(cc ==  111, val 0…127, chan, time)
            }
        }
    }
    notes { dot(x : num %  12, y : num _/  12, z : velo)>>sky.draw.dot
    }
    _cc { main { modWheel(num ==  1, val, chan, time)
        volume(num ==  7, val, chan, time)
        balance(num ==  8, val, chan, time)
        panPosition(num ==  10, val, chan, time)
        expression(num ==  11, val, chan, time)
        controller(num in 32…63, val, chan, time) // controller 0…31
        portamento { time(num ==  5, val, chan, time)
            amount(num ==  84, val, chan, time)
        }
    }
        pedal { hold(num ==  64, val, chan, time)
            porta(num ==  65, val, chan, time)
            sosta(num ==  66, val, chan, time)
            _soft(num ==  67, val, chan, time)
            _legato(num ==  68, val, chan, time)
            _hold2(num ==  69, val, chan, time)
        }
        _cc { _main2 { bankSelect(num ==  0, val, chan, time)
            breathCtrl(num ==  2, val, chan, time)
            footPedal(num ==  4, val, chan, time)
            dataEntry(num ==  6, val, chan, time)
            effectControl1(num ==  12, val, chan, time)
            effectControl2(num ==  13, val, chan, time)
        }
            _sound { soundVariation(num ==  70, val, chan, time)
                resonance(num ==  71, val, chan, time)
                soundReleaseTime(num ==  72, val, chan, time)
                soundAttackTime(num ==  73, val, chan, time)
                frequencyCutoff(num ==  74, val, chan, time)
                timbre(num ==  71, val, chan, time)
                brightness(num ==  74, val, chan, time)
            }
            _button { button1(num ==  80, val, chan, time)
                button2(num ==  81, val, chan, time)
                button3(num ==  82, val, chan, time)
                button4(num ==  83, val, chan, time)
                decayor(num ==  80, val, chan, time)
                hiPassFilter(num ==  81, val, chan, time)
                generalPurpose82(num ==  82, val, chan, time)
                generalPurpose83(num ==  83, val, chan, time)
            }
            _roland { rolandToneLevel1(num ==  80, val, chan, time)
                rolandToneLevel2(num ==  81, val, chan, time)
                rolandToneLevel3(num ==  82, val, chan, time)
                rolandToneLevel4(num ==  83, val, chan, time)
            }
            _level { reverbLevel(num ==  91, val, chan, time)
                tremoloLevel(num ==  92, val, chan, time)
                chorusLevel(num ==  93, val, chan, time)
                detuneLevel(num ==  94, val, chan, time)
                phaserLevel(num ==  95, val, chan, time)
            }
            _parameter { dataButtonIncrement(num ==  96, val, chan, time)
                dataButtonDecrement(num ==  97, val, chan, time)
                nonregisteredParameterLSB(num ==  98, val, chan, time)
                nonregisteredParameterMSB(num ==  99, val, chan, time)
                registeredParameterLSB(num ==  100, val, chan, time)
                registeredParameterMSB(num ==  101, val, chan, time)
            }
            _soundControl { soundControl6(num ==  75, val, chan, time)
                soundControl7(num ==  76, val, chan, time)
                soundControl8(num ==  77, val, chan, time)
                soundControl9(num ==  78, val, chan, time)
                soundControl10(num ==  79, val, chan, time)
            }
            _undefined { undefined_3(num ==  3, val, chan, time)
                undefined_9(num ==  9, val, chan, time)
                undefined_14_31(num in 14…31, val, chan, time)
                undefined_85_90(num in 85…90, val, chan, time)
                undefined_102_119(num in 102…119, val, chan, time)
            }
            _mode { allSoundOff(num ==  120, val, chan, time)
                allControllersOff(num ==  121, val, chan, time)
                localKeyboard(num ==  122, val, chan, time)
                allNotesOff(num ==  123, val, chan, time)
                monoOperation(num ==  126, val, chan, time)
                polyMode(num ==  127, val, chan, time)
            }
            _omni { omniModeOff(num ==  124, val, chan, time)
                omniModeOn(num ==  125, val, chan, time)
                omniMode(0…1)<<(midi._cc._cc._omni.omniModeOff( 0), midi._cc._cc._omni.omniModeOn( 1))
            }
        }
    }
}



scriptNow ⟹
sky { // visual music synth
    main { // main controls
        fps // frames per second
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
        xfade(val)
    }
    input { // phone and tablet pencil input

        azimuth(x, y)>>shader.model.pipe.draw
        accel(x, y, z) { // accelerometer
            on }
        radius(31.24) // finger silhouette
        tilt // use tilt
        force(0.239394)>>sky.draw.brush.size // pen pressure
    }
    draw { // draw on metal layer
        screen { // fill 32 bit universe
            fill(0) // all zeros 0x00000000
        }
        brush { // type of brush and range
            size(31.24) // range of radius
            press // pressure changes size
            index // index in 256 color palette
                  // <<(osc.tuio.z osc.manos˚z) // redirect from OSC
        }
        line { // place holder for line drawing
            prev(x, y) // staring point of segment
            next(x, y) // endint point of segment
        }
        dot(x, y, z)
    }
}
shader { model { cell { fade { on>>(shader.model.cell.fade.on(0), shader.model.cell.ave.on(0), shader.model.cell.melt.on(0), shader.model.cell.tunl.on(0), shader.model.cell.slide.on(0), shader.model.cell.fred.on(0), shader.model.cell.zha.on(0))<<shader.model.cell.fade }
    ave { on>>(shader.model.cell.fade.on(0), shader.model.cell.ave.on(0), shader.model.cell.melt.on(0), shader.model.cell.tunl.on(0), shader.model.cell.slide.on(0), shader.model.cell.fred.on(0), shader.model.cell.zha.on(0))<<shader.model.cell.ave }
    melt { on>>(shader.model.cell.fade.on(0), shader.model.cell.ave.on(0), shader.model.cell.melt.on(0), shader.model.cell.tunl.on(0), shader.model.cell.slide.on(0), shader.model.cell.fred.on(0), shader.model.cell.zha.on(0))<<shader.model.cell.melt }
    tunl { on>>(shader.model.cell.fade.on(0), shader.model.cell.ave.on(0), shader.model.cell.melt.on(0), shader.model.cell.tunl.on(0), shader.model.cell.slide.on(0), shader.model.cell.fred.on(0), shader.model.cell.zha.on(0))<<shader.model.cell.tunl }
    slide { on>>(shader.model.cell.fade.on(0), shader.model.cell.ave.on(0), shader.model.cell.melt.on(0), shader.model.cell.tunl.on(0), shader.model.cell.slide.on(0), shader.model.cell.fred.on(0), shader.model.cell.zha.on(0))<<shader.model.cell.slide }
    fred { on>>(shader.model.cell.fade.on(0), shader.model.cell.ave.on(0), shader.model.cell.melt.on(0), shader.model.cell.tunl.on(0), shader.model.cell.slide.on(0), shader.model.cell.fred.on(0), shader.model.cell.zha.on(0))<<shader.model.cell.fred }
    zha { on>>(shader.model.cell.fade.on(0), shader.model.cell.ave.on(0), shader.model.cell.melt.on(0), shader.model.cell.tunl.on(0), shader.model.cell.slide.on(0), shader.model.cell.fred.on(0), shader.model.cell.zha.on(0))<<shader.model.cell.zha bits loops(11)
    }
}
    pipe { draw(x, y) { on }
        record { on }
        camera { on flip(0)
        }
        camix { on mix(0)
        }
        color // bitplane
        render { frame(x 0, y 0, w 1080, h 1920)
            repeat(x, y)
            mirror(x, y)
        }
    }
}
    file { cell { fade("cell.fader.metal")
        ave("cell.ave.metal")
        melt("cell.melt.metal")
        tunl("cell.tunl.metal")
        slide("cell.slide.metal")
        fred("cell.fred.metal")
        zha("cell.zha.metal")
    }
        pipe { record camera("cell.camera.metal")
            camix("cell.camix.metal")
            draw("pipe.draw.metal")
            render("pipe.render.metal")
            color("pipe.color.metal")
        }
    }
}
menu { view { canvas(symbol "photo.artframe") { tile(image "icon.shader.tile.png") { mirror(symbol "arrowtriangle.left.and.line.vertical.and.arrowtriangle.right")
    repeat(symbol "rectangle.grid.2x2")
    shift(image "icon.cell.scroll")
    tilt(image "icon.pen.tilt")
}
    color(image "icon.pal.main") { fade(symbol "slider.horizontal.below.rectangle")
        plane(symbol "square.3.layers.3d.down.right")
        zero(symbol "drop")
        one(symbol "drop.fill")
    }
    speed(image "icon.speed") { fps(symbol "speedometer")
        run(symbol "goforward")
    }
}
    brush(symbol "paintbrush.pointed") { size(symbol "circle.circle")
        press(image "icon.pen.press")
        tilt(image "icon.pen.tilt") //(symbol "angle")
    }
    cell(symbol "circle.grid.3x3") { fade(image "icon.cell.fade")
        ave(image "icon.cell.ave")
        melt(image "icon.cell.melt")
        tunl(image "icon.cell.tunl")
        zha(image "icon.cell.zha")
        slide(image "icon.cell.slide")
        fred(image "icon.cell.fred")
    }
    cam(symbol "camera") { snap(symbol "camera.shutter.button")
        fake(symbol "face.dashed")
        real(symbol "face.smiling")
        face(symbol "arrow.triangle.2.circlepath.camera")
        mix(symbol "slider.horizontal.below.rectangle")
    }
}
    model { canvas { tile { mirror(x, y)>>shader.model.pipe.render.mirror
        repeat(x, y)>>shader.model.pipe.render.repeat
        shift(x, y)<>shader.model.pipe.draw
        tilt(tog)<>sky.input.tilt
    }
        color { fade(val)<>sky.color.xfade
            plane(val)<>shader.model.pipe.color
            zero(tap)>>sky.draw.screen.fill(0)
            one(tap)>>sky.draw.screen.fill(1)
        }
        speed { fps(seg)>>sky.main.fps
            run(tog)>>sky.main.run
        }
    }
        brush { size(val)>>(sky.draw.brush.size, menu.model.brush.press(0))
            press(tog)>>sky.draw.brush.press
            tilt(tog)<>sky.input.tilt
        }
        cell { fade(val)>>shader.model.cell.fade
            ave(val)>>shader.model.cell.ave
            melt(val)>>shader.model.cell.melt
            tunl(seg)>>shader.model.cell.tunl
            zha(seg)>>shader.model.cell.zha
            slide(seg)>>shader.model.cell.slide
            fred(seg)>>shader.model.cell.fred
        }
        cam { snap(tap)
            fake(tog)>>shader.model.pipe.camix.on
            real(tog)>>shader.model.pipe.camera.on
            face(tog)>>shader.model.pipe.camera.flip
            mix(val)>>shader.model.pipe.camix.mix
        }
    }
}
midi { // musical instrument device interface
    input { // midi input
        note { // note on/off from 0 thru 127
            on(num, velo, chan, port, time 0)>>(midi.notes.dot, midi.output.note.on)
            off(num, velo, chan, port, time 0)>>(midi.input.note.on, midi.output.note.off)
        }
        controller(cc, val, chan, port, time 0)>>(midi.cc.skypad.plane, midi.cc.skypad.xfade, midi.cc.roli.lightpad.x, midi.cc.roli.lightpad.y, midi.cc.roli.lightpad.z, midi.cc.roli.loopblock.mode, midi.cc.roli.loopblock.mute, midi.cc.roli.loopblock.metro, midi.cc.roli.loopblock.skip, midi.cc.roli.loopblock.back, midi.cc.roli.loopblock.play, midi.cc.roli.loopblock.record, midi.cc.roli.loopblock.learn, midi.cc.roli.loopblock.prev, midi.cc.roli.loopblock.next)
        afterTouch(num, val, chan, port, time 0)
        pitchBend(val, chan, port, time 0)
        programChange(num, chan, port, time 0) //1, 632, 255
        nrpn(num, val, chan, time)>>(midi.skypad.plane, midi.skypad.xfade)
    }
    output @input { note { // note on/off from 0 thru 127
        on(num, velo, chan, port, time 0)>>(midi.notes.dot, midi.output.note.on)
        off(num, velo, chan, port, time 0)>>(midi.input.note.on, midi.output.note.off)
    }
        controller(cc, val, chan, port, time 0)>>(midi.cc.skypad.plane, midi.cc.skypad.xfade, midi.cc.roli.lightpad.x, midi.cc.roli.lightpad.y, midi.cc.roli.lightpad.z, midi.cc.roli.loopblock.mode, midi.cc.roli.loopblock.mute, midi.cc.roli.loopblock.metro, midi.cc.roli.loopblock.skip, midi.cc.roli.loopblock.back, midi.cc.roli.loopblock.play, midi.cc.roli.loopblock.record, midi.cc.roli.loopblock.learn, midi.cc.roli.loopblock.prev, midi.cc.roli.loopblock.next)
        afterTouch(num, val, chan, port, time 0)
        pitchBend(val, chan, port, time 0)
        programChange(num, chan, port, time 0) //1, 632, 255
        nrpn(num, val, chan, time)>>(midi.skypad.plane, midi.skypad.xfade)
    }
    skypad { plane(num, val, chan, time)<>menu.model.canvas.color.plane
        xfade(num, val, chan, time)<>sky.color.xfade
    }
    cc { skypad { plane(cc, val, chan, ma time)<>menu.model.canvas.color.plane
        xfade(cc, val, chan, time)<>sky.color.xfade
    }
        roli { lightpad { x(cc, val, chan, time)
            y(cc, val, chan, time)
            z(cc, val, chan, time)
        }
            loopblock { mode(cc, val, chan, time)
                mute(cc, val, chan, time)
                metro(cc, val, chan, time)
                skip(cc, val, chan, time)
                back(cc, val, chan, time)
                play(cc, val, chan, time)
                record(cc, val, chan, time)
                learn(cc, val, chan, time)
                prev(cc, val, chan, time)
                next(cc, val, chan, time)
            }
        }
    }
    notes { dot(x, y, z)>>sky.draw.dot
    }
    _cc { main { modWheel(num, val, chan, time)
        volume(num, val, chan, time)
        balance(num, val, chan, time)
        panPosition(num, val, chan, time)
        expression(num, val, chan, time)
        controller(num, val, chan, time) // controller 0…31
        portamento { time(num, val, chan, time)
            amount(num, val, chan, time)
        }
    }
        pedal { hold(num, val, chan, time)
            porta(num, val, chan, time)
            sosta(num, val, chan, time)
            _soft(num, val, chan, time)
            _legato(num, val, chan, time)
            _hold2(num, val, chan, time)
        }
        _cc { _main2 { bankSelect(num, val, chan, time)
            breathCtrl(num, val, chan, time)
            footPedal(num, val, chan, time)
            dataEntry(num, val, chan, time)
            effectControl1(num, val, chan, time)
            effectControl2(num, val, chan, time)
        }
            _sound { soundVariation(num, val, chan, time)
                resonance(num, val, chan, time)
                soundReleaseTime(num, val, chan, time)
                soundAttackTime(num, val, chan, time)
                frequencyCutoff(num, val, chan, time)
                timbre(num, val, chan, time)
                brightness(num, val, chan, time)
            }
            _button { button1(num, val, chan, time)
                button2(num, val, chan, time)
                button3(num, val, chan, time)
                button4(num, val, chan, time)
                decayor(num, val, chan, time)
                hiPassFilter(num, val, chan, time)
                generalPurpose82(num, val, chan, time)
                generalPurpose83(num, val, chan, time)
            }
            _roland { rolandToneLevel1(num, val, chan, time)
                rolandToneLevel2(num, val, chan, time)
                rolandToneLevel3(num, val, chan, time)
                rolandToneLevel4(num, val, chan, time)
            }
            _level { reverbLevel(num, val, chan, time)
                tremoloLevel(num, val, chan, time)
                chorusLevel(num, val, chan, time)
                detuneLevel(num, val, chan, time)
                phaserLevel(num, val, chan, time)
            }
            _parameter { dataButtonIncrement(num, val, chan, time)
                dataButtonDecrement(num, val, chan, time)
                nonregisteredParameterLSB(num, val, chan, time)
                nonregisteredParameterMSB(num, val, chan, time)
                registeredParameterLSB(num, val, chan, time)
                registeredParameterMSB(num, val, chan, time)
            }
            _soundControl { soundControl6(num, val, chan, time)
                soundControl7(num, val, chan, time)
                soundControl8(num, val, chan, time)
                soundControl9(num, val, chan, time)
                soundControl10(num, val, chan, time)
            }
            _undefined { undefined_3(num, val, chan, time)
                undefined_9(num, val, chan, time)
                undefined_14_31(num, val, chan, time)
                undefined_85_90(num, val, chan, time)
                undefined_102_119(num, val, chan, time)
            }
            _mode { allSoundOff(num, val, chan, time)
                allControllersOff(num, val, chan, time)
                localKeyboard(num, val, chan, time)
                allNotesOff(num, val, chan, time)
                monoOperation(num, val, chan, time)
                polyMode(num, val, chan, time)
            }
            _omni { omniModeOff(num, val, chan, time)
                omniModeOn(num, val, chan, time)
                omniMode<<(midi._cc._cc._omni.omniModeOff(0), midi._cc._cc._omni.omniModeOn(1)) }
        }
    }
}






scriptDef ⟹
sky { // visual music synth
    main { // main controls
        fps(1…60=60) // frames per second
        run( 1) // currently running
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
        radius(1…92=9:31.24) // finger silhouette
        tilt(0…1) // use tilt
        force(0…0.5:0.239394)>>sky.draw.brush.size // pen pressure
    }
    draw { // draw on metal layer
        screen { // fill 32 bit universe
            fill( 0) // all zeros 0x00000000
        }
        brush { // type of brush and range
            size(1…64=10:31.24) // range of radius
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
shader { model { cell { fade(0…1=0.5) { on(0…1=0)>>(shader.model.cell.fade.on( 0), shader.model.cell.ave.on( 0), shader.model.cell.melt.on( 0), shader.model.cell.tunl.on( 0), shader.model.cell.slide.on( 0), shader.model.cell.fred.on( 0), shader.model.cell.zha.on( 0))<<shader.model.cell.fade
}
    ave(0…1=0.5) { on(0…1=1)>>(shader.model.cell.fade.on( 0), shader.model.cell.ave.on( 0), shader.model.cell.melt.on( 0), shader.model.cell.tunl.on( 0), shader.model.cell.slide.on( 0), shader.model.cell.fred.on( 0), shader.model.cell.zha.on( 0))<<shader.model.cell.ave
    }
    melt(0…1=0.5) { on(0…1=0)>>(shader.model.cell.fade.on( 0), shader.model.cell.ave.on( 0), shader.model.cell.melt.on( 0), shader.model.cell.tunl.on( 0), shader.model.cell.slide.on( 0), shader.model.cell.fred.on( 0), shader.model.cell.zha.on( 0))<<shader.model.cell.melt
    }
    tunl(0…5=1) { on(0…1=0)>>(shader.model.cell.fade.on( 0), shader.model.cell.ave.on( 0), shader.model.cell.melt.on( 0), shader.model.cell.tunl.on( 0), shader.model.cell.slide.on( 0), shader.model.cell.fred.on( 0), shader.model.cell.zha.on( 0))<<shader.model.cell.tunl
    }
    slide(0…7=3) { on(0…1=0)>>(shader.model.cell.fade.on( 0), shader.model.cell.ave.on( 0), shader.model.cell.melt.on( 0), shader.model.cell.tunl.on( 0), shader.model.cell.slide.on( 0), shader.model.cell.fred.on( 0), shader.model.cell.zha.on( 0))<<shader.model.cell.slide
    }
    fred(0…4=4) { on(0…1=0)>>(shader.model.cell.fade.on( 0), shader.model.cell.ave.on( 0), shader.model.cell.melt.on( 0), shader.model.cell.tunl.on( 0), shader.model.cell.slide.on( 0), shader.model.cell.fred.on( 0), shader.model.cell.zha.on( 0))<<shader.model.cell.fred
    }
    zha(0…6=2) { on(0…1=0)>>(shader.model.cell.fade.on( 0), shader.model.cell.ave.on( 0), shader.model.cell.melt.on( 0), shader.model.cell.tunl.on( 0), shader.model.cell.slide.on( 0), shader.model.cell.fred.on( 0), shader.model.cell.zha.on( 0))<<shader.model.cell.zha
        bits(2…4=3)
        loops( 11)
    }
}
    pipe { draw(x 0…1=0.5, y 0…1=0.5) { on(0…1=0)
    }
        record { on(0…1=0)
        }
        camera { on(0…1=0)
            flip( 0)
        }
        camix { on(0…1=0)
            mix( 0)
        }
        color(0…1=0.1) // bitplane
        render { frame(x  0, y  0, w  1080, h  1920)
            repeat(x, y)
            mirror(x, y)
        }
    }
}
    file { cell { fade("cell.fader.metal")
        ave("cell.ave.metal")
        melt("cell.melt.metal")
        tunl("cell.tunl.metal")
        slide("cell.slide.metal")
        fred("cell.fred.metal")
        zha("cell.zha.metal")
    }
        pipe { record camera("cell.camera.metal")
            camix("cell.camix.metal")
            draw("pipe.draw.metal")
            render("pipe.render.metal")
            color("pipe.color.metal")
        }
    }
}
menu { view { canvas(symbol "photo.artframe") { tile(image "icon.shader.tile.png") { mirror(symbol "arrowtriangle.left.and.line.vertical.and.arrowtriangle.right")
    repeat(symbol "rectangle.grid.2x2")
    shift(image "icon.cell.scroll")
    tilt(image "icon.pen.tilt")
}
    color(image "icon.pal.main") { fade(symbol "slider.horizontal.below.rectangle")
        plane(symbol "square.3.layers.3d.down.right")
        zero(symbol "drop")
        one(symbol "drop.fill")
    }
    speed(image "icon.speed") { fps(symbol "speedometer")
        run(symbol "goforward")
    }
}
    brush(symbol "paintbrush.pointed") { size(symbol "circle.circle")
        press(image "icon.pen.press")
        tilt(image "icon.pen.tilt") //(symbol "angle")
    }
    cell(symbol "circle.grid.3x3") { fade(image "icon.cell.fade")
        ave(image "icon.cell.ave")
        melt(image "icon.cell.melt")
        tunl(image "icon.cell.tunl")
        zha(image "icon.cell.zha")
        slide(image "icon.cell.slide")
        fred(image "icon.cell.fred")
    }
    cam(symbol "camera") { snap(symbol "camera.shutter.button")
        fake(symbol "face.dashed")
        real(symbol "face.smiling")
        face(symbol "arrow.triangle.2.circlepath.camera")
        mix(symbol "slider.horizontal.below.rectangle")
    }
}
    model { canvas { tile { mirror(x 0…1=0, y 0…1=0)>>shader.model.pipe.render.mirror
        repeat(x -1…1=0.5, y -1…1=0.5)>>shader.model.pipe.render.repeat
        shift(x 0…1=0.5, y 0…1=0.5)<>shader.model.pipe.draw
        tilt(tog 0…1=0)<>sky.input.tilt
    }
        color { fade(val 0…1=0)<>sky.color.xfade
            plane(val 0…1=0)<>shader.model.pipe.color
            zero(tap 0…1=0)>>sky.draw.screen.fill( 0)
            one(tap 0…1=0)>>sky.draw.screen.fill( 1)
        }
        speed { fps(seg 0…60=60)>>sky.main.fps
            run(tog 0…1=1)>>sky.main.run
        }
    }
        brush { size(val 0…1=0.5)>>(sky.draw.brush.size, menu.model.brush.press( 0))
            press(tog 0…1=1)>>sky.draw.brush.press
            tilt(tog 0…1=1)<>sky.input.tilt
        }
        cell { fade(val 2…3=2.2)>>shader.model.cell.fade
            ave(val 0…1=0.5)>>shader.model.cell.ave
            melt(val 0…1=0.5)>>shader.model.cell.melt
            tunl(seg 0…5=1)>>shader.model.cell.tunl
            zha(seg 0…6=2)>>shader.model.cell.zha
            slide(seg 0…7=3)>>shader.model.cell.slide
            fred(seg 0…4=4)>>shader.model.cell.fred
        }
        cam { snap(tap 0…1=0)
            fake(tog 0…1=0)>>shader.model.pipe.camix.on
            real(tog 0…1=1)>>shader.model.pipe.camera.on
            face(tog 0…1=1)>>shader.model.pipe.camera.flip
            mix(val 0…1=0.5)>>shader.model.pipe.camix.mix
        }
    }
}
midi { // musical instrument device interface
    input { // midi input
        note { // note on/off from 0 thru 127
            on(num 0…127, velo 0…127, chan 1…32, port 1…16, time  0)>>(midi.notes.dot, midi.output.note.on)
            off(num 0…127, velo 0…127, chan 1…32, port 1…16, time  0)>>(midi.input.note.on, midi.output.note.off)
        }
        controller(cc 0…127, val 0…127, chan 1…32, port 1…16, time  0)>>(midi.cc.skypad.plane, midi.cc.skypad.xfade, midi.cc.roli.lightpad.x, midi.cc.roli.lightpad.y, midi.cc.roli.lightpad.z, midi.cc.roli.loopblock.mode, midi.cc.roli.loopblock.mute, midi.cc.roli.loopblock.metro, midi.cc.roli.loopblock.skip, midi.cc.roli.loopblock.back, midi.cc.roli.loopblock.play, midi.cc.roli.loopblock.record, midi.cc.roli.loopblock.learn, midi.cc.roli.loopblock.prev, midi.cc.roli.loopblock.next)
        afterTouch(num 0…127, val 0…127, chan 1…32, port 1…16, time  0)
        pitchBend(val 0…16384=8192, chan 1…32, port 1…16, time  0)
        programChange(num 0…255, chan 1…32, port 1…16, time  0) //1, 632, 255
        nrpn(num 0…16383, val 0…1, chan, time)>>(midi.skypad.plane, midi.skypad.xfade)
    }
    output @input { note { // note on/off from 0 thru 127
        on(num 0…127, velo 0…127, chan 1…32, port 1…16, time  0)>>(midi.notes.dot, midi.output.note.on)
        off(num 0…127, velo 0…127, chan 1…32, port 1…16, time  0)>>(midi.input.note.on, midi.output.note.off)
    }
        controller(cc 0…127, val 0…127, chan 1…32, port 1…16, time  0)>>(midi.cc.skypad.plane, midi.cc.skypad.xfade, midi.cc.roli.lightpad.x, midi.cc.roli.lightpad.y, midi.cc.roli.lightpad.z, midi.cc.roli.loopblock.mode, midi.cc.roli.loopblock.mute, midi.cc.roli.loopblock.metro, midi.cc.roli.loopblock.skip, midi.cc.roli.loopblock.back, midi.cc.roli.loopblock.play, midi.cc.roli.loopblock.record, midi.cc.roli.loopblock.learn, midi.cc.roli.loopblock.prev, midi.cc.roli.loopblock.next)
        afterTouch(num 0…127, val 0…127, chan 1…32, port 1…16, time  0)
        pitchBend(val 0…16384=8192, chan 1…32, port 1…16, time  0)
        programChange(num 0…255, chan 1…32, port 1…16, time  0) //1, 632, 255
        nrpn(num 0…16383, val 0…1, chan, time)>>(midi.skypad.plane, midi.skypad.xfade)
    }
    skypad { plane(num ==  129, val 0…1, chan, time)<>menu.model.canvas.color.plane
        xfade(num ==  130, val 0…1, chan, time)<>sky.color.xfade
    }
    cc { skypad { plane(cc ==  11, val 0…127, chan, ma time)<>menu.model.canvas.color.plane
        xfade(cc ==  10, val 0…127, chan, time)<>sky.color.xfade
    }
        roli { lightpad { x(cc ==  114, val 0…127, chan, time)
            y(cc ==  113, val 0…127, chan, time)
            z(cc ==  115, val 0…127, chan, time)
        }
            loopblock { mode(cc ==  102, val 0…127, chan, time)
                mute(cc ==  103, val 0…127, chan, time)
                metro(cc ==  104, val 0…127, chan, time)
                skip(cc ==  105, val 0…127, chan, time)
                back(cc ==  106, val 0…127, chan, time)
                play(cc ==  107, val 0…127, chan, time)
                record(cc ==  108, val 0…127, chan, time)
                learn(cc ==  109, val 0…127, chan, time)
                prev(cc ==  110, val 0…127, chan, time)
                next(cc ==  111, val 0…127, chan, time)
            }
        }
    }
    notes { dot(x : num %  12, y : num _/  12, z : velo)>>sky.draw.dot
    }
    _cc { main { modWheel(num ==  1, val, chan, time)
        volume(num ==  7, val, chan, time)
        balance(num ==  8, val, chan, time)
        panPosition(num ==  10, val, chan, time)
        expression(num ==  11, val, chan, time)
        controller(num in 32…63, val, chan, time) // controller 0…31
        portamento { time(num ==  5, val, chan, time)
            amount(num ==  84, val, chan, time)
        }
    }
        pedal { hold(num ==  64, val, chan, time)
            porta(num ==  65, val, chan, time)
            sosta(num ==  66, val, chan, time)
            _soft(num ==  67, val, chan, time)
            _legato(num ==  68, val, chan, time)
            _hold2(num ==  69, val, chan, time)
        }
        _cc { _main2 { bankSelect(num ==  0, val, chan, time)
            breathCtrl(num ==  2, val, chan, time)
            footPedal(num ==  4, val, chan, time)
            dataEntry(num ==  6, val, chan, time)
            effectControl1(num ==  12, val, chan, time)
            effectControl2(num ==  13, val, chan, time)
        }
            _sound { soundVariation(num ==  70, val, chan, time)
                resonance(num ==  71, val, chan, time)
                soundReleaseTime(num ==  72, val, chan, time)
                soundAttackTime(num ==  73, val, chan, time)
                frequencyCutoff(num ==  74, val, chan, time)
                timbre(num ==  71, val, chan, time)
                brightness(num ==  74, val, chan, time)
            }
            _button { button1(num ==  80, val, chan, time)
                button2(num ==  81, val, chan, time)
                button3(num ==  82, val, chan, time)
                button4(num ==  83, val, chan, time)
                decayor(num ==  80, val, chan, time)
                hiPassFilter(num ==  81, val, chan, time)
                generalPurpose82(num ==  82, val, chan, time)
                generalPurpose83(num ==  83, val, chan, time)
            }
            _roland { rolandToneLevel1(num ==  80, val, chan, time)
                rolandToneLevel2(num ==  81, val, chan, time)
                rolandToneLevel3(num ==  82, val, chan, time)
                rolandToneLevel4(num ==  83, val, chan, time)
            }
            _level { reverbLevel(num ==  91, val, chan, time)
                tremoloLevel(num ==  92, val, chan, time)
                chorusLevel(num ==  93, val, chan, time)
                detuneLevel(num ==  94, val, chan, time)
                phaserLevel(num ==  95, val, chan, time)
            }
            _parameter { dataButtonIncrement(num ==  96, val, chan, time)
                dataButtonDecrement(num ==  97, val, chan, time)
                nonregisteredParameterLSB(num ==  98, val, chan, time)
                nonregisteredParameterMSB(num ==  99, val, chan, time)
                registeredParameterLSB(num ==  100, val, chan, time)
                registeredParameterMSB(num ==  101, val, chan, time)
            }
            _soundControl { soundControl6(num ==  75, val, chan, time)
                soundControl7(num ==  76, val, chan, time)
                soundControl8(num ==  77, val, chan, time)
                soundControl9(num ==  78, val, chan, time)
                soundControl10(num ==  79, val, chan, time)
            }
            _undefined { undefined_3(num ==  3, val, chan, time)
                undefined_9(num ==  9, val, chan, time)
                undefined_14_31(num in 14…31, val, chan, time)
                undefined_85_90(num in 85…90, val, chan, time)
                undefined_102_119(num in 102…119, val, chan, time)
            }
            _mode { allSoundOff(num ==  120, val, chan, time)
                allControllersOff(num ==  121, val, chan, time)
                localKeyboard(num ==  122, val, chan, time)
                allNotesOff(num ==  123, val, chan, time)
                monoOperation(num ==  126, val, chan, time)
                polyMode(num ==  127, val, chan, time)
            }
            _omni { omniModeOff(num ==  124, val, chan, time)
                omniModeOn(num ==  125, val, chan, time)
                omniMode(0…1)<<(midi._cc._cc._omni.omniModeOff( 0), midi._cc._cc._omni.omniModeOn( 1))
            }
        }
    }
}



scriptNow ⟹
sky { // visual music synth
    main { // main controls
        fps // frames per second
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
        xfade(val)
    }
    input { // phone and tablet pencil input

        azimuth(x, y)>>shader.model.pipe.draw
        accel(x, y, z) { // accelerometer
            on }
        radius(31.24) // finger silhouette
        tilt // use tilt
        force(0.239394)>>sky.draw.brush.size // pen pressure
    }
    draw { // draw on metal layer
        screen { // fill 32 bit universe
            fill(0) // all zeros 0x00000000
        }
        brush { // type of brush and range
            size(31.24) // range of radius
            press // pressure changes size
            index // index in 256 color palette
                  // <<(osc.tuio.z osc.manos˚z) // redirect from OSC
        }
        line { // place holder for line drawing
            prev(x, y) // staring point of segment
            next(x, y) // endint point of segment
        }
        dot(x, y, z)
    }
}
shader { model { cell { fade { on>>(shader.model.cell.fade.on(0), shader.model.cell.ave.on(0), shader.model.cell.melt.on(0), shader.model.cell.tunl.on(0), shader.model.cell.slide.on(0), shader.model.cell.fred.on(0), shader.model.cell.zha.on(0))<<shader.model.cell.fade }
    ave { on>>(shader.model.cell.fade.on(0), shader.model.cell.ave.on(0), shader.model.cell.melt.on(0), shader.model.cell.tunl.on(0), shader.model.cell.slide.on(0), shader.model.cell.fred.on(0), shader.model.cell.zha.on(0))<<shader.model.cell.ave }
    melt { on>>(shader.model.cell.fade.on(0), shader.model.cell.ave.on(0), shader.model.cell.melt.on(0), shader.model.cell.tunl.on(0), shader.model.cell.slide.on(0), shader.model.cell.fred.on(0), shader.model.cell.zha.on(0))<<shader.model.cell.melt }
    tunl { on>>(shader.model.cell.fade.on(0), shader.model.cell.ave.on(0), shader.model.cell.melt.on(0), shader.model.cell.tunl.on(0), shader.model.cell.slide.on(0), shader.model.cell.fred.on(0), shader.model.cell.zha.on(0))<<shader.model.cell.tunl }
    slide { on>>(shader.model.cell.fade.on(0), shader.model.cell.ave.on(0), shader.model.cell.melt.on(0), shader.model.cell.tunl.on(0), shader.model.cell.slide.on(0), shader.model.cell.fred.on(0), shader.model.cell.zha.on(0))<<shader.model.cell.slide }
    fred { on>>(shader.model.cell.fade.on(0), shader.model.cell.ave.on(0), shader.model.cell.melt.on(0), shader.model.cell.tunl.on(0), shader.model.cell.slide.on(0), shader.model.cell.fred.on(0), shader.model.cell.zha.on(0))<<shader.model.cell.fred }
    zha { on>>(shader.model.cell.fade.on(0), shader.model.cell.ave.on(0), shader.model.cell.melt.on(0), shader.model.cell.tunl.on(0), shader.model.cell.slide.on(0), shader.model.cell.fred.on(0), shader.model.cell.zha.on(0))<<shader.model.cell.zha bits loops(11)
    }
}
    pipe { draw(x, y) { on }
        record { on }
        camera { on flip(0)
        }
        camix { on mix(0)
        }
        color // bitplane
        render { frame(x 0, y 0, w 1080, h 1920)
            repeat(x, y)
            mirror(x, y)
        }
    }
}
    file { cell { fade("cell.fader.metal")
        ave("cell.ave.metal")
        melt("cell.melt.metal")
        tunl("cell.tunl.metal")
        slide("cell.slide.metal")
        fred("cell.fred.metal")
        zha("cell.zha.metal")
    }
        pipe { record camera("cell.camera.metal")
            camix("cell.camix.metal")
            draw("pipe.draw.metal")
            render("pipe.render.metal")
            color("pipe.color.metal")
        }
    }
}
menu { view { canvas(symbol "photo.artframe") { tile(image "icon.shader.tile.png") { mirror(symbol "arrowtriangle.left.and.line.vertical.and.arrowtriangle.right")
    repeat(symbol "rectangle.grid.2x2")
    shift(image "icon.cell.scroll")
    tilt(image "icon.pen.tilt")
}
    color(image "icon.pal.main") { fade(symbol "slider.horizontal.below.rectangle")
        plane(symbol "square.3.layers.3d.down.right")
        zero(symbol "drop")
        one(symbol "drop.fill")
    }
    speed(image "icon.speed") { fps(symbol "speedometer")
        run(symbol "goforward")
    }
}
    brush(symbol "paintbrush.pointed") { size(symbol "circle.circle")
        press(image "icon.pen.press")
        tilt(image "icon.pen.tilt") //(symbol "angle")
    }
    cell(symbol "circle.grid.3x3") { fade(image "icon.cell.fade")
        ave(image "icon.cell.ave")
        melt(image "icon.cell.melt")
        tunl(image "icon.cell.tunl")
        zha(image "icon.cell.zha")
        slide(image "icon.cell.slide")
        fred(image "icon.cell.fred")
    }
    cam(symbol "camera") { snap(symbol "camera.shutter.button")
        fake(symbol "face.dashed")
        real(symbol "face.smiling")
        face(symbol "arrow.triangle.2.circlepath.camera")
        mix(symbol "slider.horizontal.below.rectangle")
    }
}
    model { canvas { tile { mirror(x, y)>>shader.model.pipe.render.mirror
        repeat(x, y)>>shader.model.pipe.render.repeat
        shift(x, y)<>shader.model.pipe.draw
        tilt(tog)<>sky.input.tilt
    }
        color { fade(val)<>sky.color.xfade
            plane(val)<>shader.model.pipe.color
            zero(tap)>>sky.draw.screen.fill(0)
            one(tap)>>sky.draw.screen.fill(1)
        }
        speed { fps(seg)>>sky.main.fps
            run(tog)>>sky.main.run
        }
    }
        brush { size(val)>>(sky.draw.brush.size, menu.model.brush.press(0))
            press(tog)>>sky.draw.brush.press
            tilt(tog)<>sky.input.tilt
        }
        cell { fade(val)>>shader.model.cell.fade
            ave(val)>>shader.model.cell.ave
            melt(val)>>shader.model.cell.melt
            tunl(seg)>>shader.model.cell.tunl
            zha(seg)>>shader.model.cell.zha
            slide(seg)>>shader.model.cell.slide
            fred(seg)>>shader.model.cell.fred
        }
        cam { snap(tap)
            fake(tog)>>shader.model.pipe.camix.on
            real(tog)>>shader.model.pipe.camera.on
            face(tog)>>shader.model.pipe.camera.flip
            mix(val)>>shader.model.pipe.camix.mix
        }
    }
}
midi { // musical instrument device interface
    input { // midi input
        note { // note on/off from 0 thru 127
            on(num, velo, chan, port, time 0)>>(midi.notes.dot, midi.output.note.on)
            off(num, velo, chan, port, time 0)>>(midi.input.note.on, midi.output.note.off)
        }
        controller(cc, val, chan, port, time 0)>>(midi.cc.skypad.plane, midi.cc.skypad.xfade, midi.cc.roli.lightpad.x, midi.cc.roli.lightpad.y, midi.cc.roli.lightpad.z, midi.cc.roli.loopblock.mode, midi.cc.roli.loopblock.mute, midi.cc.roli.loopblock.metro, midi.cc.roli.loopblock.skip, midi.cc.roli.loopblock.back, midi.cc.roli.loopblock.play, midi.cc.roli.loopblock.record, midi.cc.roli.loopblock.learn, midi.cc.roli.loopblock.prev, midi.cc.roli.loopblock.next)
        afterTouch(num, val, chan, port, time 0)
        pitchBend(val, chan, port, time 0)
        programChange(num, chan, port, time 0) //1, 632, 255
        nrpn(num, val, chan, time)>>(midi.skypad.plane, midi.skypad.xfade)
    }
    output @input { note { // note on/off from 0 thru 127
        on(num, velo, chan, port, time 0)>>(midi.notes.dot, midi.output.note.on)
        off(num, velo, chan, port, time 0)>>(midi.input.note.on, midi.output.note.off)
    }
        controller(cc, val, chan, port, time 0)>>(midi.cc.skypad.plane, midi.cc.skypad.xfade, midi.cc.roli.lightpad.x, midi.cc.roli.lightpad.y, midi.cc.roli.lightpad.z, midi.cc.roli.loopblock.mode, midi.cc.roli.loopblock.mute, midi.cc.roli.loopblock.metro, midi.cc.roli.loopblock.skip, midi.cc.roli.loopblock.back, midi.cc.roli.loopblock.play, midi.cc.roli.loopblock.record, midi.cc.roli.loopblock.learn, midi.cc.roli.loopblock.prev, midi.cc.roli.loopblock.next)
        afterTouch(num, val, chan, port, time 0)
        pitchBend(val, chan, port, time 0)
        programChange(num, chan, port, time 0) //1, 632, 255
        nrpn(num, val, chan, time)>>(midi.skypad.plane, midi.skypad.xfade)
    }
    skypad { plane(num, val, chan, time)<>menu.model.canvas.color.plane
        xfade(num, val, chan, time)<>sky.color.xfade
    }
    cc { skypad { plane(cc, val, chan, ma time)<>menu.model.canvas.color.plane
        xfade(cc, val, chan, time)<>sky.color.xfade
    }
        roli { lightpad { x(cc, val, chan, time)
            y(cc, val, chan, time)
            z(cc, val, chan, time)
        }
            loopblock { mode(cc, val, chan, time)
                mute(cc, val, chan, time)
                metro(cc, val, chan, time)
                skip(cc, val, chan, time)
                back(cc, val, chan, time)
                play(cc, val, chan, time)
                record(cc, val, chan, time)
                learn(cc, val, chan, time)
                prev(cc, val, chan, time)
                next(cc, val, chan, time)
            }
        }
    }
    notes { dot(x, y, z)>>sky.draw.dot
    }
    _cc { main { modWheel(num, val, chan, time)
        volume(num, val, chan, time)
        balance(num, val, chan, time)
        panPosition(num, val, chan, time)
        expression(num, val, chan, time)
        controller(num, val, chan, time) // controller 0…31
        portamento { time(num, val, chan, time)
            amount(num, val, chan, time)
        }
    }
        pedal { hold(num, val, chan, time)
            porta(num, val, chan, time)
            sosta(num, val, chan, time)
            _soft(num, val, chan, time)
            _legato(num, val, chan, time)
            _hold2(num, val, chan, time)
        }
        _cc { _main2 { bankSelect(num, val, chan, time)
            breathCtrl(num, val, chan, time)
            footPedal(num, val, chan, time)
            dataEntry(num, val, chan, time)
            effectControl1(num, val, chan, time)
            effectControl2(num, val, chan, time)
        }
            _sound { soundVariation(num, val, chan, time)
                resonance(num, val, chan, time)
                soundReleaseTime(num, val, chan, time)
                soundAttackTime(num, val, chan, time)
                frequencyCutoff(num, val, chan, time)
                timbre(num, val, chan, time)
                brightness(num, val, chan, time)
            }
            _button { button1(num, val, chan, time)
                button2(num, val, chan, time)
                button3(num, val, chan, time)
                button4(num, val, chan, time)
                decayor(num, val, chan, time)
                hiPassFilter(num, val, chan, time)
                generalPurpose82(num, val, chan, time)
                generalPurpose83(num, val, chan, time)
            }
            _roland { rolandToneLevel1(num, val, chan, time)
                rolandToneLevel2(num, val, chan, time)
                rolandToneLevel3(num, val, chan, time)
                rolandToneLevel4(num, val, chan, time)
            }
            _level { reverbLevel(num, val, chan, time)
                tremoloLevel(num, val, chan, time)
                chorusLevel(num, val, chan, time)
                detuneLevel(num, val, chan, time)
                phaserLevel(num, val, chan, time)
            }
            _parameter { dataButtonIncrement(num, val, chan, time)
                dataButtonDecrement(num, val, chan, time)
                nonregisteredParameterLSB(num, val, chan, time)
                nonregisteredParameterMSB(num, val, chan, time)
                registeredParameterLSB(num, val, chan, time)
                registeredParameterMSB(num, val, chan, time)
            }
            _soundControl { soundControl6(num, val, chan, time)
                soundControl7(num, val, chan, time)
                soundControl8(num, val, chan, time)
                soundControl9(num, val, chan, time)
                soundControl10(num, val, chan, time)
            }
            _undefined { undefined_3(num, val, chan, time)
                undefined_9(num, val, chan, time)
                undefined_14_31(num, val, chan, time)
                undefined_85_90(num, val, chan, time)
                undefined_102_119(num, val, chan, time)
            }
            _mode { allSoundOff(num, val, chan, time)
                allControllersOff(num, val, chan, time)
                localKeyboard(num, val, chan, time)
                allNotesOff(num, val, chan, time)
                monoOperation(num, val, chan, time)
                polyMode(num, val, chan, time)
            }
            _omni { omniModeOff(num, val, chan, time)
                omniModeOn(num, val, chan, time)
                omniMode<<(midi._cc._cc._omni.omniModeOff(0), midi._cc._cc._omni.omniModeOn(1)) }
        }
    }
}



