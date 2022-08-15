sky { // visual music program

    main { // main controls

        frame (0) // frame counter
        fps (1…60 = 60) // frames per second
        run (1) // currently running
    }
    pipeline { // default metal pipeline at atartup

        draw "draw" // drawing layer
        ave "compute" // compute layer
        color "color" // colorizing layer
        render "render" // render layer al
    }
    dock { // list of panel items to put in dock

        fader ave (1)
        melt tunl zha slide fred brush color scroll tile speed camera record }
    color { // false color mapping palette

        pal0 "roygbik" // palette 0: (r)ed (o)range (y)ellow …
        pal1 "wKZ" // palette 1: (w)hite blac(K) fractali(Z)e
        xfade (0…1 = 0.5) // cross fade between pal0 and pal1
    }
    input { // phone and tablet pencil input

        azimuth (x -0.2…0.2, y -0.2…0.2) // pen tilt
        accel (x -0.3…0.3, y -0.3…0.3, z -0.3…0.3) { // accelerometer
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
    }
}
shader {
    model {
        cell {
            fade (val 0…1 = 0.5) {
                on (0…1) >> (cell.fade.on(0) , cell.ave.on(0) , cell.melt.on(0) , cell.tunl.on(0) , cell.slide.on(0) , cell.fred.on(0) , cell.zha.on(0) )
            }
            ave (val 0…1 = 0.5) {
                on (0…1) >> (cell.fade.on(0) , cell.ave.on(0) , cell.melt.on(0) , cell.tunl.on(0) , cell.slide.on(0) , cell.fred.on(0) , cell.zha.on(0) )
            }
            melt (val 0…1 = 0.5) {
                on (0…1) >> (cell.fade.on(0) , cell.ave.on(0) , cell.melt.on(0) , cell.tunl.on(0) , cell.slide.on(0) , cell.fred.on(0) , cell.zha.on(0) )
            }
            tunl (seg 0…5 = 1) {
                on (0…1) >> (cell.fade.on(0) , cell.ave.on(0) , cell.melt.on(0) , cell.tunl.on(0) , cell.slide.on(0) , cell.fred.on(0) , cell.zha.on(0) )
            }
            slide (seg 0…7 = 3) {
                on (0…1) >> (cell.fade.on(0) , cell.ave.on(0) , cell.melt.on(0) , cell.tunl.on(0) , cell.slide.on(0) , cell.fred.on(0) , cell.zha.on(0) )
            }
            fred (seg 0…4 = 4) {
                on (0…1) >> (cell.fade.on(0) , cell.ave.on(0) , cell.melt.on(0) , cell.tunl.on(0) , cell.slide.on(0) , cell.fred.on(0) , cell.zha.on(0) )
            }
            zha (seg 0…6 = 2, bits 2…4 = 3) {
                on (0…1) >> (cell.fade.on(0) , cell.ave.on(0) , cell.melt.on(0) , cell.tunl.on(0) , cell.slide.on(0) , cell.fred.on(0) , cell.zha.on(0) )
                loops (11)
            }
        }
        pipe {
            draw (x 0…1 = 0.5, y 0…1 = 0.5)
            record (tog 0)
            camera (tog 0) {
                flip (tog 0)
            }
            camix (tog 0)
            render {
                frame (x 0, y 0, w 1080, h 1920)
                repeat (x, y)
                mirror (x, y)
            }
            color (val 0…1 = 0.3) // bitplane
        }
    }
    file {
        cell {
            fade ("cell.fader.metal")
            ave ("cell.ave.metal")
            melt ("cell.melt.metal")
            tunl ("cell.tunl.metal")
            slide ("cell.slide.metal")
            fred ("cell.fred.metal")
            zha ("cell.zha.metal")
        }
        pipe {
            record
            camera ("cell.camera.metal")
            camix ("cell.camix.metal")
            draw ("pipe.draw.metal")
            render ("pipe.render.metal")
            color ("pipe.color.metal")
        }
    }
}

