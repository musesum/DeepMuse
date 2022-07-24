import UIKit
import Tr3
import Par // Visitor
import MuUtilities

class ThumbSlider: ThumbBase {

    var thumbFlip: ThumbFlip!
    var bezel: UIView!

    override func updateBase() {

        super.updateBase()

        let h = frame.size.height
        let w = frame.size.width
        let d = radius * 2
        let f = CGRect(x: 0, y: 0, width: w, height: h)
        if w == h { bezel = UIView(frame: f) }
        else      { bezel = MuBezel(frame: f) }

        horizontal = w >= h

        let f2 =  CGRect(x: 0, y: 0, width: d, height: d)
        let val = (horizontal ? pointNext.x : pointNext.y) > 0
        thumbFlip = ThumbFlip(f2, icon, val)
        thumb = thumbFlip

        addSubview(bezel)
        addSubview(thumbFlip)
    }
    
    /// Update "value" for Tr3 Graph
    ///
    /// - parameter P01: current value normalized between 0...1
    ///
    override func updateTr3Node(_ p:CGPoint) {
        
        let v =  horizontal ? pointNext.x : pointNext.y
        var options = Tr3SetOptions([.activate,.zero1])
        if caching { options.insert(.cache) }
        tr3Node?.setVal(v, options, Visitor(id))
    }

    override func valueClosure(_ tr3:Tr3,_ visitor:Visitor) {
        //?? print("\(tr3.scriptLineage(3)).\(tr3.id): \(tr3.FloatVal() ?? -1)")
        if visitor.newVisit(id),
            let v = tr3.CGFloatVal() {

            let p = horizontal
                ? CGPoint(x:v, y:pointNext.y)
                : CGPoint(x:pointNext.x, y:v)
            touchNext = p
            updateCursor(p)
            
            let isFlipped = horizontal ? p.x > 0 : p.y > 0
            thumbFlip?.setFlipped(isFlipped)
        }
    }
}
