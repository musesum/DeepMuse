panel.cell.gas: _cell {
    base {
        title "Gas"
        icon "icon.cell.gas.png"
    }
    controls {
        ruleOn.icon "icon.cell.gas.png"
        ruleOn.value >> sky.shader.cellGas.on
        version.value >> sky.shader.cellGas.buffer.version
    }
}
