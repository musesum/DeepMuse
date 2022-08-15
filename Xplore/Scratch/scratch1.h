sky { // visual music program


    main { // main controls


        frame (201) // frame counter
        fps (1…60 = 208920) // frames per second
        run (0) // currently running
    }
    pipeline { // default metal pipeline at atartup
        draw "draw" // drawing layer
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
        xfade (0…1 = 0) // cross fade between pal0 and pal1
    }
    input { // phone and tablet pencil input



        azimuth (x -0.2…0.2, y -0.2…0.2) // pen tilt

        accel (x -0.3…0.3, y -0.3…0.3, z -0.3…0.3) { // accelerometer


            on (0…1)
        }
        radius (1…92 = 3.30319) // finger silhouette
        tilt (0…1) // use tilt
        force (0…0.5) >> draw.brush.size// pen pressure

    }
    draw { // draw on metal layer


        screen { // fill 32 bit universe


            fillZero (0) // all zeros 0x00000000
            fillOne (0) // all ones 0xFFFFFFFF
        }
        brush { // type of brush and range


            type "dot" // draw a circle
            size (1…64 = 3.30319) // range of radius
            press (0…1 = 0) // pressure changes size
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
            flip (0…1)
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
            flip (0…1)
        }
        draws {
            type "draw"
            file "pipe.draws.metal"
            on (0…1)
            buffer {
                scroll (x 0…1 = 0, y 0…1 = 0)
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
                repeat (x 0…1, y 0…1)
                mirror (x 0…1, y 0…1)
            }
        }
    }
}
midi panel {
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
                value (0…1) >> controls.ruleOn.value(0)
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

                // 00ffffde

                // 00ffffde

                // 00ffffde

                // 00ffffde

                // 00ffffde

                // 00ffffde

                // 00ffffde


                type "trigger"
                title "Fill Zeros"
                frame (x 210, y 44, w 32, h 32)
                icon "icon.drop.gray.png"
                value (0…1) >> draw.screen.fillZero
            }
            fillOne { // ffffffde

                // ffffffde

                // ffffffde

                // ffffffde

                // ffffffde

                // ffffffde

                // ffffffde

                // ffffffde


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
                          // name
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
                    value (0…1) >> controls.ruleOn.value(0)
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

                    // 00ffffde

                    // 00ffffde

                    // 00ffffde

                    // 00ffffde

                    // 00ffffde

                    // 00ffffde

                    // 00ffffde


                    type "trigger"
                    title "Fill Zeros"
                    frame (x 210, y 44, w 32, h 32)
                    icon "icon.drop.gray.png"
                    value (0…1) >> draw.screen.fillZero
                }
                fillOne { // ffffffde

                    // ffffffde

                    // ffffffde

                    // ffffffde

                    // ffffffde

                    // ffffffde

                    // ffffffde

                    // ffffffde


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
                    value (0…1) >> controls.ruleOn.value(0)
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

                    // 00ffffde

                    // 00ffffde

                    // 00ffffde

                    // 00ffffde

                    // 00ffffde

                    // 00ffffde

                    // 00ffffde


                    type "trigger"
                    title "Fill Zeros"
                    frame (x 210, y 44, w 32, h 32)
                    icon "icon.drop.gray.png"
                    value (0…1) >> draw.screen.fillZero
                }
                fillOne { // ffffffde

                    // ffffffde

                    // ffffffde

                    // ffffffde

                    // ffffffde

                    // ffffffde

                    // ffffffde

                    // ffffffde


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
                    value (0…1) >> controls.ruleOn.value(0)
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

                    // 00ffffde

                    // 00ffffde

                    // 00ffffde

                    // 00ffffde

                    // 00ffffde

                    // 00ffffde

                    // 00ffffde


                    type "trigger"
                    title "Fill Zeros"
                    frame (x 210, y 44, w 32, h 32)
                    icon "icon.drop.gray.png"
                    value (1.67772e+07) >> draw.screen.fillZero
                }
                fillOne { // ffffffde

                    // ffffffde

                    // ffffffde

                    // ffffffde

                    // ffffffde

                    // ffffffde

                    // ffffffde

                    // ffffffde


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
                    value (0…1) >> controls.ruleOn.value(0)
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

                    // 00ffffde

                    // 00ffffde

                    // 00ffffde

                    // 00ffffde

                    // 00ffffde

                    // 00ffffde

                    // 00ffffde


                    type "trigger"
                    title "Fill Zeros"
                    frame (x 210, y 44, w 32, h 32)
                    icon "icon.drop.gray.png"
                    value (0…1) >> draw.screen.fillZero
                }
                fillOne { // ffffffde

                    // ffffffde

                    // ffffffde

                    // ffffffde

                    // ffffffde

                    // ffffffde

                    // ffffffde

                    // ffffffde


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
                    value (0…1) >> controls.ruleOn.value(0)
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

                    // 00ffffde

                    // 00ffffde

                    // 00ffffde

                    // 00ffffde

                    // 00ffffde

                    // 00ffffde

                    // 00ffffde


                    type "trigger"
                    title "Fill Zeros"
                    frame (x 210, y 44, w 32, h 32)
                    icon "icon.drop.gray.png"
                    value (0…1) >> draw.screen.fillZero
                }
                fillOne { // ffffffde

                    // ffffffde

                    // ffffffde

                    // ffffffde

                    // ffffffde

                    // ffffffde

                    // ffffffde

                    // ffffffde


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
                    value (0…1) >> controls.ruleOn.value(0)
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

                    // 00ffffde

                    // 00ffffde

                    // 00ffffde

                    // 00ffffde

                    // 00ffffde

                    // 00ffffde

                    // 00ffffde


                    type "trigger"
                    title "Fill Zeros"
                    frame (x 210, y 44, w 32, h 32)
                    icon "icon.drop.gray.png"
                    value (0…1) >> draw.screen.fillZero
                }
                fillOne { // ffffffde

                    // ffffffde

                    // ffffffde

                    // ffffffde

                    // ffffffde

                    // ffffffde

                    // ffffffde

                    // ffffffde


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
                    value (0…1) >> controls.ruleOn.value(0)
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

                    // 00ffffde

                    // 00ffffde

                    // 00ffffde

                    // 00ffffde

                    // 00ffffde

                    // 00ffffde

                    // 00ffffde


                    type "trigger"
                    title "Fill Zeros"
                    frame (x 210, y 44, w 32, h 32)
                    icon "icon.drop.gray.png"
                    value (0…1) >> draw.screen.fillZero
                }
                fillOne { // ffffffde

                    // ffffffde

                    // ffffffde

                    // ffffffde

                    // ffffffde

                    // ffffffde

                    // ffffffde

                    // ffffffde


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
                    value (0…1 = 1)
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
                    value (x 0…1 = 0, y 0…1 = 0) <> sky.input.azimuth
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
                               // name
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
                    value (1…60 = 208920) <> sky.main.fps
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
                value >> shader.record.flip lag (0)
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
