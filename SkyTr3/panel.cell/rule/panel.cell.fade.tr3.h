panel.cell.fade: _cell {
    base {
        title "Fade"
        icon "icon.cell.fade.png"
    }
    controls {
        ruleOn.icon "icon.cell.fade.png"
        ruleOn.value >> sky.shader.fade.on
        version.value (0..1 = 0.5) >> sky.shader.fade.buffer.version
        bitplane.value (0..1 = 0.2)
    }
}
