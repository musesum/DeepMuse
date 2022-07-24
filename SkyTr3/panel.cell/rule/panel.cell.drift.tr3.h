panel.cell.drift: _cell {
    base {
        title "Drift"
        icon "icon.cell.drift.png"
    }
    controls {
        ruleOn.icon "icon.cell.drift.png"
        ruleOn.value >> sky.shader.cellDrift.on
        version.value >> sky.shader.cellDrift.buffer.version
    }
}
