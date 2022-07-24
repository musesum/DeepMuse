//  Converted to Swift 5 by Swiftify v5.0.37171 - https://objectivec2swift.com/
import QuartzCore
import UIKit

public class ThumbDot: ThumbView {

    var panel: ThumbPanel? // control panel
    var target: Any?

    var beganTime = CFTimeInterval(0)
    var beganPoint = CGPoint.zero
    var endedPoint = CGPoint.zero

    var dragging = false
    var name = ""
    var touchMove = CGPoint.zero
    var calcCenter = CGPoint.zero
    var dockCenter = CGPoint.zero // calculated center irregardless of updating with finger
    var selected = false

    var thumbDock: ThumbDock! 

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

    }
    override init() {
        super.init()
        addBlur()
        scaled = 0.25
    }

    convenience init(_ thumbDock_: ThumbDock, _ name: String,_ type: String,_ image: UIImage?,_ panel_: ThumbPanel?,_ target: Any?) {

        self.init()
        thumbDock = thumbDock_
        if let img = image { addImage(img) }
        self.name = name
        panel = panel_
        self.target = target
    }

    convenience init(_ thumbDock_: ThumbDock, _ name: String,_ type: String,_ icon: String,_ panel: ThumbPanel?,_ target: Any?) {

        self.init(thumbDock_,name,type,UIImage(named:icon),panel,target)
    }

    func isDotNow() -> Bool {
        return thumbDock.dotNow == self
    }
    func tap1() {
        ThumbPrint("Dot_tap1 name: \(name)")
        thumbDock.hideTimer?.invalidate()
        thumbDock.relocate(dot: self, hideChild: true)
        thumbDock.hideDock(after: 0.50)
        panel?.dotTap1()
    }

    func tap2() {
        ThumbPrint("Dot_tap1 name: \(name)")
        panel?.dotTap2()
    }

// MARK: - Touches
    
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        ThumbPrint("Dot_touchesBegan")
        
        dragging = false
        
        let thisTime = CFAbsoluteTimeGetCurrent()
        let deltaTime = thisTime - beganTime
        beganTime = thisTime
        
        let touch = touches.first
        beganPoint = touch?.location(in: nil) ?? CGPoint.zero
        touchMove = beganPoint
        
        if deltaTime < DoubleTapTime { tap2() }
        else                         { tap1() }
        panel?.thumbTouched(.began)
    }
    
    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        panel?.thumbTouched(.moved)
    }
    override public func touchesEnded    (_ touches: Set<UITouch>, with event: UIEvent?) {
        panel?.thumbTouched(.ended) }
    
    override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        panel?.thumbTouched(.cancelled) }
}
