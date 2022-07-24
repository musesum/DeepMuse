panel._camera {
    base {
        type "cell"
        title "_cell" // name
        frame (x 0, y 0, w 250, h 130)
        icon "icon.ring.white.png"
    }
    controls {
        hide {
            type "panelx"
            title "hide"
            frame (x 0, y 0, w 40, h 40)
            icon "icon.thumb.X.png"
            value (0..1)
        }
        cameraOne {
            type "panelon"
            title "Camera Cell"
            frame (x 202, y 4, w 40, h 32)
            icon "icon.camera.png"
            value (0..1)
            lag (0)
        }
        version {
            type "segment"
            title "Version"
            frame (x 10, y 44, w 184, h 32)
            value (0..1 = 0.5)
            user >> ruleOn.value (1)
        }
        cameraTwo {
            type "panelon"
            title "Camera Mix"
            frame (x 202, y 44, w 40, h 32)
            icon "icon.camera.flip.png"
            value (0..1)
            lag (0)
        }
        bitplane {
            type "slider"
            title "Bit Plane"
            frame (x 10, y 84, w 184, h 32)
            icon "icon.pearl.white.png"
            value (0..1)
        }
        facing {
            type "switch"
            title "Lock"
            frame (x 202, y 84, w 40, h 32)
            icon "icon.camera.flip.png"
            value (0..1) >> sky.shader.camera.flip
            lag (0)
        }
    }
}
