import CoreGraphics
import UIKit
import MuUtilities

extension ThumbDock {

    func updateDock(_ state_:ShowState, _ from:String) {

        func animateDock() {

            let deltaTime = CFAbsoluteTimeGetCurrent() - dockStartTime

            func rearrange(_ interval:CGFloat, _ changeState:ShowState) {

                factor = cubic.point(for: interval).y
                remain = 1 - factor

                arrangeDots()
                dotNow?.panel?.reorientCenter()

                if deltaTime >= AnimDuration {

                    dockTimer?.invalidate()
                    state = changeState
                }
            }

            let timeFactor = CGFloat(min(1.0, deltaTime/AnimDuration))

            switch state {

            case .animShow: rearrange(  timeFactor,.showing)
            case .animHide: rearrange(1-timeFactor,.hidden)
            /* */           superview?.bringSubviewToFront(self)

            case .showing:  break
            case .hidden:   break
            }
        }

        // begin ---------------------------
         ThumbPrint("Dock_updateDock from: \(from) .\(state)=>.\(state_)")

        state = state_
        dockTimer?.invalidate()
        dockStartTime = CFAbsoluteTimeGetCurrent()
        dockTimer = Timer.scheduledTimer(withTimeInterval: LoopTime, repeats: true)  {_ in
            animateDock()
        }
    }

    func resetPanelTimer(after delay:CFTimeInterval) {

        panelTimer?.invalidate()

        if let panel = dotNow?.panel,
            panel.state != .showing {

            panelTimer = Timer.scheduledTimer(withTimeInterval:delay, repeats: false) { _ in
                panel.showPanel("Dock_resetPanelTimer")
            }
        }
    }
    func growDock() {

        switch state {
        case .animShow: break
        default:
            hideTimer?.invalidate()
            if let panel = dotNow?.panel,
                panel.state == .showing {
                panel.hidePanel("Dock_growDock")
            }
            else {
                resetPanelTimer(after: 2)
            }
            updateDock(.animShow,"Dock_growDock")
        }
    }

    func hideDock(after delay:CFTimeInterval) {

        switch state {
        case .hidden, .animHide: return
        default: break
        }

        func hideNow() {
            relocate(dot:dotNow, hideChild:false)
            updateDock(.animHide, "hideDock")
        }

        hideTimer?.invalidate()
        hideTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            hideNow()
        }
    }

}
