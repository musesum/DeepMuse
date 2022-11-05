//
//  Created by warren on 7/17/19.

import Foundation
import QuartzCore
import UIKit

public class MuBezel: UIView {

    public override func draw(_ rect: CGRect) {

        let maskLayer = CAShapeLayer()
        maskLayer.frame = bounds

        let path = UIBezierPath()
        let size = frame.size
        let h = size.height
        let w = size.width
        let r: CGFloat = min(h, w) / 2

        let p1 = CGPoint(x: r, y: r)
        let p2 = CGPoint(x: w - r, y: r)
        let p3 = CGPoint(x: w - r, y: h - r)
        let p4 = CGPoint(x: r, y: h - r)

        let q1 = CGPoint(x: 0, y: r)        // let q2 = CGPoint(x: r, y: 0)
        let q3 = CGPoint(x: w - r, y: 0)    // let q4 = CGPoint(x: w, y: r)
        let q5 = CGPoint(x: w, y: h - r)    // let q6 = CGPoint(x: w - r, y: h)
        let q7 = CGPoint(x: r, y: h)        // let q8 = CGPoint(x: 0, y: h - r)

        path.move(to: q1)
        path.addArc(withCenter: p1, radius: r, startAngle: -2 * .pi / 2, endAngle: -1 * .pi / 2, clockwise: true)
        path.addLine(to: q3)
        path.addArc(withCenter: p2, radius: r, startAngle: -1 * .pi / 2, endAngle: 0 * .pi / 2, clockwise: true)
        path.addLine(to: q5)
        path.addArc(withCenter: p3, radius: r, startAngle: 0 * .pi / 2, endAngle: 1 * .pi / 2, clockwise: true)
        path.addLine(to: q7)
        path.addArc(withCenter: p4, radius: r, startAngle: 1 * .pi / 2, endAngle: 2 * .pi / 2, clockwise: true)
        path.close()

        UIColor(white: 1, alpha: 0.5).setStroke()
        path.lineWidth = 2
        path.stroke()

        //    maskLayer.strokeColor = [[UIColor colorWithWhite: .5 alpha: 1] CGColor];
        maskLayer.fillColor = UIColor(white: 0, alpha: 0.20).cgColor
        maskLayer.backgroundColor = UIColor.clear.cgColor
        maskLayer.path = path.cgPath

        let superview = self.superview
        removeFromSuperview()
        layer.mask = maskLayer
        superview?.insertSubview(self, at: 0)
    }
}
