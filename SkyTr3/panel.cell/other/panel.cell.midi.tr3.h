panel.cell.midi {
    base {
        type "cell"
        title "Midi" // name
        frame (x 0, y 0, w 212, h 104)
        icon "icon.midi.png"
    }
    controls {
        speedOn {
            type "panelon"
            title "Active"
            frame (x 154, y 6, w 48, h 32)
            icon "icon.midi.png"
            value (0..1) >> sky.main.run
            user >> scrollBox.value(x 0.5, y 0.5)
            lag (0)
        }
        hide {
            type "panelx"
            title "hide"
            frame (x 0, y 0, w 40, h 40)
            icon "icon.thumb.X.png"
            value (0..1)
        }
        speed {
            type "slider"
            title "Frames per second"
            frame (x 10, y 50, w 192, h 44)
            icon "icon.pearl.white.png"
            value (1..60 = 60) <> sky.main.fps
            user >> speedOn.value(1)
        }
    }
}
