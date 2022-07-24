import Par // Visitor
import UIKit
import MuUtilities

class ThumbTouch: UIView {

    var id        = Visitor.nextId()
    var span      = CGRect.zero         // frame for center of thumb -radius -border
    let LoopTime  = 1.0/60.0            // animation update loo time
    var timeLag   = CFTimeInterval(0.5) // time to reach touchNext
    var beganTime = CFTimeInterval(0)   // time for touchNext for animating interim points
    var touchNext = CGPoint.zero        // where user touched, target for animated pointNext
    var pointNext = CGPoint.zero        // current position animating to touchNext
    var tap2Time  = CFTimeInterval(0)   // start time for double tap, animate
    var tap2Val   = CGPoint(x:-1,y:-1)  // position for double tap, -1 for nearest grid
    var timer     = Timer()             // animation timer
    var panel     : ThumbPanel?         // control panel containing many ThumbTouches


    /// add new touch point from user
    ///
    /// - parameter time: time of touch
    /// - parameter point: normalized touch point 0...1
    func addTouchPoint(_ time:CFTimeInterval,_ point: CGPoint) {
        touchNext = point
        beganTime = time
    }

    func getNextPoint() -> CGPoint {
        
        let timeNext = CFAbsoluteTimeGetCurrent()
        let pointPrev = pointNext
        let deltaTime = timeNext - beganTime
        let deltaPoint = touchNext - pointPrev
        let factor = CGFloat(timeLag <= 0 ? 1 : min(1,deltaTime / timeLag))
        pointNext = pointPrev + (deltaPoint * factor)
        //print( String(format:"Δt:%.3f Δp:(%.2f,%.2f) pNext:(%.2f,%.2f) tNext:(%.2f,%.2f)", deltaTime, deltaPoint.x, deltaPoint.y, pointNext.x, pointNext.y, touchNext.x, touchNext.y))
        return pointNext

    }


    /// normalize touch in view to between 01,before animating changes
    ///
    /// - parameter pv: view coordinates
    ///
    func userSetCursor(_ pv: CGPoint) {

        let pn = span.normalizeTo01(pv)
        addTouchPoint(CFAbsoluteTimeGetCurrent(),pn)
        animateCursor()
    }

    /// animate transition between points.
    /// block with animating while time already active
    ///
    /// - note: intially started by user action, and then calls itself via timer.
    ///
    func animateCursor () {

        pointNext = getNextPoint()
        updateCursor(pointNext)
        updateTr3Node(pointNext)

        if pointNext == touchNext {
             // do nothing
        }
        else {
            timer = Timer.scheduledTimer(withTimeInterval: LoopTime, repeats: false)  {_ in
                self.animateCursor()
                
            }
        }
    }
    // MARK: updates -------------------------

     /// notify subclass that user directly changed value
    func updateTr3Node(_ p01:CGPoint) {
        print("***  \(#function) needs override")
    }

    /// Notify subclass that user directly changed value.
    /// Often used to block changes from Tr3Graph.
    func updateTr3User(_ user:Bool) {
        print("*** \(#function) needs override")
    }

    func updateCursor(_ p01:CGPoint) {
          print("*** \(#function) needs override")
    }
    // MARK: touch  updates -------------------------

    /// user double tapped
    func doubleTap(_ p:CGPoint) {

        tap2Time = CFAbsoluteTimeGetCurrent()

        let norm = span.normalizeTo01(p)

        // -1 will allign to nearest normalized xy: [0, .5, 1], [0, .5, 1],
        if tap2Val.x < 0  {
            let grid = norm.grid(2.0)
            addTouchPoint(tap2Time,grid)
            animateCursor()
        }
        else {
            let x = span.origin.x
            let y = span.origin.y
            let w = span.size.width
            let h = span.size.height

            let pp = CGPoint(x: x + tap2Val.x * w,
                             y: y + tap2Val.y * h)

            addTouchPoint(tap2Time,pp)
            animateCursor()
        }
    }


    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

        updateTr3User(true)

        let timeNext = CFAbsoluteTimeGetCurrent()
        let deltaTap1 = timeNext - beganTime
        let deltaTap2 = timeNext - tap2Time

        if let touch = touches.first {
            let p = touch.location(in: self)

            if deltaTap1 < 0.5 {
                doubleTap(p)
            }
            else if deltaTap2 < 0.5 {
                // don't do do anything for a half second after a double tap
            }
            else {
                tap2Time = 0
                userSetCursor(p)
            }
            panel?.thumbTouched(.began)
        }
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if CFAbsoluteTimeGetCurrent() - tap2Time < 0.5 { return }
        let p = touches.first!.location(in: self)
        userSetCursor(p)
        panel?.thumbTouched(.moved)
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if CFAbsoluteTimeGetCurrent() - tap2Time < 0.5 { return }
        if let p = touches.first?.location(in: self) {
            userSetCursor(p)
            panel?.thumbTouched(.ended)
        }
    }
    override func touchesCancelled(_ touches: Set<UITouch>?, with event: UIEvent?) {
        if CFAbsoluteTimeGetCurrent() - tap2Time < 0.5 { return }
        if let p = touches?.first?.location(in: self) {
            userSetCursor(p)
            panel?.thumbTouched(.ended)
        }
    }
}
