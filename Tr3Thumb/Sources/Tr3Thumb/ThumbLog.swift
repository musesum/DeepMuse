
import Foundation
import MuUtilities

/// Create a time string, relative from the first time called.
///
///      0.00 Dock_TouchesBegan distance: 16.034686425229875 true
///      0.00 Dock_updateDock from: Dock_growDock .hidden=>.animShow
///     23.61 Dock_endedTouch panelShowing: true
///     24.62 Dock_updateDock from: hideDock .showing=>.animHide
///
func ThumbRuntime() -> String  {

    if  CFAbsoluteStartTime == 0 {
        CFAbsoluteStartTime = CFAbsoluteTimeGetCurrent()
    }
    let deltaTime = CFAbsoluteTimeGetCurrent() - CFAbsoluteStartTime
    let ret = String(format:"%7.2f ",deltaTime)
    return ret
}

func ThumbPrint(_ str: String) {
    //tileprint(ThumbRuntime() + str)
}
