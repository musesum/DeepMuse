
import QuartzCore
import UIKit


class ThumbSwitch: ThumbSlider {

    override func userSetCursor(_ ignored: CGPoint) {

        if horizontal   { touchNext.x = touchNext.x < 0.5 ? 1 : 0 }
        else            { touchNext.y = touchNext.y < 0.5 ? 1 : 0 }

        addTouchPoint(CFAbsoluteTimeGetCurrent(),touchNext)
        animateCursor()

        thumbFlip?.toggleValue()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

        updateTr3User(true)

        let thisTime = CFAbsoluteTimeGetCurrent()
        let deltaTime = thisTime - beganTime

        if deltaTime > 0.15 { userSetCursor(.zero) }
        panel?.thumbTouched(.began)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        panel?.thumbTouched(.moved)
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        panel?.thumbTouched(.ended)
    }
    override func touchesCancelled(_ touches: Set<UITouch>?, with event: UIEvent?) { panel?.thumbTouched(.cancelled)
    }
}
