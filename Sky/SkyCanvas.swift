//  created by musesum on 9/17/23.

import SwiftUI
import MuFlo
import MuMenu
import MuVision

#if os(visionOS)
class SkyCanvas: SkyCanvasBase, MenuFrame {

    var insets =  EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)

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
        nextFrame.pause = immersion
    }

    func menuFrame(_ frame: CGRect,
                   _ insets: EdgeInsets,
                   onAppear: Bool) {
        self.insets = insets

        var size: CGSize
        switch renderState {
        case .immersed:
            if pipeline.viewports.count > 0,
               let v = pipeline.viewports.first {
                size = CGSize(width: v.width, height: v.height) / 3 // Scale
            } else {
                size = CGSize(width: 1355, height: 1087) //... ignore; hard coded
                return secondMenuFrame()
            }
        default:
            size = frame.size
        }
        setSize(size, onAppear: onAppear)
    }
    func setSize(_ size: CGSize, onAppear: Bool) {
        let scale = CGFloat(3)
        let drawableSize = size * scale // layer.drawableSize
        let frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)

        touchDraw.drawableSize = drawableSize
        pipeline.resizeFrame(frame, drawableSize, scale, onAppear)
        DebugLog {
            P("🧭 \(self.renderState.rawValue) size\(size.digits()) ports:\(self.pipeline.viewports.count)")
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            DebugLog { P("🧭 Immersive secondMenuFrame") }
            self.menuFrame(self.touchView.frame, self.insets, onAppear: false)
        }
    }
}
#else
class SkyCanvas: SkyCanvasBase, MenuFrame {

    func menuFrame(_ frame: CGRect,
                   _ insets: EdgeInsets,
                   onAppear: Bool) {
        
        DebugLog { P("🧭 menuFrame\(frame.digits())") }
        Task { @MainActor in
            
            let scale = UIScreen.main.scale
            let width = frame.width + insets.leading + insets.trailing
            let height = frame.height + insets.top + insets.bottom
            let size = CGSize(width: width, height: height)
            
            let drawableSize = size * scale  // layer.drawableSize
            let frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            
            touchView.frame = frame
            touchDraw.drawableSize = drawableSize
            pipeline.resizeFrame(frame, drawableSize, scale, onAppear)
        }
    }
}
#endif
extension SkyCanvas: NextFrameDelegate {
    func goFrame() -> Bool {
        pipeline.renderFrame()
        return true
    }
    func cancel(_ key: Int) {
        nextFrame.removeDelegate(key)
    }
}
