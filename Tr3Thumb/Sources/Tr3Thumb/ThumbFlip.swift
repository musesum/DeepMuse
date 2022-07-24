import UIKit

class ThumbFlip: UIView {

    var back: UIImageView!
    var front: UIImageView!
    var flipped = false // current state of back and front visible
    var twisted = false // use twisting animation
    var animating = false // animating a twist state

    convenience init(frame frame_: CGRect, back back_: UIImage?, front front_: UIImage?) {

        self.init(frame: frame_)

        animating = false
        twisted = false
        flipped = false

        let backPath = back_ ?? UIImage.getIconPath("/tr3/control/png", name: "icon.thumb.back.png")

        back = UIImageView(image: backPath)
        front = UIImageView(image: front_)

        back?.frame = frame_
        front?.frame = frame_

        addSubview(front)
        addSubview(back)
    }

    convenience init(_ frame_: CGRect,_ icon_: UIImage?,_ value: Bool) {

        self.init(frame: frame_)

        animating = false
        twisted = false
        flipped = false

        if let img = UIImage(named: "icon.thumb.back.png") {
            back = UIImageView(image: img)
        }
        front = UIImageView(image: icon_)
        back?.frame = frame_
        front?.frame = frame_

        addSubview(front)
        addSubview(back)
        setFlipped(value)
    }
    func toggleValue() {
        setFlipped(!flipped)
    }
    func setFlipped(_ flipped_: Bool) {

        flipped = flipped_

        if twisted       { animateTwist()  }
        else if !flipped { back?.superview?.bringSubviewToFront(back) }
        else             { front?.superview?.bringSubviewToFront(front) }
    }

    func makeTwisted() {
        twisted = true
        if flipped { front?.alpha = 1 ; back?.alpha = 0 }
        else       { front?.alpha = 0 ; back?.alpha = 1 }
    }

// MARK: - Flip Button
    static let animateTwistTransformNormal    = CGAffineTransform.identity.rotated(by: 0)
    static let animateTwistTransformClockwise = CGAffineTransform.identity.rotated(by: 0 + .pi - 0.01)
    static let animateTwistTransformCounter   = CGAffineTransform.identity.rotated(by: 0 - .pi + 0.01)

    func animateTwist() {

        if animating {

            let currentLayer = layer.presentation()
            layer.removeAllAnimations()
            if let transform = currentLayer?.transform {
                layer.transform = transform
            }
            layer.position = currentLayer?.position ?? CGPoint.zero
        }
        else if flipped {

            back?.transform = ThumbFlip.animateTwistTransformNormal
            front?.transform = ThumbFlip.animateTwistTransformCounter
        }
        else {
            front?.transform = ThumbFlip.animateTwistTransformNormal
            back?.transform = ThumbFlip.animateTwistTransformCounter
        }

        animating = true

        UIView.animate(withDuration: AnimDuration, delay: 0, options:AnimUser, animations: {

            if  let back  = self.back,
                let front = self.front {

                if self.flipped {

                    back.transform = ThumbFlip.animateTwistTransformClockwise
                    front.transform = ThumbFlip.animateTwistTransformNormal
                    back.alpha = 0
                    front.alpha = 1
                }
                else {

                    back.transform = ThumbFlip.animateTwistTransformNormal
                    front.transform = ThumbFlip.animateTwistTransformClockwise
                    back.alpha = 1
                    front.alpha = 0
                }
            }
        }) { finished in
            if finished {
                self.animating = false
            }
        }

    }

}
