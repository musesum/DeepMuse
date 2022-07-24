panel.cell.melt: _cell {
    base {
        title "Melt"
        icon "icon.cell.melt.png"
    }
    controls {
        ruleOn.icon "icon.cell.melt.png"
        ruleOn.value >> sky.shader.melt.on
        version.value >> sky.shader.melt.buffer.version
        fillZero.value (16777182)  // 00ffffde
        fillOne.value (16777182)   // ffffffde
    }
}
