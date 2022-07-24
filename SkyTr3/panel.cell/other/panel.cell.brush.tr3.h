panel.cell.brush {

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
            value (0..1)
        }
        brushSize {
            type "slider"
            title "Size"
            frame (x 10, y 40, w 192, h 32)
            value (0..1) <> sky.draw.brush.size
            user >> brushPress.value(0)
        }
        brushPress {
            type "switch"
            title "Pressure"
            frame (x 210, y 40, w 44, h 32)
            icon "icon.pen.press.png"
            value (0..1) <> sky.draw.brush.press
        }
        bitplane {
            type "slider"
            title "Bit Plane"
            frame (x 10, y 80, w 192, h 32)
            icon "icon.pearl.white.png"
            value (0..1) >> sky.shader.color.buffer.bitplane
        }
        fillOne {
            type "trigger"
            title "clear 0xFFFF"
            frame (x 210, y 80, w 32, h 32)
            icon "icon.drop.gray.png"
            value (0..1) >> sky.draw.screen.fillOne
        }
    }
}
