controller(cc: 10, val: 127, chan: 1, port: 1, time : 2.30888e+12)


sky { // visual music program
    main { // main controls
        fps (1…60 = 60) // frames per second
        run (1)         // currently running
    }
    pipeline { // default metal pipeline at atartup
        draw   ("draw")    // drawing layer
        ave    ("compute") // compute layer
        color  ("color")   // colorizing layer
        render ("render")  // render layer al
    }
    color { // false color mapping palette
        pal0 ("roygbik")    // palette 0: (r)ed (o)range (y)ellow …
        pal1 ("wKZ")        // palette 1: (w)hite blac(K) fractali(Z)e
        xfade (val 0…1 = 0.5)
    }
    input { // phone and tablet pencil input
        
        azimuth (x -0.2…0.2,
                 y -0.2…0.2)  >> shader.model.pipe.draw
        
        accel (x -0.3…0.3,
               y -0.3…0.3,
               z -0.3…0.3)  // accelerometer
        accel.on (0…1)
        
        radius (1…92 = 9) // finger silhouette
        tilt (0…1)        // use tilt
        force (0…0.5)     // pen pressure
        >> sky.draw.brush.size
    }
    draw { // draw on metal layer
        screen { // fill 32 bit universe
            fill(0) // all zeros 0x00000000
        }
        brush { // type of brush and range
            size (1…64 = 10)    // range of radius
            press (0…1 = 1)     // pressure changes size
            index (1…255 = 127) // index in 256 color palette
                                  // <<(osc.tuio.z osc.manos˚z) // redirect from OSC
        }
        line { // place holder for line drawing
            prev (x 0…1, y 0…1) // staring point of segment
            next (x 0…1, y 0…1) // endint point of segment
        }
        dot (x, y, z)
    }
}
shader{
    model {
        cell {
            fade  (0…1 = 0.5) { on(0…1 = 0) >> cell˚on(0) << .. }
            ave   (0…1 = 0.5) { on(0…1 = 1) >> cell˚on(0) << .. }
            melt  (0…1 = 0.5) { on(0…1 = 0) >> cell˚on(0) << .. }
            tunl  (0…5 = 1  ) { on(0…1 = 0) >> cell˚on(0) << .. }
            slide (0…7 = 3  ) { on(0…1 = 0) >> cell˚on(0) << .. }
            fred  (0…4 = 4  ) { on(0…1 = 0) >> cell˚on(0) << .. }
            zha   (0…6 = 2  ) { on(0…1 = 0) >> cell˚on(0) << ..  bits (2…4=3) loops(11)  }
        }
        pipe {
            draw (x 0…1 = 0.5, y 0…1 = 0.5) { on(0…1 = 0) }
            record { on(0…1 = 0) }
            camera { on(0…1 = 0) flip (0) }
            camix  { on(0…1 = 0) mix (0) }
            color  (0…1 = 0.1) // bitplane
            render {
                frame (x 0, y 0, w 1080, h 1920)
                repeat (x, y)
                mirror (x, y)
            }
        }
    }
    file {
        cell {
            fade  ("cell.fader.metal")
            ave   ("cell.ave.metal"  )
            melt  ("cell.melt.metal" )
            tunl  ("cell.tunl.metal" )
            slide ("cell.slide.metal")
            fred  ("cell.fred.metal" )
            zha   ("cell.zha.metal"  )
        }
        pipe {
            record
            camera ("cell.camera.metal")
            camix  ("cell.camix.metal" )
            draw   ("pipe.draw.metal" )
            render ("pipe.render.metal")
            color  ("pipe.color.metal" )
        }
    }
}
menu {
    view {
        canvas (symbol "photo.artframe") {
            tile (image "icon.shader.tile.png") {
                mirror (symbol "arrowtriangle.left.and.line.vertical.and.arrowtriangle.right")
                repeat (symbol "rectangle.grid.2x2" )
                shift (image "icon.cell.scroll")
                tilt  (image "icon.pen.tilt")
            }
            color(image "icon.pal.main") {
                fade  (symbol "slider.horizontal.below.rectangle")
                plane (symbol "square.3.layers.3d.down.right")
                zero  (symbol "drop")
                one   (symbol "drop.fill")
            }
            speed (image "icon.speed") {
                fps (symbol "speedometer")
                run (symbol "goforward")
            }
        }
        brush (symbol "paintbrush.pointed") {
            size  (symbol "circle.circle")
            press (image "icon.pen.press")
            tilt  (image "icon.pen.tilt")  //(symbol "angle")
        }
        cell (symbol "circle.grid.3x3") {
            fade  (image "icon.cell.fade" )
            ave   (image "icon.cell.ave"  )
            melt  (image "icon.cell.melt" )
            tunl  (image "icon.cell.tunl" )
            zha   (image "icon.cell.zha"  )
            slide (image "icon.cell.slide")
            fred  (image "icon.cell.fred" )
        }
        cam (symbol "camera") {
            snap  (symbol "camera.shutter.button")
            fake  (symbol "face.dashed")
            real  (symbol "face.smiling")
            face  (symbol "arrow.triangle.2.circlepath.camera")
            mix   (symbol "slider.horizontal.below.rectangle")
        }
    }
    model {
        canvas {
            tile  {
                mirror (x 0…1 = 0,
                        y 0…1 = 0) >> shader.model.pipe.render.mirror

                repeat (x -1…1 = 0.5,
                        y -1…1 = 0.5) >> shader.model.pipe.render.repeat

                shift (x 0…1 = 0.5,
                       y 0…1 = 0.5) <> shader.model.pipe.draw

                tilt  (tog 0…1 = 0) <> sky.input.tilt
            }
            color {
                fade  (val 0…1 = 0) <> sky.color.xfade
                plane (val 0…1 = 0) <> shader.model.pipe.color
                zero  (tap 0…1 = 0) >> sky.draw.screen.fill(0)
                one   (tap 0…1 = 0) >> sky.draw.screen.fill(1)
            }
            speed {
                fps (seg 0…60 = 60) >> sky.main.fps
                run (tog 0…1  = 1 ) >> sky.main.run
            }
        }
        brush {
            size  (val 0…1 = 0.5) >> (sky.draw.brush.size, press(0))
            press (tog 0…1 = 1  ) >> sky.draw.brush.press
            tilt  (tog 0…1 = 1  ) <> sky.input.tilt
        }
        cell {
            fade  (val 2…3 = 2.2) >> shader.model.cell.fade
            ave   (val 0…1 = 0.5) >> shader.model.cell.ave
            melt  (val 0…1 = 0.5) >> shader.model.cell.melt
            tunl  (seg 0…5 = 1  ) >> shader.model.cell.tunl
            zha   (seg 0…6 = 2  ) >> shader.model.cell.zha
            slide (seg 0…7 = 3  ) >> shader.model.cell.slide
            fred  (seg 0…4 = 4  ) >> shader.model.cell.fred
        }
        cam {
            snap  (tap 0…1 = 0  )
            fake  (tog 0…1 = 0  ) >> shader.model.pipe.camix.on
            real  (tog 0…1 = 1  ) >> shader.model.pipe.camera.on
            face  (tog 0…1 = 1  ) >> shader.model.pipe.camera.flip
            mix   (val 0…1 = 0.5) >> shader.model.pipe.camix.mix
        }
    }
}
midi { // musical instrument device interface
    input { // midi input
        note { // note on/off from 0 thru 127
            on  (num 0…127, velo 0…127, chan 1…32, port 1…16, time 0)
            off (num 0…127, velo 0…127, chan 1…32, port 1…16, time 0)
        }
        controller (cc 0…127, val 0…127, chan 1…32, port 1…16, time 0)
        afterTouch (num 0…127, val 0…127, chan 1…32, port 1…16, time 0)
        pitchBend  (val 0…16384=8192, chan 1…32, port 1…16, time 0)
        programChange (num 0…255, chan 1…32, port 1…16, time 0) //1, 632, 255
        nrpn (num 0…16383, val 0…1, chan, time)
    }
    
    output @ input
    
    skypad {
        plane(num == 129, val 0…1, chan, time)
        <> menu.model.canvas.color.plane
        
        xfade(num == 130, val 0…1, chan, time)
        <> sky.color.xfade
    }
    input.nrpn >> skypad˚.
    
    cc {
        skypad {
            plane(cc == 11, val 0…127, chan, time)
            <> menu.model.canvas.color.plane
            
            xfade(cc == 10, val 0…127, chan, time)
            <> sky.color.xfade
        }
        roli {
            lightpad {
                x (cc == 114, val 0…127, chan, time)
                y (cc == 113, val 0…127, chan, time)
                z (cc == 115, val 0…127, chan, time)
            }
            loopblock {
                mode    (cc == 102, val 0…127, chan, time)
                mute    (cc == 103, val 0…127, chan, time)
                metro   (cc == 104, val 0…127, chan, time)
                skip    (cc == 105, val 0…127, chan, time)
                back    (cc == 106, val 0…127, chan, time)
                play    (cc == 107, val 0…127, chan, time)
                record  (cc == 108, val 0…127, chan, time)
                learn   (cc == 109, val 0…127, chan, time)
                prev    (cc == 110, val 0…127, chan, time)
                next    (cc == 111, val 0…127, chan, time)
            }
        }
    }
    input.controller >> cc˚.
    output.controller << cc˚.
    
    notes {
        dot(x: num % 12,
            y: num _/ 12,
            z: velo) >> sky.draw.dot
    }
    input.note.on >> (notes˚., output.note.on)
    input.note.off >> (input.note.on, output.note.off)
    
    _cc {
        main {
            modWheel    (num == 1, val, chan, time)
            volume      (num == 7, val, chan, time)
            balance     (num == 8, val, chan, time)
            panPosition (num == 10, val, chan, time)
            expression  (num == 11, val, chan, time)
            controller  (num in 32…63, val, chan, time) // controller 0…31
            portamento {
                time   (num == 5, val, chan, time)
                amount (num == 84, val, chan, time)
            }
        }
        pedal {
            hold    (num == 64, val, chan, time)
            porta   (num == 65, val, chan, time)
            sosta   (num == 66, val, chan, time)
            _soft    (num == 67, val, chan, time)
            _legato  (num == 68, val, chan, time)
            _hold2   (num == 69, val, chan, time)
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
                undefined_3       (num == 3       , val, chan, time)
                undefined_9       (num == 9       , val, chan, time)
                undefined_14_31   (num in 14…31  , val, chan, time)
                undefined_85_90   (num in 85…90  , val, chan, time)
                undefined_102_119 (num in 102…119, val, chan, time)
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
                omniMode(0…1) << (omniModeOff(0), omniModeOn(1))
            }
        }
    }
}

