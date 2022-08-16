shader.model {
    cell {
        fade  (val 0…1 = 0.5) { on(0…1 = 0) >> cell˚on(0) }
        ave   (val 0…1 = 0.5) { on(0…1 = 1) >> cell˚on(0) }
        melt  (val 0…1 = 0.5) { on(0…1 = 0) >> cell˚on(0) }
        tunl  (seg 0…5 = 1  ) { on(0…1 = 0) >> cell˚on(0) }
        slide (seg 0…7 = 3  ) { on(0…1 = 0) >> cell˚on(0) }
        fred  (seg 0…4 = 4  ) { on(0…1 = 0) >> cell˚on(0) }
        zha   (seg 0…6 = 2  ) { on(0…1 = 0) >> cell˚on(0) }
        zha { loops(11) bits (2…4 = 3) }
    }
    pipe {
        draw (x 0…1 = 0.5, y 0…1 = 0.5)
        record (tog 0)
        camera (tog 0) { flip (tog 0) }
        camix  (tog 0)
        color(val 0…1 = 0.1) // bitplane
        render {
            frame (x 0, y 0, w 1080, h 1920)
            repeat (x, y)
            mirror (x, y)
        }
    }
}
shader.file {
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
