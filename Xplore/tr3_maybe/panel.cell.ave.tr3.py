panel.cell.ave: _cell
    base
        title "Average"
        icon "icon.cell.ave.png"

    controls
        ruleOn.icon "icon.cell.ave.png"
        ruleOn.value >> sky.shader.ave.on
        version.value(0..1 = 0.4) >> sky.shader.ave.buffer.version


