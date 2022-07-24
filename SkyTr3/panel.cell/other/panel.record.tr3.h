panel.record {
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
            value (0..1)
        }
        ruleOn {
            type "panelon"
            title "Active"
            frame (x 202, y 4, w 40, h 32)
            icon  "icon.record.png"
            value (0..1) >> sky.shader.record.on
            lag (0)
        }
        version {
            type "segment"
            title "Version"
            frame (x 10, y 44, w 192, h 32)
            value (0..1 = 0.5) >> sky.shader.record.buffer.version
            user >> ruleOn.value (1)
        }
        lock {
            type "switch"
            title "Lock"
            frame (x 210, y 44, w 32, h 32)
            icon "icon.camera.flip.png"
            value >> sky.shader.record.flip
            lag (0)
        }
        bitplane {
            type "slider"
            title "Bit Plane"
            frame (x 10, y 84, w 192, h 32)
            icon "icon.pearl.white.png"
            value (0..1 = 0.2)
        }
        fillZero {
            type "trigger"
            title "Fill Zeros"
            frame (x 210, y 44, w 32, h 32)
            icon "icon.drop.gray.png"
            value (0..1) >> sky.draw.screen.fillZero
        }
        fillOne {
            type "trigger"
            title "Fill Ones"
            frame (x 210, y 84, w 32, h 32)
            icon "icon.drop.gray.png"
            value (0..1) >> sky.draw.screen.fillOne
        }
    }
}
