import UIKit
import MuUtilities

class ThumbXY: ThumbBase {
    
    var box: MuDrawBox?
    var thumbBox: UIImageView?

    override func updateBase() {

        super.updateBase()

        let h = frame.size.height
        let w = frame.size.width
        let d = radius * 2
        let f = CGRect(x: 0, y: 0, width: w, height: h)

        box = MuDrawBox(frame: f, cornerRadius: radius)

        thumbBox = UIImageView(image: icon)
        thumbBox?.frame = CGRect(x: 0, y: 0, width: d, height: d)
        thumb = thumbBox

        if let box   = box   { addSubview(box) }
        if let thumb = thumb { addSubview(thumb) }
    }
}
