sky { // visual music program

    main { // main controls

        frame (1945) // frame counter
        fps (1…60 = 60) // frames per second
        run (1) // currently running
    }
    pipeline { // default metal pipeline at atartup

        draws "draw" // drawing layer
        ave "compute" // compute layer
        color "color" // colorizing layer
        render "render" // render layer al
    }
    dock { // list of panel items to put in dock

        camera fade ave (1)
        melt tunl zha slide fred brush color scroll tile speed record }
    color { // false color mapping palette

        pal0 "roygbik" // palette 0: (r)ed (o)range (y)ellow ...
        pal1 "wKZ" // palette 1: (w)hite blac(K) fractali(Z)e
        xfade (0…1 = 0.5) // cross fade between pal0 and pal1
    }
    input { // phone and tablet pencil input


        azimuth (x -0.2…0.2, y -0.2…0.2) // pen tilt

        accel (x -0.3…0.3, y -0.3…0.3, z -0.3…0.3) { // accelerometer

            // use accel

            on (0…1)
        }
        radius (1…92 = 9) // finger silhouette
        tilt (0…1) // use tilt
        force (0…0.5) >> draw.brush.size // pen pressure
    }
    draw { // draw on metal layer

        screen { // fill 32 bit universe

            fillZero (0) // all zeros 0x00000000
            fillOne (-1) // all ones 0xFFFFFFFF
        }
        brush { // type of brush and range

            type "dot" // draw a circle
            size (1…64 = 10) // range of radius
            press (0…1 = 1) // pressure changes size
            index (1…255 = 127) // index in 256 color palette
                                // <<(osc.tuio.z osc.manos˚z) // redirect from OSC
        }
        line { // place holder for line drawing

            prev (x 0…1, y 0…1) // staring point of segment
            next (x 0…1, y 0…1) // endint point of segment
        }
        scroll {
            offset (x 0…1, y 0…1)
            shift (x -1…1 = 0, y -1…1 = 0)
        }
    }
    shader {
        _compute {
            type "compute"
            file "*.metal"
            on (0…1)
            buffer {
                version (0…1)
            }
        }
        melt : _compute {
            type "compute"
            file "cell.melt.metal"
            on (0…1)
            buffer {
                version (0…1)
            }
        }
        fred : _compute {
            type "compute"
            file "cell.fred.metal"
            on (0…1)
            buffer {
                version (0…1)

            }
        }
        gas : _compute {
            type "compute"
            file "cell.gas.metal"
            on (0…1)
            buffer {
                version (0…1)
            }
        }
        ave : _compute {
            type "compute"
            file "cell.ave.metal"
            on (0…1)
            buffer {
                version (0…1)
            }
        }
        mod : _compute {
            type "compute"
            file "cell.mod.metal"
            on (0…1)
            buffer {
                version (0…1)
            }
        }
        fade : _compute {
            type "compute"
            file "cell.fade.metal"
            on (0…1)
            buffer {
                version (0…1)
            }
        }
        slide : _compute {
            type "compute"
            file "cell.slide.metal"
            on (0…1)
            buffer {
                version (0…1)
            }
        }
        drift : _compute {
            type "compute"
            file "cell.drift.metal"
            on (0…1)
            buffer {
                version (0…1)
            }
        }
        tunl : _compute {
            type "compute"
            file "cell.tunl.metal"
            on (0…1)
            buffer {
                version (0…1)
            }
        }
        zha : _compute {
            type "compute"
            file "cell.zha.metal"
            on (0…1)
            buffer {
                version (0…1)
                bits (2…4 = 3)
            }
            repeat (11)
        }
        record {
            type "record"
            file "record.metal"
            on (0…1)
            buffer {
                version (0…1)
            }
        }
        camera {
            type "camera"
            file "cell.camera.metal"
            on (0…1)
            buffer {
                version (0…1)
            }
            flip (0…1)
        }
        camix {
            type "camix"
            file "cell.camix.metal"
            on (0…1)
            buffer {
                version (0…1)
            }
        }
        draws {
            type "draw"
            file "pipe.draws.metal"
            on (0…1)
            buffer {
                scroll (x 0…1 = 0.5, y 0…1 = 0.5)
            }
        }
        color {
            type "color"
            file "pipe.color.metal"
            buffer {
                bitplane (0…1)
            }
        }
        render {
            type "render"
            file "pipe.render.metal"
            buffer {
                clip (x 0, y 0, w 1080, h 1920)
                repeat (x, y)
                mirror (x, y)
            }
        }
    }
}
shader {
    model {
        cell {
            fade (val 0…1 = 0.5, on 1)
            ave (val 0…1 = 0.5, on 0)
            melt (val 0…1 = 0.5, on 0)
            tunl (seg 0…5 = 1, on 0)
            slide (seg 0…7 = 3, on 0)
            fred (seg 0…4 = 4, on 0)
            zha (seg 0…6 = 2, on 0) {
                repeat (11), bits (2…4 = 3)
            }
        }
        pipe {
            record (tog 0, on 0…1)
            camera (tog 0, on 0…1) {
                flip (tog)
            }
            camix (tog 0, on 0…1)
            scroll (x 0…1 = 0.5, y 0…1 = 0.5)
            render {
                offset (x 0, y 0)
                size (w 1080, h 1920)
                repeat (x, y)
                mirror (x, y)
            }
            color (val 0) {
                bitplane (val)
            }
        }
    }
    file }
midi { // musical instrument device interface

    input { // midi input

        note { // note on/off from 0 thru 127

            on (num 0…127, velo 0…127, chan 1…32, port 1…16, time 0)
            off (num 0…127, velo 0…127, chan 1…32, port 1…16, time 0)
        }
        controller (num 0…127, val 0…127, chan 1…32, port 1…16, time 0)
        afterTouch (num 0…127, val 0…127, chan 1…32, port 1…16, time 0)
        pitchBend (val 0…16384 = 8192, chan 1…32, port 1…16, time 0)
        programChange (num 0…255, chan 1…32, port 1…16, time 0) //1, 632, 255
    }
    output : input {
        note { // note on/off from 0 thru 127

            on (num 0…127, velo 0…127, chan 1…32, port 1…16, time 0)
            off (num 0…127, velo 0…127, chan 1…32, port 1…16, time 0)
        }
        controller (num 0…127, val 0…127, chan 1…32, port 1…16, time 0)
        afterTouch (num 0…127, val 0…127, chan 1…32, port 1…16, time 0)
        pitchBend (val 0…16384 = 8192, chan 1…32, port 1…16, time 0)
        programChange (num 0…255, chan 1…32, port 1…16, time 0) //1, 632, 255
    }
    cc {
        main {
            modWheel (num == 1, val, chan, time)
            volume (num == 7, val, chan, time)
            balance (num == 8, val, chan, time)
            panPosition (num == 10, val, chan, time)
            expression (num == 11, val, chan, time)
            controller (num in 32…63, val, chan, time) // controller 0…31
            portamento {
                time (num == 5, val, chan, time)
                amount (num == 84, val, chan, time)
            }
        }
        pedal {
            hold (num == 64, val, chan, time)
            porta (num == 65, val, chan, time)
            sosta (num == 66, val, chan, time)
            _soft (num == 67, val, chan, time)
            _legato (num == 68, val, chan, time)
            _hold2 (num == 69, val, chan, time)
        }
        _cc {
            _main2 {
                bankSelect (num == 0, val, chan, time)
                breathCtrl (num == 2, val, chan, time)
                footPedal (num == 4, val, chan, time)
                dataEntry (num == 6, val, chan, time)
                effectControl1 (num == 12, val, chan, time)
                effectControl2 (num == 13, val, chan, time)
            }
            _sound {
                soundVariation (num == 70, val, chan, time)
                resonance (num == 71, val, chan, time)
                soundReleaseTime (num == 72, val, chan, time)
                soundAttackTime (num == 73, val, chan, time)
                frequencyCutoff (num == 74, val, chan, time)
                timbre (num == 71, val, chan, time)
                brightness (num == 74, val, chan, time)
            }
            _button {
                button1 (num == 80, val, chan, time)
                button2 (num == 81, val, chan, time)
                button3 (num == 82, val, chan, time)
                button4 (num == 83, val, chan, time)
                decayor (num == 80, val, chan, time)
                hiPassFilter (num == 81, val, chan, time)
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
                reverbLevel (num == 91, val, chan, time)
                tremoloLevel (num == 92, val, chan, time)
                chorusLevel (num == 93, val, chan, time)
                detuneLevel (num == 94, val, chan, time)
                phaserLevel (num == 95, val, chan, time)
            }
            _parameter {
                dataButtonIncrement (num == 96, val, chan, time)
                dataButtonDecrement (num == 97, val, chan, time)
                nonregisteredParameterLSB (num == 98, val, chan, time)
                nonregisteredParameterMSB (num == 99, val, chan, time)
                registeredParameterLSB (num == 100, val, chan, time)
                registeredParameterMSB (num == 101, val, chan, time)
            }
            _soundControl {
                soundControl6 (num == 75, val, chan, time)
                soundControl7 (num == 76, val, chan, time)
                soundControl8 (num == 77, val, chan, time)
                soundControl9 (num == 78, val, chan, time)
                soundControl10 (num == 79, val, chan, time)
            }
            _undefined {
                undefined_3 (num == 3, val, chan, time)
                undefined_9 (num == 9, val, chan, time)
                undefined_14_31 (num in 14…31, val, chan, time)
                undefined_85_90 (num in 85…90, val, chan, time)
                undefined_102_119 (num in 102…119, val, chan, time)
            }
            _mode {
                allSoundOff (num == 120, val, chan, time)
                allControllersOff (num == 121, val, chan, time)
                localKeyboard (num == 122, val, chan, time)
                allNotesOff (num == 123, val, chan, time)
                monoOperation (num == 126, val, chan, time)
                polyMode (num == 127, val, chan, time)
            }
            _omni {
                omniModeOff (num == 124, val, chan, time)
                omniModeOn (num == 125, val, chan, time)
                omniMode (0…1) << (_cc._omni.omniModeOff(0) , _cc._omni.omniModeOn(1) )
            }
        }
    }
}
panel {
    _cell {
        base {
            type "cell"
            title "_cell"
            frame (x 0, y 0, w 250, h 130)
            icon "icon.ring.white.png"
        }
        controls {
            hide {
                type "panelx"
                title "hide"
                frame (x 0, y 0, w 40, h 40)
                icon "icon.thumb.X.png"
                value (0…1)
            }
            ruleOn {
                type "panelon"
                title "Active"
                frame (x 202, y 4, w 40, h 32)
                icon "icon.ring.white.png"
                value (0…1) >> (controls.ruleOn.value(0) , controls.ruleOn.value(0) , controls.ruleOn.value(0) , controls.ruleOn.value(0) , controls.ruleOn.value(0) , controls.ruleOn.value(0) , controls.ruleOn.value(0) )
                lag (0)
            }
            version {
                type "segment"
                title "Version"
                frame (x 10, y 44, w 192, h 32)
                value (0…1 = 1)
                user >> controls.ruleOn.value(1) }
            lock {
                type "switch"
                title "Lock"
                frame (x 210, y 44, w 32, h 32)
                icon {
                    off "icon.lock.closed.png"
                    on "icon.lock.open.png"
                }
                value (0…1)
                lag (0)
            }
            bitplane {
                type "slider"
                title "Bit Plane"
                frame (x 10, y 84, w 192, h 32)
                icon "icon.pearl.white.png"
                value (0…1) >> color.buffer.bitplane
            }
            fillZero { // 00ffffde

                type "trigger"
                title "Fill Zeros"
                frame (x 210, y 44, w 32, h 32)
                icon "icon.drop.gray.png"
                value (0…1) >> draw.screen.fillZero
            }
            fillOne { // ffffffde

                type "trigger"
                title "Fill Ones"
                frame (x 210, y 84, w 32, h 32)
                icon "icon.drop.gray.png"
                value (0…1) >> draw.screen.fillOne
            }
        }
    }
    _camera {
        base {
            type "cell"
            title "_cell" // name
            frame (x 0, y 0, w 250, h 130)
            icon "icon.ring.white.png"
        }
        controls {
            hide {
                type "panelx"
                title "hide"
                frame (x 0, y 0, w 40, h 40)
                icon "icon.thumb.X.png"
                value (0…1)
            }
            cameraOne {
                type "panelon"
                title "Camera Cell"
                frame (x 202, y 4, w 40, h 32)
                icon "icon.camera.png"
                value (0…1)
                lag (0)
            }
            version {
                type "segment"
                title "Version"
                frame (x 10, y 44, w 184, h 32)
                value (0…1 = 0.5)
                user >> ruleOn.value (1) }
            cameraTwo {
                type "panelon"
                title "Camera Mix"
                frame (x 202, y 44, w 40, h 32)
                icon "icon.camera.flip.png"
                value (0…1)
                lag (0)
            }
            bitplane {
                type "slider"
                title "Bit Plane"
                frame (x 10, y 84, w 184, h 32)
                icon "icon.pearl.white.png"
                value (0…1)
            }
            facing {
                type "switch"
                title "Lock"
                frame (x 202, y 84, w 40, h 32)
                icon "icon.camera.flip.png"
                value (0…1) >> shader.camera.flip
                lag (0)
            }
        }
    }
    cell {
        fade : _cell {
            base {
                type "cell"
                title "Fade"
                frame (x 0, y 0, w 250, h 130)
                icon "icon.cell.fade.png"
            }
            controls {
                hide {
                    type "panelx"
                    title "hide"
                    frame (x 0, y 0, w 40, h 40)
                    icon "icon.thumb.X.png"
                    value (0…1)
                }
                ruleOn {
                    type "panelon"
                    title "Active"
                    frame (x 202, y 4, w 40, h 32)
                    icon "icon.cell.fade.png"
                    value (0…1) >> (controls.ruleOn.value(0) , controls.ruleOn.value(0) , controls.ruleOn.value(0) , controls.ruleOn.value(0) , controls.ruleOn.value(0) , controls.ruleOn.value(0) , controls.ruleOn.value(0) , shader.fade.on)
                    lag (0)
                }
                version {
                    type "segment"
                    title "Version"
                    frame (x 10, y 44, w 192, h 32)
                    value (0…1 = 0.5) >> fade.buffer.version
                    user >> controls.ruleOn.value(1) }
                lock {
                    type "switch"
                    title "Lock"
                    frame (x 210, y 44, w 32, h 32)
                    icon {
                        off "icon.lock.closed.png"
                        on "icon.lock.open.png"
                    }
                    value (0…1)
                    lag (0)
                }
                bitplane {
                    type "slider"
                    title "Bit Plane"
                    frame (x 10, y 84, w 192, h 32)
                    icon "icon.pearl.white.png"
                    value (0…1 = 0.2) >> color.buffer.bitplane
                }
                fillZero { // 00ffffde

                    type "trigger"
                    title "Fill Zeros"
                    frame (x 210, y 44, w 32, h 32)
                    icon "icon.drop.gray.png"
                    value (0…1) >> draw.screen.fillZero
                }
                fillOne { // ffffffde

                    type "trigger"
                    title "Fill Ones"
                    frame (x 210, y 84, w 32, h 32)
                    icon "icon.drop.gray.png"
                    value (0…1) >> draw.screen.fillOne
                }
            }
        }
        ave : _cell {
            base {
                type "cell"
                title "Average"
                frame (x 0, y 0, w 250, h 130)
                icon "icon.cell.ave.png"
            }
            controls {
                hide {
                    type "panelx"
                    title "hide"
                    frame (x 0, y 0, w 40, h 40)
                    icon "icon.thumb.X.png"
                    value (0…1)
                }
                ruleOn {
                    type "panelon"
                    title "Active"
                    frame (x 202, y 4, w 40, h 32)
                    icon "icon.cell.ave.png"
                    value (0…1) >> (controls.ruleOn.value(0) , controls.ruleOn.value(0) , controls.ruleOn.value(0) , controls.ruleOn.value(0) , controls.ruleOn.value(0) , controls.ruleOn.value(0) , controls.ruleOn.value(0) , shader.ave.on)
                    lag (0)
                }
                version {
                    type "segment"
                    title "Version"
                    frame (x 10, y 44, w 192, h 32)
                    value (0…1 = 0.4) >> ave.buffer.version
                    user >> controls.ruleOn.value(1) }
                lock {
                    type "switch"
                    title "Lock"
                    frame (x 210, y 44, w 32, h 32)
                    icon {
                        off "icon.lock.closed.png"
                        on "icon.lock.open.png"
                    }
                    value (0…1)
                    lag (0)
                }
                bitplane {
                    type "slider"
                    title "Bit Plane"
                    frame (x 10, y 84, w 192, h 32)
                    icon "icon.pearl.white.png"
                    value (0…1) >> color.buffer.bitplane
                }
                fillZero { // 00ffffde

                    type "trigger"
                    title "Fill Zeros"
                    frame (x 210, y 44, w 32, h 32)
                    icon "icon.drop.gray.png"
                    value (0…1) >> draw.screen.fillZero
                }
                fillOne { // ffffffde

                    type "trigger"
                    title "Fill Ones"
                    frame (x 210, y 84, w 32, h 32)
                    icon "icon.drop.gray.png"
                    value (0…1) >> draw.screen.fillOne
                }
            }
        }
        melt : _cell {
            base {
                type "cell"
                title "Melt"
                frame (x 0, y 0, w 250, h 130)
                icon "icon.cell.melt.png"
            }
            controls {
                hide {
                    type "panelx"
                    title "hide"
                    frame (x 0, y 0, w 40, h 40)
                    icon "icon.thumb.X.png"
                    value (0…1)
                }
                ruleOn {
                    type "panelon"
                    title "Active"
                    frame (x 202, y 4, w 40, h 32)
                    icon "icon.cell.melt.png"
                    value (0…1) >> (controls.ruleOn.value(0) , controls.ruleOn.value(0) , controls.ruleOn.value(0) , controls.ruleOn.value(0) , controls.ruleOn.value(0) , controls.ruleOn.value(0) , controls.ruleOn.value(0) , shader.melt.on)
                    lag (0)
                }
                version {
                    type "segment"
                    title "Version"
                    frame (x 10, y 44, w 192, h 32)
                    value (0…1 = 1) >> melt.buffer.version
                    user >> controls.ruleOn.value(1) }
                lock {
                    type "switch"
                    title "Lock"
                    frame (x 210, y 44, w 32, h 32)
                    icon {
                        off "icon.lock.closed.png"
                        on "icon.lock.open.png"
                    }
                    value (0…1)
                    lag (0)
                }
                bitplane {
                    type "slider"
                    title "Bit Plane"
                    frame (x 10, y 84, w 192, h 32)
                    icon "icon.pearl.white.png"
                    value (0…1) >> color.buffer.bitplane
                }
                fillZero { // 00ffffde

                    type "trigger"
                    title "Fill Zeros"
                    frame (x 210, y 44, w 32, h 32)
                    icon "icon.drop.gray.png"
                    value (1.67772e+07) >> draw.screen.fillZero
                }
                fillOne { // ffffffde

                    type "trigger"
                    title "Fill Ones"
                    frame (x 210, y 84, w 32, h 32)
                    icon "icon.drop.gray.png"
                    value (1.67772e+07) >> draw.screen.fillOne
                }
            }
        }
        tunl : _cell {
            base {
                type "cell"
                title "Time Tunnel"
                frame (x 0, y 0, w 250, h 130)
                icon "icon.cell.tunl.png"
            }
            controls {
                hide {
                    type "panelx"
                    title "hide"
                    frame (x 0, y 0, w 40, h 40)
                    icon "icon.thumb.X.png"
                    value (0…1)
                }
                ruleOn {
                    type "panelon"
                    title "Active"
                    frame (x 202, y 4, w 40, h 32)
                    icon "icon.cell.tunl.png"
                    value (0…1) >> (controls.ruleOn.value(0) , controls.ruleOn.value(0) , controls.ruleOn.value(0) , controls.ruleOn.value(0) , controls.ruleOn.value(0) , controls.ruleOn.value(0) , controls.ruleOn.value(0) , shader.tunl.on)
                    lag (0)
                }
                version {
                    type "segment"
                    title "Version"
                    frame (x 10, y 44, w 192, h 32)
                    value (0…1 = 1) >> tunl.buffer.version
                    user >> controls.ruleOn.value(1) }
                lock {
                    type "switch"
                    title "Lock"
                    frame (x 210, y 44, w 32, h 32)
                    icon {
                        off "icon.lock.closed.png"
                        on "icon.lock.open.png"
                    }
                    value (0…1)
                    lag (0)
                }
                bitplane {
                    type "slider"
                    title "Bit Plane"
                    frame (x 10, y 84, w 192, h 32)
                    icon "icon.pearl.white.png"
                    value (0…1) >> color.buffer.bitplane
                }
                fillZero { // 00ffffde

                    type "trigger"
                    title "Fill Zeros"
                    frame (x 210, y 44, w 32, h 32)
                    icon "icon.drop.gray.png"
                    value (0…1) >> draw.screen.fillZero
                }
                fillOne { // ffffffde

                    type "trigger"
                    title "Fill Ones"
                    frame (x 210, y 84, w 32, h 32)
                    icon "icon.drop.gray.png"
                    value (0…1) >> draw.screen.fillOne
                }
            }
        }
        zha : _cell {
            base {
                type "cell"
                title "Zhabatinski"
                frame (x 0, y 0, w 250, h 130)
                icon "icon.cell.zha.png"
            }
            controls {
                hide {
                    type "panelx"
                    title "hide"
                    frame (x 0, y 0, w 40, h 40)
                    icon "icon.thumb.X.png"
                    value (0…1)
                }
                ruleOn {
                    type "panelon"
                    title "Active"
                    frame (x 202, y 4, w 40, h 32)
                    icon "icon.cell.zha.png"
                    value (0…1) >> (controls.ruleOn.value(0) , controls.ruleOn.value(0) , controls.ruleOn.value(0) , controls.ruleOn.value(0) , controls.ruleOn.value(0) , controls.ruleOn.value(0) , controls.ruleOn.value(0) , shader.zha.on)
                    lag (0)
                }
                version {
                    type "segment"
                    title "Version"
                    frame (x 10, y 44, w 192, h 32)
                    value (0…1 = 0.75) >> zha.buffer.version
                    user >> controls.ruleOn.value(1) }
                lock {
                    type "switch"
                    title "Lock"
                    frame (x 210, y 44, w 32, h 32)
                    icon {
                        off "icon.lock.closed.png"
                        on "icon.lock.open.png"
                    }
                    value (0…1)
                    lag (0)
                }
                bitplane {
                    type "slider"
                    title "Bit Plane"
                    frame (x 10, y 84, w 192, h 32)
                    icon "icon.pearl.white.png"
                    value (0…1) >> color.buffer.bitplane
                }
                fillZero { // 00ffffde

                    type "trigger"
                    title "Fill Zeros"
                    frame (x 210, y 44, w 32, h 32)
                    icon "icon.drop.gray.png"
                    value (0…1) >> draw.screen.fillZero
                }
                fillOne { // ffffffde

                    type "trigger"
                    title "Fill Ones"
                    frame (x 210, y 84, w 32, h 32)
                    icon "icon.drop.gray.png"
                    value (0…1) >> draw.screen.fillOne
                }
            }
        }
        slide : _cell {
            base {
                type "cell"
                title "Slide Bit Planes"
                frame (x 0, y 0, w 250, h 130)
                icon "icon.cell.slide.png"
            }
            controls {
                hide {
                    type "panelx"
                    title "hide"
                    frame (x 0, y 0, w 40, h 40)
                    icon "icon.thumb.X.png"
                    value (0…1)
                }
                ruleOn {
                    type "panelon"
                    title "Active"
                    frame (x 202, y 4, w 40, h 32)
                    icon "icon.cell.slide.png"
                    value (0…1) >> (controls.ruleOn.value(0) , controls.ruleOn.value(0) , controls.ruleOn.value(0) , controls.ruleOn.value(0) , controls.ruleOn.value(0) , controls.ruleOn.value(0) , controls.ruleOn.value(0) , shader.slide.on)
                    lag (0)
                }
                version {
                    type "segment"
                    title "Version"
                    frame (x 10, y 44, w 192, h 32)
                    value (0…1 = 1) >> slide.buffer.version
                    user >> controls.ruleOn.value(1) }
                lock {
                    type "switch"
                    title "Lock"
                    frame (x 210, y 44, w 32, h 32)
                    icon {
                        off "icon.lock.closed.png"
                        on "icon.lock.open.png"
                    }
                    value (0…1)
                    lag (0)
                }
                bitplane {
                    type "slider"
                    title "Bit Plane"
                    frame (x 10, y 84, w 192, h 32)
                    icon "icon.pearl.white.png"
                    value (0…1) >> color.buffer.bitplane
                }
                fillZero { // 00ffffde

                    type "trigger"
                    title "Fill Zeros"
                    frame (x 210, y 44, w 32, h 32)
                    icon "icon.drop.gray.png"
                    value (0…1) >> draw.screen.fillZero
                }
                fillOne { // ffffffde

                    type "trigger"
                    title "Fill Ones"
                    frame (x 210, y 84, w 32, h 32)
                    icon "icon.drop.gray.png"
                    value (0…1) >> draw.screen.fillOne
                }
            }
        }
        fred : _cell {
            base {
                type "cell"
                title "Fredkin"
                frame (x 0, y 0, w 250, h 130)
                icon "icon.cell.fred.png"
            }
            controls {
                hide {
                    type "panelx"
                    title "hide"
                    frame (x 0, y 0, w 40, h 40)
                    icon "icon.thumb.X.png"
                    value (0…1)
                }
                ruleOn {
                    type "panelon"
                    title "Active"
                    frame (x 202, y 4, w 40, h 32)
                    icon "icon.cell.fred.png"
                    value (0…1) >> (controls.ruleOn.value(0) , controls.ruleOn.value(0) , controls.ruleOn.value(0) , controls.ruleOn.value(0) , controls.ruleOn.value(0) , controls.ruleOn.value(0) , controls.ruleOn.value(0) , shader.fred.on)
                    lag (0)
                }
                version {
                    type "segment"
                    title "Version"
                    frame (x 10, y 44, w 192, h 32)
                    value (0…1 = 0.5) >> fred.buffer.version
                    user >> controls.ruleOn.value(1) }
                lock {
                    type "switch"
                    title "Lock"
                    frame (x 210, y 44, w 32, h 32)
                    icon {
                        off "icon.lock.closed.png"
                        on "icon.lock.open.png"
                    }
                    value (0…1)
                    lag (0)
                }
                bitplane {
                    type "slider"
                    title "Bit Plane"
                    frame (x 10, y 84, w 192, h 32)
                    icon "icon.pearl.white.png"
                    value (0…1) >> color.buffer.bitplane
                }
                fillZero { // 00ffffde

                    type "trigger"
                    title "Fill Zeros"
                    frame (x 210, y 44, w 32, h 32)
                    icon "icon.drop.gray.png"
                    value (0…1) >> draw.screen.fillZero
                }
                fillOne { // ffffffde

                    type "trigger"
                    title "Fill Ones"
                    frame (x 210, y 84, w 32, h 32)
                    icon "icon.drop.gray.png"
                    value (0…1) >> draw.screen.fillOne
                }
            }
        }
        brush {
            base {
                type "brush"
                title "Brush"
                frame (x 0, y 0, w 262, h 120)
                icon "icon.cell.brush.png"
            }
            controls {
                hide {
                    type "panelx"
                    title "hide"
                    frame (x 0, y 0, w 40, h 40)
                    icon "icon.thumb.X.png"
                    value (0…1)
                }
                brushSize {
                    type "slider"
                    title "Size"
                    frame (x 10, y 40, w 192, h 32)
                    value (0…1) <> draw.brush.size
                    user >> controls.brushPress.value(0) }
                brushPress {
                    type "switch"
                    title "Pressure"
                    frame (x 210, y 40, w 44, h 32)
                    icon "icon.pen.press.png"
                    value (0…1) <> draw.brush.press
                }
                bitplane {
                    type "slider"
                    title "Bit Plane"
                    frame (x 10, y 80, w 192, h 32)
                    icon "icon.pearl.white.png"
                    value (0…1) >> color.buffer.bitplane
                }
                fillOne {
                    type "trigger"
                    title "clear 0xFFFF"
                    frame (x 210, y 80, w 32, h 32)
                    icon "icon.drop.gray.png"
                    value (0…1) >> draw.screen.fillOne
                }
            }
        }
        scroll {
            base {
                type "cell"
                title "Scroll"
                frame (x 0, y 0, w 192, h 180)
                icon "icon.scroll.png"
            }
            controls {
                scrollOn {
                    type "panelon"
                    title "Active"
                    frame (x 148, y 6, w 40, h 32)
                    icon "icon.scroll.png"
                    value (0…1 = 0)
                    lag (0)
                    user >> (controls.scrollBox.value(x 0.5, y 0.5) , controls.brushTilt.value(0) ) }
                hide {
                    type "panelx"
                    title "hide"
                    frame (x 0, y 0, w 40, h 40)
                    icon "icon.thumb.X.png"
                    value (0…1)
                }
                scrollBox {
                    type "box"
                    title "Screen Scroll"
                    frame (x 8, y 44, w 128, h 128)
                    radius (10)
                    tap2 (x -1, y -1)
                    lag (0)
                    value (x 0…1 = 0.5, y 0…1 = 0.5) <> sky.input.azimuth>> draws.buffer.scroll
                    user >> (controls.brushTilt.value(0) , controls.scrollOn.value(1) ) }
                brushTilt {
                    type "switch"
                    title "Brush Tilt"
                    frame (x 144, y 62, w 40, h 32)
                    icon "icon.pen.tilt.png"
                    value (0…1) <> sky.input.tilt
                }
                fillZero {
                    type "trigger"
                    title "Fill Zero"
                    frame (x 148, y 116, w 32, h 32)
                    icon "icon.drop.clear.png"
                    value (0…1) >> draw.screen.fillZero
                }
            }
        }
        camera : _camera {
            base {
                type "camera"
                title "Camera" // name
                frame (x 0, y 0, w 250, h 130)
                icon "icon.camera.png"
            }
            controls {
                hide {
                    type "panelx"
                    title "hide"
                    frame (x 0, y 0, w 40, h 40)
                    icon "icon.thumb.X.png"
                    value (0…1)
                }
                cameraOne {
                    type "panelon"
                    title "Camera Cell"
                    frame (x 202, y 4, w 40, h 32)
                    icon "icon.camera.png"
                    value (0…1) >> shader.camera.on
                    lag (0)
                }
                version {
                    type "segment"
                    title "Version"
                    frame (x 10, y 44, w 184, h 32)
                    value (0…1 = 0.5) >> camix.buffer.version
                    user >> ruleOn.value (1) }
                cameraTwo {
                    type "panelon"
                    title "Camera Mix"
                    frame (x 202, y 44, w 40, h 32)
                    icon "icon.camera.flip.png"
                    value (0…1) >> shader.camix.on
                    lag (0)
                }
                bitplane {
                    type "slider"
                    title "Bit Plane"
                    frame (x 10, y 84, w 184, h 32)
                    icon "icon.pearl.white.png"
                    value (0…1) >> color.buffer.bitplane
                }
                facing {
                    type "switch"
                    title "Lock"
                    frame (x 202, y 84, w 40, h 32)
                    icon "icon.camera.flip.png"
                    value (0…1) >> shader.camera.flip
                    lag (0)
                }
            }
        }
        speed {
            restart >> controls.speed.value(60) , base {
                type "cell"
                title "Speed" // name
                frame (x 0, y 0, w 212, h 104)
                icon "icon.speed.png"
            }
            controls {
                speedOn {
                    type "panelon"
                    title "Active"
                    frame (x 154, y 6, w 48, h 32)
                    icon "icon.speed.png"
                    value (0…1) >> sky.main.run
                    user >> scrollBox.value (x 0.5, y 0.5) lag (0)
                }
                hide {
                    type "panelx"
                    title "hide"
                    frame (x 0, y 0, w 40, h 40)
                    icon "icon.thumb.X.png"
                    value (0…1)
                }
                speed {
                    type "slider"
                    title "Frames per second"
                    frame (x 10, y 50, w 192, h 44)
                    icon "icon.pearl.white.png"
                    value (1…60 = 60) <> sky.main.fps
                    user >> controls.speedOn.value(1) }
            }
        }
    }
    shader {
        color {
            base {
                type "color"
                title "Color"
                frame (x 0, y 0, w 250, h 130)
                icon "icon.pal.main.png"
            }
            controls {
                hide {
                    type "panelx"
                    title "hide"
                    frame (x 0, y 0, w 40, h 40)
                    icon "icon.thumb.X.png"
                    value (0…1)
                }
                palFade {
                    type "slider"
                    title "Palette Cross Fade"
                    frame (x 10, y 44, w 192, h 32)
                    icon "icon.pearl.white.png"
                    value (0…1) <> sky.color.xfade
                    lag (0)
                }
                bitplane {
                    type "slider"
                    title "Bit Plane"
                    frame (x 10, y 84, w 192, h 32)
                    icon "icon.pearl.white.png"
                    value (0…1) >> color.buffer.bitplane
                }
                fillOne {
                    type "trigger"
                    title "Fill Ones"
                    frame (x 210, y 84, w 32, h 32)
                    icon "icon.drop.gray.png"
                    value (0…1) >> draw.screen.fillOne
                }
            }
        }
        tile {
            base {
                type "shader"
                title "Tile"
                frame (x 0, y 0, w 230, h 170)
                icon "icon.shader.tile.png"
            }
            controls {
                hide {
                    type "panelx"
                    title "hide"
                    frame (x 0, y 0, w 40, h 40)
                    icon "icon.thumb.X.png"
                    value (0…1)
                }
                tileOn {
                    type "panelon"
                    title "Active"
                    frame (x 174, y 6, w 40, h 32)
                    icon "icon.shader.tile.png"
                    value (0…1)
                    user >> controls.repeatBox.value(x 0, y 0) lag (0)
                }
                repeatBox {
                    type "box"
                    title "Repeat"
                    frame (x 10, y 40, w 120, h 120)
                    radius (10)
                    tap2 (x -1, y -1)
                    lag (0)
                    user (0…1 = 1) >> controls.tileOn.value(1)
                    value (x 0…1, y 0…1) >> render.buffer.repeat
                }
                mirrorBox {
                    type "box"
                    title "Mirror"
                    frame (x 140, y 60, w 80, h 80)
                    radius (10)
                    tap2 (x 1, y 1)
                    lag (0)
                    user (0…1 = 1)
                    value (x 0…1, y 0…1) >> render.buffer.mirror
                }
            }
        }
    }
    record {
        base {
            type "record"
            title "Record"
            frame (x 0, y 0, w 250, h 130)
            icon "icon.record.png"
        }
        controls {
            hide {
                type "panelx"
                title "hide"
                frame (x 0, y 0, w 40, h 40)
                icon "icon.thumb.X.png"
                value (0…1)
            }
            ruleOn {
                type "panelon"
                title "Active"
                frame (x 202, y 4, w 40, h 32)
                icon "icon.record.png"
                value (0…1) >> shader.record.on
                lag (0)
            }
            version {
                type "segment"
                title "Version"
                frame (x 10, y 44, w 192, h 32)
                value (0…1 = 0.5) >> record.buffer.version
                user >> controls.ruleOn.value(1) }
            lock {
                type "switch"
                title "Lock"
                frame (x 210, y 44, w 32, h 32)
                icon "icon.camera.flip.png"
                value >> sky.shader.record.flip lag (0)
            }
            bitplane {
                type "slider"
                title "Bit Plane"
                frame (x 10, y 84, w 192, h 32)
                icon "icon.pearl.white.png"
                value (0…1 = 0.2)
            }
            fillZero {
                type "trigger"
                title "Fill Zeros"
                frame (x 210, y 44, w 32, h 32)
                icon "icon.drop.gray.png"
                value (0…1) >> draw.screen.fillZero
            }
            fillOne {
                type "trigger"
                title "Fill Ones"
                frame (x 210, y 84, w 32, h 32)
                icon "icon.drop.gray.png"
                value (0…1) >> draw.screen.fillOne
            }
        }
    }
    }
