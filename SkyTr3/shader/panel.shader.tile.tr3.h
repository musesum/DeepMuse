panel.shader.tile {
    base {
        type "shader"
        title "Tile"
        frame (x 0, y 0, w 230, h 170)
        icon "icon.shader.tile.png"
    }
    controls {
        hide {
            type "panelx"
            title "hide"
            frame (x 0, y 0, w 40, h 40)
            icon "icon.thumb.X.png"
            value (0..1)
        }
        tileOn {
            type "panelon"
            title "Active"
            frame (x 174, y 6, w 40, h 32)
            icon "icon.shader.tile.png"
            value (0..1)
            user >> repeatBox.value(x 0, y 0)
            lag (0)
        }
        repeatBox {
            type "box"
            title "Repeat"
            frame (x 10, y 40, w 120, h 120)
            radius (10)
            tap2 (x -1, y -1)
            lag (0)
            user (0..1 = 1) >> tileOn.value(1)
            value (x 0..1, y 0..1) >> sky.shader.render.buffer.repeat
        }
        mirrorBox {
            type "box"
            title "Mirror"
            frame (x 140, y 60, w 80, h 80)
            radius (10)
            tap2 (x 1, y 1)
            lag (0)
            user (0..1 = 1)
            value (x 0..1, y 0..1) >> sky.shader.render.buffer.mirror
        }
    }
}
