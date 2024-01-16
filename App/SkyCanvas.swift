//  created by musesum on 9/17/23.

import SwiftUI
import MuFlo
import MuAudio
import MuMenu
import MuSkyFlo
import MuVision

class SkyCanvas {

    static let shared = SkyCanvas()
    var midi: MuMidi
    var pipeline: SkyPipeline
    var touchView: SkyTouchView
    var settingUp = true

    var renderState = RenderDepth.state
    var renderFrame = [RenderState: CGRect]()
    var frameNow = CGRect.zero

    let archive = FloArchive(
        bundle: MuSkyFlo.bundle,
        archive: "Snapshot",
        scripts:  ["sky", "shader","model", "menu", "midi", "corner"],
        textures: ["draw"])

    init() {
        midi = MuMidi(root: archive.root˚)
        TouchMidi.touchRemote = midi
        _ = MuAudio.shared // MuAudio.shared.test()
#if os(visionOS)
        let bounds = CGRect(x: 0, y: 0, width: 1920, height: 1080)
#else
        let bounds = UIScreen.main.bounds
#endif
        pipeline = SkyPipeline(bounds, archive.root˚)
        TouchCanvas.shared.touchFlo.parseRoot(archive.root˚, archive)
        touchView = SkyTouchView(bounds)
        touchView.backgroundColor = .clear
        touchView.layer.addSublayer(pipeline.metalLayer)
    }
}
extension SkyCanvas: MenuDelegate {

    func window(frame: CGRect, insets: EdgeInsets) {

        let scale    : CGFloat
        var bounds   : CGRect
        var viewSize : CGSize

        var frame = frame

        #if os(visionOS)
        scale = 3
        if renderState != RenderDepth.state {
            renderState = RenderDepth.state
            if let savedFrame = renderFrame[RenderDepth.state],
               savedFrame != .zero {
                frame = savedFrame
            }
        }
        renderFrame[renderState] = frame

        if RenderDepth.state == .immer,
           let viewports = RenderLayer.viewports,
           let v = viewports.first {
            bounds = CGRect(x: v.originX, y: v.originY, width: v.width, height: v.height) / scale
        } else {
            bounds = frame
        }
        viewSize = bounds.size * scale
        touchView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)

        #else
        scale = UIScreen.main.scale
        bounds = frame
        let width = bounds.width + insets.leading + insets.trailing
        let height = bounds.height + insets.top + insets.bottom
        viewSize = CGSize(width: width, height: height) * scale
        touchView.frame = CGRect(x: 0, y: 0, width: width, height: height)
        #endif

        TouchCanvas.shared.touchFlo.viewSize = viewSize

        print("state: \(RenderDepth.state.rawValue.pad(6))  bounds\(bounds.script) viewSize\(viewSize.script) touchView\(touchView.frame.size.script)", terminator: " ")
        pipeline.resize(frame, viewSize, scale)

    }
}
extension SkyCanvas: NextFrameDelegate {

    func nextFrame() -> Bool {
        pipeline.renderFrame()
        return true
    }
    func cancel(_ key: Int) {
        NextFrame.shared.removeDelegate(key)
    }

}
