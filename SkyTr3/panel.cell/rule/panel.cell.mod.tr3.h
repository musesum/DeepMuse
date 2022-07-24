panel.cell.mod: _cell {
    base {
        title "Modulo"
        icon "icon.cell.mod.png"
    }
    controls {
        ruleOn.icon "icon.cell.mod.png"
        ruleOn.value >> sky.shader.mod.on
        version.value >> sky.shader.mod.buffer.version
    }
}
