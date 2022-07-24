shader
    _compute { type "compute", file "*.metal", on (0..1), buffer { version (0..1) } }
    melt: _compute { file "cell.melt.metal" }
    fred: _compute { file "cell.fred.metal" }
    gas: _compute { file "cell.gas.metal" }
    ave: _compute { file "cell.ave.metal" }
    mod: _compute { file "cell.mod.metal" }
    fade: _compute { file "cell.fade.metal" }
    slide: _compute { file "cell.slide.metal" }
    drift: _compute { file "cell.drift.metal" }
    tunl: _compute { file "cell.tunl.metal" }
    zha: _compute { file "cell.zha.metal", repeat (11), buffer.bits (2..4 = 3) }
    record { type "record", file "record.metal", on (0..1), buffer { version (0..1) } flip (0..1) }
    camera { type "camera", file "cell.camera.metal", on (0..1), buffer { version (0..1) } flip (0..1) }
    camix { type "camix", file "cell.camix.metal", on (0..1), buffer { version (0..1) } flip (0..1) }
    draws { type "draw", file "draw.metal", on (0..1), buffer.scroll (x 0..1 = 0.5, y 0..1 = 0.5) }
    color { type "color" file "color.metal" buffer.bitplane (0..1) }
    render { type "render", file "render.metal", buffer { repeat (x, y), mirror (x, y) } }
