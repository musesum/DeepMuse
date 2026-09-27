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
        NoDebugLog { P("🚰 \(self.renderState.rawValue) size\(size.digits()) ports:\(self.pipeline.viewports.count)") }
        if !startup.menusReady { Task { @MainActor in self.startup.menusReady = true } }
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
            NoDebugLog { P("👓 Immersive secondMenuFrame") }
            self.setFrame(self.touchView.frame, self.insets, onAppear: false)
        }
    }
}
#endif
extension SkyModel: NextFrameDelegate {
    nonisolated func goFrame() -> Bool {
        Task { @MainActor in
            syncPairMix()   // re-reads the flag before the frame encodes it
            pipeline.renderFrame()
            if !startup.done {
                startup.done = true
                for menuVm in menus.menuVms {
                    menuVm.rootVm.cornerVm.setStartupCenter(nil)
                }
                // trunk flash after the ring lands; showNow self-arms the fade timeout
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    // NE holds the graph leaf; its trunk stays closed until asked for
                    for menuVm in self.menus.menuVms where menuVm.cornerType.corner != .NE {
                        menuVm.rootVm.showTrunks(false)
                    }
                }
                // defer past ring flight + trunk fade-in: CoreMIDI (~0.8s) would starve it
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                    self.loadAudio()
                }
            }
        }
        return true
    }
    nonisolated func cancel(_ key: Int) {
        Task { @MainActor in
            NextFrame.shared.removeDelegate(key)
        }
    }
}
