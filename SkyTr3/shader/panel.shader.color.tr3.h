panel.shader.color {
    base {
        type "color"
        title "Color"
        frame (x 0, y 0, w 250, h 130)
        icon "icon.pal.main.png"
    }
    controls {
        hide {
            type "panelx"
            title "hide"
            frame (x 0, y 0, w 40, h 40)
            icon "icon.thumb.X.png"
            value (0..1)
        }
        palFade {
            type "slider"
            title "Palette Cross Fade"
            frame (x 10, y 44, w 192, h 32)
            icon "icon.pearl.white.png"
            value (0..1) <> sky.color.xfade
            lag (0)
        }
        bitplane {
            type "slider"
            title "Bit Plane"
            frame (x 10, y 84, w 192, h 32)
            icon "icon.pearl.white.png"
            value (0..1) >> sky.shader.color.buffer.bitplane
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
