//  created by musesum on 9/17/23.

import SwiftUI
import MuFlo
import MuMenu
import MuVision

#if os(visionOS)
extension VisionModel  { // visionOS

    func setImmersion(_ immersion: Bool) {

        let renderState: RenderState = immersion ? .immersed : .windowed

        if self.renderState != renderState {

            self.renderState = renderState
            pipeline.renderState = renderState

            if renderState == .immersed {
                pipeline.layer.opacity = 0
                touchCanvas.immersive = true
            } else {
                pipeline.layer.opacity = 1
                touchCanvas.immersive = false
            }
            if let frame = stateFrame[renderState],
               frame != .zero {
                setSize(frame.size, onAppear: false)
            }
        }
        DebugLog { P("🎬 SkyCanvas NextFrame.pause: \(immersion)") }
        NextFrame.shared.pause = immersion
    }

    
    func setSize(_ size: CGSize, onAppear: Bool) {
        let drawableSize = size * scale // layer.drawableSize
        let frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)

        touchCanvas.drawableSize = drawableSize
        pipeline.resizeFrame(frame, drawableSize, scale, onAppear)
        NoDebugLog { P("🧭 \(self.renderState.rawValue) size\(size.digits()) ports:\(self.pipeline.viewports.count)") }
    }

    /// Adjust frame after rendering first frame
    ///
    ///   This is a kludge. The SkyCanvas appears before
    ///   rendering the first frame in an immersive space.
    ///   The problem is that we need a DrawableLayer to setup
    ///   the viewports, and it is from the viewport that we can
    ///   determine the frame size. So, wait for a few frames.
    ///   and try it again.
    func secondMenuFrame() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NoDebugLog { P("🧭 Immersive secondMenuFrame") }
            self.setFrame(self.touchView.frame, self.insets, onAppear: false)
        }
    }
}
#endif
extension SkyModel: NextFrameDelegate {
    nonisolated func goFrame() -> Bool {
        Task { @MainActor in
            pipeline.renderFrame()
        }
        return true
    }
    nonisolated func cancel(_ key: Int) {
        Task { @MainActor in
            NextFrame.shared.removeDelegate(key)
        }
    }
}
