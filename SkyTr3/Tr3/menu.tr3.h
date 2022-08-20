menu.view {
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
        xfade (symbol "slider.horizontal.below.rectangle")
    }
}
menu.model {
    canvas {
        tile  {
            mirror (x 0…1 = 0,
                    y 0…1 = 0) >> shader.model.pipe.render.mirror

            repeat (x -1…1 = 0,
                    y -1…1 = 0) >> shader.model.pipe.render.repeat

            shift (x 0…1 = 0.5,
                   y 0…1 = 0.5) >> shader.model.pipe.draw

            tilt  (tog 0…1 = 0) <> sky.input.tilt
        }
        color {
            fade  (val 0…1 = 0) <> sky.color.xfade
            plane (val 0…1 = 0) >> shader.model.pipe.color
            zero  (tap 0…1 = 0) >> sky.draw.screen.fill(0)
            one   (tap 0…1 = 0) >> sky.draw.screen.fill(1)
        }
        speed {
            fps (seg 0…60 = 60) >> sky.main.fps
            run (tog 0…1  = 1 ) >> sky.main.run
        }
    }
    brush {
        size  (val 0…1 = 0.5) >> (sky.draw.brush.size, press.(tog 0))
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
        xfade (val 0…1 = 0.5) <> sky.color.xfade
    }
}
