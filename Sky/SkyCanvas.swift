//  created by musesum on 9/17/23.

import SwiftUI
import MuFlo
import MuAudio
import MuMenu
import MuSky
import MuVision
import MuMetal

class SkyCanvas {

    static let shared = SkyCanvas()
    var midi: MuMidi
    var pipeline: SkyPipeline
    var skyTouchView: SkyTouchView
    var settingUp = true

    var renderState = RenderDepth.state
    var renderFrame = [RenderState: CGRect]()
    var frameNow = CGRect.zero
#if os(visionOS)
    let handsModel: HandsModel
    let handsTracker: HandsTracker
#endif

    let archive = FloArchive(
        bundles: [MuSky.bundle, MuVision.bundle],
        archive: "Snapshot",
        scripts:  ["sky", "shader","model", "menu", "midi"],
        textures: ["draw"])

    init() {
        midi = MuMidi(root: archive.root˚)
        TouchMidi.touchRemote = midi
        _ = MuAudio.shared // MuAudio.shared.test()
#if os(visionOS)
        let bounds = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        handsModel = HandsModel(TouchCanvas.shared, archive.root˚, archive)
        handsTracker = HandsTracker(handsModel.handsFlo)
#else
        let bounds = UIScreen.main.bounds
#endif
        pipeline = SkyPipeline(bounds, archive.root˚)
        TouchCanvas.shared.touchFlo.parseRoot(archive.root˚, archive)

        skyTouchView = SkyTouchView(bounds)
        skyTouchView.backgroundColor = .clear
        skyTouchView.layer.addSublayer(pipeline.metalLayer)
    }
}
extension SkyCanvas: MenuDelegate {

#if os(visionOS)
    func window(frame: CGRect, insets: EdgeInsets) {

        // save restore frame
        var frame = frame
        if renderState != RenderDepth.state {
            renderState = RenderDepth.state
            if let savedFrame = renderFrame[RenderDepth.state],
               savedFrame != .zero {
                frame = savedFrame
            }
        }
        renderFrame[renderState] = frame

        // resize
        let scale = CGFloat(3)
        var bounds: CGRect
        if RenderDepth.state == .immer,
           let viewports = RenderLayer.viewports,
           let v = viewports.first {
            bounds = CGRect(x: v.originX, y: v.originY, width: v.width, height: v.height) / scale
        } else {
            bounds = frame
        }
        let viewSize = bounds.size * scale
        skyTouchView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)

        TouchCanvas.shared.touchFlo.viewSize = viewSize
        pipeline.resize(frame, viewSize, scale)
        log(viewSize)
    }
#else
    func window(frame: CGRect, insets: EdgeInsets) {

        let scale = UIScreen.main.scale
        let width = frame.width + insets.leading + insets.trailing
        let height = frame.height + insets.top + insets.bottom
        let viewSize = CGSize(width: width, height: height) * scale

        skyTouchView.frame = CGRect(x: 0, y: 0, width: width, height: height)
        TouchCanvas.shared.touchFlo.viewSize = viewSize
        pipeline.resize(skyTouchView.frame, viewSize, scale)

        // ipad    frame (0,24 1194,790 insets ( 0 0 20 0)
        // iphone  frame (0,59  430,839 insets (59 0 34 0) bounds (430,932) 932-839=93
        //
        log(viewSize)
    }
#endif
    func log(_ viewSize: CGSize) {

        //print("state: \(RenderDepth.state.rawValue.pad(6))  frame\(pipeline.metalLayer.frame.script) viewSize\(viewSize.script) touchView\(touchView.frame.size.script)", terminator: " ")
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
