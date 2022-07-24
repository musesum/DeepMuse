import UIKit
import Tr3

class ThumbTrigger: ThumbSlider {

    override func userSetCursor(_ location_: CGPoint) {

        animateCursor()
        thumbFlip?.flipped = pointNext.x > 0.5
    }
    
    /// Update "value" for Tr3 Graph
    ///
    /// - parameter P01: current value normalized between 0...1
    ///
    override func updateTr3Node(_ p:CGPoint) {

        var options = Tr3SetOptions([.activate,.zero1])
        if caching { options.insert(.cache) }
        tr3Node?.activate() // !! should cache the activation

    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

        updateTr3User(true) 

        let thisTime = CFAbsoluteTimeGetCurrent()
        let deltaTime = thisTime - beganTime
        beganTime = thisTime

        if deltaTime > 0.5 {
            updateTr3Node(CGPoint(x:1, y:1)) // not touches event; Tr3Event
        }
        panel?.thumbTouched(.began)
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        panel?.thumbTouched(.moved)
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        panel?.thumbTouched(.ended)
    }
    override func touchesCancelled(_ touches: Set<UITouch>?, with event: UIEvent?) {
        panel?.thumbTouched(.cancelled)
    }
}
