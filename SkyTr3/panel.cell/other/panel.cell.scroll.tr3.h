panel.cell.scroll {
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
            value (0..1 = 0)
            lag (0)
            user >> (scrollBox.value(x 0.5, y 0.5),
                     brushTilt.value(0))
        }
        hide {
            type "panelx"
            title "hide"
            frame (x 0, y 0, w 40, h 40)
            icon "icon.thumb.X.png"
            value (0..1)
        }
        scrollBox {
            type "box"
            title "Screen Scroll"
            frame (x 8, y 44, w 128, h 128)
            radius (10)
            tap2 (x -1, y -1)
            lag (0)

            value (x 0..1 = 0.5,
                   y 0..1 = 0.5) <> sky.input.azimuth >> sky.shader.draws.buffer.scroll

            user >> (brushTilt.value(0),
                     accelTilt.value(0),
                     scrollOn.value(1))
        }
        brushTilt {
            type "switch"
            title "Brush Tilt"
            frame (x 144, y 62, w 40, h 32)
            icon "icon.pen.tilt.png"
            value (0..1) <> sky.input.tilt >> accelTilt.value(0)
        }
        fillZero {
            type "trigger"
            title "Fill Zero"
            frame (x 148, y 116, w 32, h 32)
            icon "icon.drop.clear.png"
            value (0..1) >> sky.draw.screen.fillZero
        }
    }
}

