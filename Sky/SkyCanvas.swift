//  created by musesum on 9/17/23.

import SwiftUI
import MuFlo
import MuMenu
import MuVision

#if os(visionOS)
class SkyCanvas: SkyCanvasBase, MenuFrame {

    static let shared = SkyCanvas()
    var insets =  EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)

    func menuFrame(_ frame: CGRect,
                   _ insets: EdgeInsets,
                   onAppear: Bool) {
        self.insets = insets
        // save restore frame
        var frame = frame
        if renderState != RenderDepth.state {
            renderState = RenderDepth.state
            if let savedFrame = stateFrame[RenderDepth.state],
               savedFrame != .zero {
                frame = savedFrame
            }
            stateFrame[renderState] = frame
        }

        if RenderDepth.state == .immersive {
            var size = frame.size
            if let viewports = RenderLayer.viewports,
               let v = viewports.first {
                size = CGSize(width: v.width, height: v.height) / 3 // Scale
            } else {
                size = CGSize(width: 2732, height: 2048) / 3 // Scale
                secondMenuFrame()
            }
            setFrame("Immersive",size, scale: 3)
        } else {
            setFrame("Non-Immersive", frame.size, scale: 3)
        }
        func setFrame(_ state: String,_ size: CGSize, scale: CGFloat) {
            let drawableSize = size * scale // layer.drawableSize
            let layerFrame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            touchesView.frame = layerFrame
            TouchDraw.shared.drawableSize = drawableSize
            pipeline.resizeFrame(frame, drawableSize, scale, onAppear)
            DebugLog { P("🧭 \(state) size\(size.digits()) ports:\(RenderLayer.viewports?.count ?? 0)") }
        }
    }

    /// Adjust frame after rendering first frame
    ///
    ///   This is a kludge. The SkyCanvas appears before
    ///   rendering the first frame in an immersive space.
    ///   The problem is that we need a DrawableLayer to setup
    ///   the viewports, and it is from the viewport that we can
    ///   determine the frame size. So, we wait for a one second
    ///   and try it again.
    func secondMenuFrame() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            DebugLog { P("🧭 Immersive secondMenuFrame") }
            self.menuFrame(self.touchesView.frame, self.insets, onAppear: false)
        }
    }
}
#else
class SkyCanvas: SkyCanvasBase, MenuFrame {

    static let shared = SkyCanvas()

    func menuFrame(_ frame: CGRect,
                   _ insets: EdgeInsets,
                   onAppear: Bool) {
        
        DebugLog { P("🧭 menuFrame\(frame.digits())") }

        let scale = UIScreen.main.scale
        let width = frame.width + insets.leading + insets.trailing
        let height = frame.height + insets.top + insets.bottom
        let size = CGSize(width: width, height: height)

        let drawableSize = size * scale  // layer.drawableSize
        let frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)

        touchesView.frame = frame
        TouchDraw.shared.drawableSize = drawableSize
        pipeline.resizeFrame(frame, drawableSize, scale, onAppear)
    }
}
#endif
extension SkyCanvas: NextFrameDelegate {
    func nextFrame() -> Bool {
        pipeline.renderFrame()
        return true
    }
    func cancel(_ key: Int) {
        NextFrame.shared.removeDelegate(key)
    }
}
