panel.cell.slide: _cell {
    base {
        title "Slide Bit Planes"
        icon "icon.cell.slide.png"
    }
    controls {
        ruleOn.icon "icon.cell.slide.png"
        ruleOn.value >> sky.shader.slide.on
        version.value >> sky.shader.slide.buffer.version
    }
}
