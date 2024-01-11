//  created by musesum on 9/17/23.

import SwiftUI
import MuFlo
import MuAudio
import MuMenu
import MuSkyFlo
import MuVision

struct SkyCanvas {

    static let shared = SkyCanvas()
    var midi: MuMidi
    var pipeline: SkyPipeline
    var touchView: SkyTouchView
    var settingUp = true

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
        touchView.layer.addSublayer(pipeline.metalLayer)
    }
}
extension SkyCanvas: MenuDelegate {

    func window(frame: CGRect, insets: EdgeInsets) {

        let scale   : CGFloat
        let bounds  : CGRect
        let width   : CGFloat
        let height  : CGFloat
        let viewSize: CGSize

        #if os(visionOS)


        if DepthRender.state == .vision,
           let viewports = RenderLayer.viewports,
           let v = viewports.first {
            bounds = CGRect(x: v.originX, y: v.originY, width: v.width, height: v.height)
            scale = 3
            viewSize = bounds.size * scale
        } else {
            bounds = frame
            scale = 3
            viewSize = bounds.size * scale

        }
        width = bounds.width
        height = bounds.height
        #else
        scale = UIScreen.main.scale
        bounds = frame
        width = bounds.width + insets.leading + insets.trailing
        height = bounds.height + insets.top + insets.bottom
        viewSize = CGSize(width: width, height: height) * scale
        #endif


        TouchCanvas.shared.touchFlo.viewSize = viewSize
        touchView.frame = CGRect(x: 0, y: 0, width: width, height: height)
        print("state: \(DepthRender.state.script.pad(6))   viewSize\(viewSize.script) touchView\(touchView.frame.script)")

        pipeline.resize(viewSize, scale)
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
