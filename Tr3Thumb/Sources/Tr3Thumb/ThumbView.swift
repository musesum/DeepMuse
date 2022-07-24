import UIKit
import QuartzCore
import MuUtilities

public class ThumbView: UIView {

    var radius    = CGFloat(1)
    var scaled    = CGFloat(0.25)
    var thumbSize = CGSize.zero
    var imageView : UIImageView?
    var blurView  : UIVisualEffectView?

    private var _scale =  CGFloat(1)

    var scale: CGFloat {

        set(scale_) {

            _scale = scaled * max(scale_,0.001)
            radius = thumbSize.width * scale / 2
            reorientCenter()
        }
        get {
            return _scale
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    init() {
        super.init(frame:.zero)
    }

    func addImage(_ image:UIImage) {

        if let imageRef = image.cgImage {
            let w = imageRef.width
            let h = imageRef.height
            thumbSize = CGSize(width: w, height: h)
            frame = CGRect(x: 0, y: 0, width: w, height: h)
            imageView = UIImageView(image: image)
            addSubview(imageView!)
            layer.cornerRadius = thumbSize.width / 2
            layer.masksToBounds = true
        }
    }
    
    func addBlur() {
        
        let blurEffect = UIBlurEffect(style: .dark)
        blurView = UIVisualEffectView(effect: blurEffect)
        if let blurView = blurView {
            blurView.frame = bounds
            blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            blurView.layer.cornerRadius = 16
            blurView.clipsToBounds = true
            insertSubview(blurView, at: 0)
        }
    }

    func reorientCenter() {

        let radians = OrienteDevice.shared.radians
        transform = CGAffineTransform.identity
            .rotated(by: radians)
            .scaledBy(x: _scale, y: _scale)
    }

    func radius(forScale scale: CGFloat) -> CGFloat {

        let sizeScale = CGFloat(scaled * scale)
        let radius = CGFloat((thumbSize.width * CGFloat(sizeScale)) / 2)
        return radius
    }

    func contains(_ point_: CGPoint) -> Bool {

        // x,y coordinates for _thumbPulse center is (_radius, _radius)
        let delta = CGPoint(x: point_.x - self.radius, y: point_.y - self.radius)
        let radius = sqrt(delta.x * delta.x + delta.y * delta.y)

        if round(CGFloat(radius)) > self.radius {
            return false
        } else {
            return true
        }
    }

    func setOnlyScale(_ scale_: CGFloat) {
        scale = scaled * scale_
        radius = thumbSize.width * scale / 2
    }

}
