import UIKit

class ThumbTwist: ThumbSwitch {

    override func updateBase() {

        super.updateBase()
        
        let d = radius * 2 // diameter
        thumbFlip.frame = CGRect(x: 0, y: 0, width: d, height: d)
        thumbFlip?.makeTwisted()
    }
}
