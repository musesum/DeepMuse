sky { // visual music program

    main { // main controls

        frame (368) // frame counter
        fps (1…60:60) // frames per second
        run (1) // currently running
    }
    pipeline { // default metal pipeline at atartup

        draw » // drawing layer
        ave "compute" // compute layer
        color "color" // colorizing layer
        render "render" // render layer al
    }
    color { // false color mapping palette

        pal0 "roygbik" // palette 0: (r)ed (o)range (y)ellow …
        pal1 "wKZ" // palette 1: (w)hite blac(K) fractali(Z)e
        xfade (0…1 = 0.5:0.2)
    }
    input { // phone and tablet pencil input
        azimuth (x -0.2…0.2, y -0.2…0.2) // pen tilt
        accel (x -0.3…0.3, y -0.3…0.3, z -0.3…0.3) { // accelerometer
            on (0…1)
        }
        radius (1…92:24.2351) // finger silhouette
        tilt (0…1) // use tilt
        force (0…0.5) >> draw.brush.size // pen pressure
    }
    draw { // draw on metal layer

        screen { // fill 32 bit universe

            fill (0) // all zeros 0x00000000
        }
        brush { // type of brush and range

            type "dot" // draw a circle
            size (1…64:24.2351) // range of radius
            press (0…1:1) // pressure changes size
            index (1…255:127) // index in 256 color palette
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
            fade (val 0…1:0.5) {
                on (0…1:0) >> (cell.fade.on(0) , cell.ave.on(0) , cell.melt.on(0) , cell.tunl.on(0) , cell.slide.on(0) , cell.fred.on(0) , cell.zha.on(0) )
            }
            ave (val 0…1:0.5) {
                on (0…1:1) >> (cell.fade.on(0) , cell.ave.on(0) , cell.melt.on(0) , cell.tunl.on(0) , cell.slide.on(0) , cell.fred.on(0) , cell.zha.on(0) )
            }
            melt (val 0…1:0.5) {
                on (0…1:0) >> (cell.fade.on(0) , cell.ave.on(0) , cell.melt.on(0) , cell.tunl.on(0) , cell.slide.on(0) , cell.fred.on(0) , cell.zha.on(0) )
            }
            tunl (seg 0…5:1) {
                on (0…1:0) >> (cell.fade.on(0) , cell.ave.on(0) , cell.melt.on(0) , cell.tunl.on(0) , cell.slide.on(0) , cell.fred.on(0) , cell.zha.on(0) )
            }
            slide (seg 0…7 3) {
                on (0…1:0) >> (cell.fade.on(0) , cell.ave.on(0) , cell.melt.on(0) , cell.tunl.on(0) , cell.slide.on(0) , cell.fred.on(0) , cell.zha.on(0) )
            }
            fred (seg 0…4:4) {
                on (0…1:0) >> (cell.fade.on(0) , cell.ave.on(0) , cell.melt.on(0) , cell.tunl.on(0) , cell.slide.on(0) , cell.fred.on(0) , cell.zha.on(0) )
            }
            zha (seg 0…6:2) {
                on (0…1:0) >> (cell.fade.on(0) , cell.ave.on(0) , cell.melt.on(0) , cell.tunl.on(0) , cell.slide.on(0) , cell.fred.on(0) , cell.zha.on(0) )
                loops (11)
                bits (2…4:3)
            }
        }
        pipe {
            draw (x 0…1:0.5, y 0…1:0.5)
            record (tog 0)
            camera (tog 0) {
                flip (tog 0)
            }
            camix (tog 0)
            color (val 0…1:0.1) // bitplane
            render {
                frame (x 0, y 0, w 1080, h 1920)
                repeat (x, y)
                mirror (x, y)
            }
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
menu {
    view {
        canvas (symbol "photo.artframe", spot:0) {
            tile (image "icon.shader.tile.png", spot:0)) {
                mirror (symbol"arrowtriangle.left.and.line.vertical.and.arrowtriangle.right", spot 0)
                repeat (symbol"rectangle.grid.2x2", on:0))
            }
            scroll (image"icon.cell.scroll.png") {
                shift (image"icon.cell.scroll")
                tilt (image"icon.pen.tilt")
            }
            color (image"icon.pal.main") {
                fade (symbol"slider.horizontal.below.rectangle")
                plane (symbol"square.3.layers.3d.down.right")
                zero (symbol"drop")
                one (symbol"drop.fill")
            }
            speed (image"icon.speed") {
                fps (symbol"speedometer")
                run (symbol"goforward")
            }
        }
        brush (symbol"paintbrush.pointed") {
            size (symbol"circle.circle")
            press (image"icon.pen.press")
            tilt (image"icon.pen.tilt") //(symbol "angle")
        }
        cell (symbol"circle.grid.3x3") {
            fade (image"icon.cell.fade")
            ave (image"icon.cell.ave")
            melt (image"icon.cell.melt")
            tunl (image"icon.cell.tunl")
            zha (image"icon.cell.zha")
            slide (image"icon.cell.slide")
            fred (image"icon.cell.fred")
        }
        cam (symbol"camera") {
            snap (symbol"camera.shutter.button")
            fake (symbol"face.dashed")
            real (symbol"face.smiling")
            face (symbol"arrow.triangle.2.circlepath.camera")
            xfade (symbol"slider.horizontal.below.rectangle")
        }
    }
    model {
        canvas {
            tile {
                mirror (x -1…1, y -1…1) >> pipe.render.mirror
                repeat (x -1…1, y -1…1) >> pipe.render.repeat
            }
            scroll {
                shift (x 0…1:0.5, y 0…1:0.5) >> model.pipe.draw
                tilt (tog 0…1:0) <> sky.input.tilt
            }
            color {
                fade (val 0…1:0) <> sky.color.xfade
                plane (val 0…1:0) >> model.pipe.color
                zero (tap 0…1:0) >> draw.screen.fill(0)
                one (tap 0…1:0) >> draw.screen.fill(1)
            }
            speed {
                fps (seg 0…60:60) >> sky.main.fps
                run (tog 0…1:1) >> sky.main.run
            }
        }
        brush {
            size (val 0…1:0.5) >> draw.brush.size
            press (tog 0…1:1) >> draw.brush.press
            tilt (tog 0…1:1) >> sky.input.brush.tilt
        }
        cell {
            fade (val 2…3:2.2) >> model.cell.fade
            ave (val 0…1:0.5) >> model.cell.ave
            melt (val 0…1:0.5) >> model.cell.melt
            tunl (seg 0…5:1) >> model.cell.tunl
            zha (seg 0…6:2) >> model.cell.zha
            slide (seg 0…7:3) >> model.cell.slide
            fred (seg 0…4:4) >> model.cell.fred
        }
        cam {
            snap (tap 0…1:0)
            fake (tog 0…1:0) >> shader.model.pipe.camix.on
            real (tog 0…1:1) >> shader.model.pipe.camera.on
            face (tog 0…1:1) >> pipe.camera.flip
            xfade (val 0…1:0.5) <> sky.color.xfade
        }
    }
}
