sky.shader {
    _compute { type "compute" file "*.metal" on (0…1) buffer { version (0…1) } }
    melt: _compute { file "cell.melt.metal" }
    fred: _compute { file "cell.fred.metal" }
    gas: _compute { file "cell.gas.metal" }
    ave: _compute { file "cell.ave.metal" }
    mod: _compute { file "cell.mod.metal" }
    fade: _compute { file "cell.fade.metal" }
    slide: _compute { file "cell.slide.metal" }
    drift: _compute { file "cell.drift.metal" }
    tunl: _compute { file "cell.tunl.metal" }
    zha: _compute { file "cell.zha.metal" repeat (11) buffer.bits (2…4 = 3) }
    record { type "record" file "record.metal"      on (0…1) buffer { version (0…1) } }
    camera { type "camera" file "cell.camera.metal" on (0…1) buffer { version (0…1) } flip (0…1) }
    camix  { type "camix"  file "cell.camix.metal"  on (0…1) buffer { version (0…1) } }
    draws  { type "draw"   file "pipe.draws.metal"  on (0…1) buffer { scroll(x 0…1=0.5, y 0…1=0.5) }}
    color  { type "color"  file "pipe.color.metal"           buffer { bitplane (0…1) } }
    render { type "render" file "pipe.render.metal"          buffer { clip (x 0, y 0, w 1080, h 1920) repeat (x, y) mirror (x, y) } }
}

shader.model {
    cell {
        fade  (val 0…1 = 0.5, on 1)
        ave   (val 0…1 = 0.5, on 0)
        melt  (val 0…1 = 0.5, on 0)
        tunl  (seg 0…5 = 1  , on 0)
        slide (seg 0…7 = 3  , on 0)
        fred  (seg 0…4 = 4  , on 0)
        zha   (seg 0…6 = 2  , on 0) { repeat (11), bits (2…4=3) }
    }
    pipe {
        record (tog 0, on 0…1)
        camera (tog 0, on 0…1) { flip (tog) }
        camix  (tog 0, on 0…1)
        scroll (x 0…1 = 0.5,
                y 0…1 = 0.5)

        render {
            offset (x 0, y 0)
            size (w 1080, h 1920)
            repeat (x, y)
            mirror (x, y)
        }
        color  (val 0) { bitplane (val) }
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
        scroll ("pipe.draws.metal" )
        render ("pipe.render.metal")
        color  ("pipe.color.metal" )
    }
}
