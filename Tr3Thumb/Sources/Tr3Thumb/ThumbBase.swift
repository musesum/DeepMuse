import Par
import Tr3
import UIKit

class ThumbBase: ThumbTouch {

    var caching = false

    var title = "??"
    var tr3Node: Tr3? // interface to main node
    var tr3User: Tr3? // changed by user (not tr3)

    var iconName = "icon.pearl.white.png"
    var icon : UIImage?
    var thumb : UIView?
    var radius = CGFloat(0)
    var cursor = CGPoint.zero
    var horizontal = true
    
    /// init via tr3 chidren
    convenience init(tr3: Tr3,_ panel_: ThumbPanel) {

        self.init()
        title = tr3.name
        panel = panel_

        func initTr3Node(_ child:Tr3) {

            tr3Node = child
            if let node = tr3Node {
                if let p = node.CGPointVal() {
                    pointNext = p
                }
                else if let f = node.CGFloatVal() {
                    pointNext = self.horizontal ? CGPoint(x:f,y:0) : CGPoint(x:0,y:f)
                }
                node.addClosure(valueClosure)
            }
            else {
                pointNext = .zero
            }

        }
        func initIcon(_ name:String?) {

            if let name = name {
                iconName = name
                icon = UIImage(named: iconName)
            }
        }
        for child in tr3.children {

            switch child.name {
            case "title"   : title   = child.StringVal()  ?? "??"
            case "frame"   : frame   = child.CGRectVal()  ?? .zero
            case "tap2"    : tap2Val = child.CGPointVal() ?? .zero
            case "lag"     : timeLag = child.DoubleVal()  ?? 0
            case "radius"  : radius  = child.CGFloatVal() ?? .zero
            case "value"   : initTr3Node(child)
            case "user"    : tr3User = child
            case "default" : child.addClosure(valueClosure)
            case "icon"    : initIcon(child.StringVal())
            case "type"    : break
            default        : print("*** unknown child:\(tr3.name).\(child.name)")
            }
        }
        updateBase()
        updateCursor(pointNext)
        updateTr3Node(pointNext)
    }

    // MARK: tr3 closures -------------------------

    func valueClosure(_ tr3:Tr3,_ visitor:Visitor) {
        if visitor.newVisit(id),
            let p01 = tr3.CGPointVal() {
            //print("V", terminator:" ")
            updateCursor(p01) // changes pointNext
        }
    }

    // MARK: model for view -------------------------

    /// setup icon for thumb, and span for allowed motion
    func updateBase() {

        icon = UIImage(named: iconName)

        let w = frame.size.width
        let h = frame.size.height
        let b = CGFloat(2)   // border
        let r = fmin(w,h)/2 - b

        radius = radius == 0 ? r : radius
        span = CGRect(x: radius + b,
                      y: radius + b,
                      width:  w - radius*2 - b*2,
                      height: h - radius*2 - b*2)
    }

    // MARK: tr3 updates -------------------------

    /// Update "value" for Tr3 Graph
    ///
    /// - parameter P01: current value normalized between 0...1
    /// - note: Visitor(id) makes sure that closure breaks loop
    ///
    override func updateTr3Node(_ p01:CGPoint) {

        if let tr3Node = tr3Node {
            if tr3Node.val is Tr3ValTuple {
                if caching { Tr3Cache.add(tr3Node, p01, [.activate], Visitor(id)) }
                else       { tr3Node.setVal(       p01, [.activate], Visitor(id)) }
            }
            else {
                let f = horizontal ? p01.x : p01.y
                if caching { Tr3Cache.add(tr3Node, f, [.activate], Visitor(id)) }
                else       { tr3Node.setVal(       f, [.activate], Visitor(id)) }
            }
        }
    }
    /// Change in value came from "user" not closure
    ///
    /// - parameter P01: current value normalized between 0...1
    /// - note: Visitor(id) makes sure that closure breaks loop
    ///
    override func updateTr3User(_ user:Bool) {

        if let tr3User = tr3User {

            let isUser = CGFloat(user ? 1 : 0)
            if caching { Tr3Cache.add(tr3User, isUser, [.activate], Visitor(id)) }
            else       { tr3User.setVal(       isUser, [.activate], Visitor(id)) }
        }
    }

    // MARK: view update -------------------------

    override func updateCursor(_ p01:CGPoint) {

        cursor = span.scaleUpFrom01(p01)
        DispatchQueue.main.async(execute: {
            self.thumb?.center = self.cursor
        })
    }

}
