panel.shader.weave {
    base {
        type "shader"
        title "Weave"
        frame (x 0, y 0, w 312, h 202)
        icon "icon.shader.weave.png"
    }
    controls {
        ruleOn {
            type "switch"
            title "Active"
            frame (x 246, y 6, w 48, h 32)
            icon "icon.shader.weave.png"
            value (0..1)
        }
       spreadBox {
            type "box"
            frame (x 16, y 52, w 128, h 128)
            radius (10)
            tap2 (x -1, y -1)
            lag (1.5)
            value (x 0..1, y 0..1) <> shader.buffer.spread
        }
        divideBox {
            type "box"
            frame (x 160, y 52, w 128, h 128)
            radius (10)
            tap2 (x -1, y -1)
            lag (1.5)
            value (x 0..1, y 0..1) <> shader.buffer.divide
        }
    }
}
