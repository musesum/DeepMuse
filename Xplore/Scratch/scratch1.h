model {
    canvas {
        tile  {
            mirror (x: 0…1=0, y: 0…1=0)
            ^ sky.main.anim
            <> shader.render˚mirror

            repeat (x: -1…1=0, y: -1…1=0)
            ^ sky.main.anim
            <> shader.render˚repeat

            shift  (x: 0…1=0.5, y: 0…1=0.5)
            ^ sky.main.anim
            <> shader.compute.draw
        }
        color {
            fade (val: 0…1=0.5)
            <> sky.color.xfade
            ^ sky.main.anim

            plane (val: 0…1=0.1)
            ^ sky.main.anim
            <> shader.compute.color

            fill_0 (tap: 0…1) <> sky.draw.screen.fill(0)
            fill_1 (tap: 0…1) <> sky.draw.screen.fill(1)
        }
        speed {
            fps (seg: 0…60=60)  <> sky.main.fps
            run (tog: 0…1=1 )   <> sky.main.run
            anim(val: 0…1=0.24) <> sky.main.anim
        }
    }
    brush {
        size  (val: 0…1=0.5)   <> sky.draw.brush.size
        press (tog: 0…1=1  )   <> sky.draw.brush.press
        tilt  (tog: 0…1=0)     <> sky.input.tilt
        index (seg: 1…255=127) <> sky.draw.brush.index
    }
    cell {
        fade  (val: 1.61…3=1.61) <> shader.cell.fade
        ave   (val: 0…1=0.5) <> shader.cell.ave
        melt  (val: 0…1=0.5) <> shader.cell.melt
        tunl  (seg: 0…5=1  ) <> shader.cell.tunl
        zha   (seg: 0…6=2  ) <> shader.cell.zha
        slide (seg: 0…7=3  ) <> shader.cell.slide
        fred  (seg: 0…4=4  ) <> shader.cell.fred
    }
    camera {
        stream (tog: 0…1=0  ) <> shader.compute.camera.on
        facing (tog: 0…1=1  ) <> shader.compute.camera.flip
        mask   (tog: 0…1=1  )
        mix    (val: 0…1=0.5) <> shader.compute.camix.mix
    }
    network (symbol: "network") {
        bonjour (peer: "bonjour") <> sky.main.peer.bonjour
        follow  (tog: 0…1=1) <> sky.main.peer.follow
        midi    (tog: 0…1=1) <> sky.main.peer.midi
    }
}

midi { // musical instrument device interface
    input { // midi input
        note { // note on/off from 0 thru 127
            on  (num: 0_127, velo: 0_127, chan: 1_32, port: 1_16, time)
            off (num: 0_127, velo: 0_127, chan: 1_32, port: 1_16, time)
        }
        controller (cc: 0_127, val: 0_127, chan: 1_32, port: 1_16, time)
        afterTouch (num: 0_127, val: 0_127, chan: 1_32, port: 1_16, time)
        pitchBend  (val: 0_16384=8192, chan: 1_32, port: 1_16, time)
        programChange (num: 0_255, chan: 1_32, port: 1_16, time) //1, 632, 255
        nrpn (num: 0_16383, val: 0…1, chan, time)
    }

    output @ input

    skypad {
        plane(num == 129, val: 0…1, chan, time)
        <> model.canvas.color.plane

        fade(num == 130, val: 0…1, chan, time)
        <> model.canvas.color.fade
    }
    input.nrpn >> skypad˚.

    cc {
        skypad {

            zoom(cc == 4, val: 0_127, chan, time)
            <> model.canvas.plato.zoom

            convex(cc == 5, val: 0_127, chan, time)
            <> model.canvas.plato.shade.convex

            colorY(cc == 6, val: 0_127, chan, time)
            <> model.canvas.plato.shade.colors(y: val)

            fade(cc == 10, val: 0_127, chan, time)
            <> model.canvas.color.fade

            plane(cc == 11, val: 0_127, chan, time)
            <> model.canvas.color.plane

            camix(cc == 9, val: 0_127, chan, time)
            <> model.cam.mix

            shiftX(cc == 12, val: 0_127, chan, time)
            <> model.canvas.tile.shift(x:val)

            shiftY(cc == 13, val: 0_127, chan, time)
            <> model.canvas.tile.shift(y:val)

            repeatX(cc == 14, val: 0_127, chan, time)
            <> model.canvas.tile.repeat(x:val)

            repeatY(cc == 15, val: 0_127, chan, time)
            <> model.canvas.tile.repeat(y:val)
        }
        roli {
            lightpad {
                x (cc == 114, val: 0_127, chan, time)
                y (cc == 113, val: 0_127, chan, time)
                z (cc == 115, val: 0_127, chan, time)
            }
            loopblock {
                mode    (cc == 102, val: 0_127, chan, time)
                mute    (cc == 103, val: 0_127, chan, time)
                metro   (cc == 104, val: 0_127, chan, time)
                skip    (cc == 105, val: 0_127, chan, time)
                back    (cc == 106, val: 0_127, chan, time)
                play    (cc == 107, val: 0_127, chan, time)
                record  (cc == 108, val: 0_127, chan, time)
                learn   (cc == 109, val: 0_127, chan, time)
                prev    (cc == 110, val: 0_127, chan, time)
                next    (cc == 111, val: 0_127, chan, time)
            }
        }
    }
    input.controller >> cc˚.
    output.controller << cc˚.

    notes {
        dot.on (x: num % 12, y: num _/ 12, z: velo) >> sky.draw.dot.on
        dot.off(x: num % 12, y: num _/ 12, z: velo) >> sky.draw.dot.off
    }
    input.note.on  >> (notes.dot.on,  output.note.on)
    input.note.off >> (notes.dot.off, output.note.off)

    _cc {
        main {
            modWheel    (num ==  1, val, chan, time)
            volume      (num ==  7, val, chan, time)
            balance     (num ==  8, val, chan, time)
            panPosition (num == 10, val, chan, time)
            expression  (num == 11, val, chan, time)
            controller  (num in 32_63, val, chan, time) // controller 0_31
            portamento {
                time   (num == 5, val, chan, time)
                amount (num == 84, val, chan, time)
            }
        }
        pedal {
            hold    (num == 64, val, chan, time)
            porta   (num == 65, val, chan, time)
            sosta   (num == 66, val, chan, time)
            _soft   (num == 67, val, chan, time)
            _legato (num == 68, val, chan, time)
            _hold2  (num == 69, val, chan, time)
        }
        _cc {
            _main2 {
                bankSelect  (num == 0, val, chan, time)
                breathCtrl  (num == 2, val, chan, time)
                footPedal   (num == 4, val, chan, time)
                dataEntry   (num == 6, val, chan, time)
                effectControl1 (num == 12, val, chan, time)
                effectControl2 (num == 13, val, chan, time)
            }
            _sound {
                soundVariation  (num == 70, val, chan, time)
                resonance       (num == 71, val, chan, time)
                soundReleaseTime(num == 72, val, chan, time)
                soundAttackTime (num == 73, val, chan, time)
                frequencyCutoff (num == 74, val, chan, time)

                timbre          (num == 71, val, chan, time)
                brightness      (num == 74, val, chan, time)
            }
            _button {
                button1 (num == 80, val, chan, time)
                button2 (num == 81, val, chan, time)
                button3 (num == 82, val, chan, time)
                button4 (num == 83, val, chan, time)

                decayor          (num == 80, val, chan, time)
                hiPassFilter     (num == 81, val, chan, time)
                generalPurpose82 (num == 82, val, chan, time)
                generalPurpose83 (num == 83, val, chan, time)
            }
            _roland {
                rolandToneLevel1 (num == 80, val, chan, time)
                rolandToneLevel2 (num == 81, val, chan, time)
                rolandToneLevel3 (num == 82, val, chan, time)
                rolandToneLevel4 (num == 83, val, chan, time)
            }
            _level {
                reverbLevel  (num == 91, val, chan, time)
                tremoloLevel (num == 92, val, chan, time)
                chorusLevel  (num == 93, val, chan, time)
                detuneLevel  (num == 94, val, chan, time)
                phaserLevel  (num == 95, val, chan, time)
            }
            _parameter {
                dataButtonIncrement       (num == 96, val, chan, time)
                dataButtonDecrement       (num == 97, val, chan, time)
                nonregisteredParameterLSB (num == 98, val, chan, time)
                nonregisteredParameterMSB (num == 99, val, chan, time)
                registeredParameterLSB    (num == 100, val, chan, time)
                registeredParameterMSB    (num == 101, val, chan, time)
            }
            _soundControl {
                soundControl6  (num == 75, val, chan, time)
                soundControl7  (num == 76, val, chan, time)
                soundControl8  (num == 77, val, chan, time)
                soundControl9  (num == 78, val, chan, time)
                soundControl10 (num == 79, val, chan, time)
            }
            _undefined {
                undefined_3       (num == 3      , val, chan, time)
                undefined_9       (num == 9      , val, chan, time)
                undefined_14_31   (num in 14_31  , val, chan, time)
                undefined_85_90   (num in 85_90  , val, chan, time)
                undefined_102_119 (num in 102_119, val, chan, time)
            }
            _mode {
                allSoundOff       (num == 120, val, chan, time)
                allControllersOff (num == 121, val, chan, time)
                localKeyboard     (num == 122, val, chan, time)
                allNotesOff       (num == 123, val, chan, time)
                monoOperation     (num == 126, val, chan, time)
                polyMode          (num == 127, val, chan, time)
            }
            _omni {
                omniModeOff       (num == 124, val, chan, time)
                omniModeOn        (num == 125, val, chan, time)
                omniMode(0_1) << (omniModeOff(0), omniModeOn(1))
            }
        }
    }
}


_menu  {
    canvas (svg: "icon.canvas") {
        tile (svg: "icon.tile") {
            mirror (svg: "icon.mirror")
            repeat (svg: "icon.repeat.arrows")
            shift  (svg: "icon.direction")
        }
        color(img: "icon.pal.main") {
            fade   (svg: "icon.gradient")
            plane  (svg: "icon.layers")
            fill_0 (sym: "drop")
            fill_1 (sym: "drop.fill")
        }
        speed (img: "icon.speed") {
            fps  (sym: "speedometer")
            run  (sym: "goforward")
            anim (sym: "bolt.fill")
        }
    }
    brush (svg: "icon.brush") {
        size  (svg: "icon.size.dot")
        press (sym: "scribble.variable")
        tilt  (sym: "angle")
        index (sym: "calendar.day.timeline.left")
    }
    cell (svg: "icon.ca.grid") {
        fade  (img: "icon.cell.fade" )
        ave   (img: "icon.cell.ave"  )
        melt  (img: "icon.cell.melt" )
        tunl  (img: "icon.cell.tunl" )
        zha   (img: "icon.cell.zha"  )
        slide (img: "icon.cell.slide")
        fred  (img: "icon.cell.fred" )
    }
    camera (sym: "camera") {
        stream (sym: "video")
        facing (svg: "icon.camera.facing")
        mask   (svg: "icon.face")
        mix    (sym: "camera.filters")
    }
    network (sym: "network") {
        bonjour (sym: "bonjour")
        follow  (sym: "shared.with.you")
        midi    (sym: "pianokeys.inverse")
    }
}
shader {
    pipeline {
        draw
        slide
        color
        flatmap
    }
    cell {
        fade  (1.62…3=1.62) { on(0…1=0) >> cell˚on(0) << .. }
        ave   (0…1=0.5) { on(0…1=1) >> cell˚on(0) << .. }
        melt  (0…1=0.5) { on(0…1=0) >> cell˚on(0) << .. }
        tunl  (0…5=1  ) { on(0…1=0) >> cell˚on(0) << .. }
        slide (0…7=3  ) { on(0…1=0) >> cell˚on(0) << .. }
        fred  (0…4=4  ) { on(0…1=0) >> cell˚on(0) << .. }
        zha   (0…6=2  ) { on(0…1=0) >> cell˚on(0) << .. bits(2…4=3) loops(11)  }
    }
    compute {
        draw (x: 0…1=0.5, y: 0…1=0.5) { on(0…1=1) }
        record { on(0…1=0) }
        camera { on(0…1=0) flip (0) }
        camix  { mix(val: 0…1=0.5) }
        color (val: 0…1=0.1)
        tile {
            repeat(x: -1…1=0, y: -1…1=0)
            mirror(x: 0…1, y: 0…1)
        }
    }
    render {
        flatmap {
            frame(x: 0, y: 0, w: 1080, h: 1920)
            repeat(x: -1…1=0, y: -1…1=0)
            mirror(x: 0…1, y: 0…1)
        }
        cubemap {
            frame(x: 0, y: 0, w: 1080, h: 1920)
            repeat(x: -1…1=0, y: -1…1=0)
            mirror(x: 0…1, y: 0…1)
            gravity(0…2)
            on(0…1=0)
        }
        plato { on(0…1=0) }
    }
}
sky { // visual music synth
    main { // main controls
        fps (1…60=60) // frames per second
        run (0…1=1) // currently running
        anim(val: 0…1=0.9) // animation transition speed
    }
    network {
        bonjour // bonjour status
        follow (0…1=1) // follow remote events
        midi (0…1=1)   // follow midi events
    }
    color { // false color mapping palette
        pal0 ("roygbik")
        pal1 ("wKZ")
        xfade (val: 0 … 1 = 0.5)
    }
    input { // phone and tablet pencil input

        azimuth (x: -0.2 … 0.2,
                 y: -0.2 … 0.2)  >> shader.compute.draw

        accel (x: -0.3 … 0.3,
               y: -0.3 … 0.3,
               z: -0.3 … 0.3)  // accelerometer

        accel.on (0…1)

        radius (1…92=9) // finger silhouette
        tilt (0…1)
        force (0…0.5) >> draw.brush.size
    }
    draw { // draw on metal layer
        screen { // fill 32 bit universe
            fill(0…1=0) // all zeros 0x00000000
        }
        brush { // type of brush and range
            size (1…64=10)    // range of radius
            press (0…1=1)     // pressure changes size
            index (1…255=127) // index in 256 color palette

        }
        line { // place holder for line drawing
            prev (x: 0…1, y: 0…1) // staring point of segment
            next (x: 0…1, y: 0…1) // endint point of segment
        }
        dot {
            on (x, y, z)
            off (x, y, z)
        }
    }
}
model.canvas {
    cube {
        motion (tog: 0…1=1)
        rotate (x: -1…1=0, y: -1…1=0)
        back (tog: 0…1=1)
        show (tog: 0…1=0) <> shader.render.cubemap.on
    }
}
_menu.canvas {
    cube (sym: "cube") {
        motion (sym: "gyroscope")
        rotate (svg: "icon.direction")
        back   (sym: "cube")
        show   (sym: "cube.fill")
    }
}
