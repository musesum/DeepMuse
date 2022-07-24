panel.cell.camera: _camera {

    base {
        type "camera"
        title "Camera"
        icon "icon.camera.png"
    }
    controls {
        cameraOne.value >> sky.shader.camera.on
        cameraTwo.value >> sky.shader.camix.on
        version.value (0..1 = 0.5) >> sky.shader.camix.buffer.version
        bitplane.value (0..1) >> sky.shader.color.buffer.bitplane
    }
}
