//  Created by warren on 7/17/19.
//  Copyright © 2019 DeepMuse All rights reserved.

import UIKit
import QuartzCore


class MuDrawBubble: UIView {
    var fromFrame = CGRect.zero
    var cornerRadius = CGFloat(0)
    var cornerArrowRadius = CGFloat(0)
    var arrowHeight = CGFloat(0)
    var arrowWidth = CGFloat(0)
    var viewPoint  = CGPoint.zero
    var arrowPoint = CGPoint.zero
    var arrowMid = CGPoint.zero


    init(size: CGSize, radius: CGFloat, from fromView: UIView?) {

        cornerRadius = radius
        cornerArrowRadius = cornerRadius
        arrowHeight = 16
        arrowWidth = arrowHeight
        let radii = arrowHeight * 2 + cornerRadius * 2

        if radii > size.width {
            let ratio = size.width / radii
            cornerArrowRadius *= ratio
            arrowWidth *= ratio
        }
        fromFrame = fromView?.frame ?? CGRect.zero

        viewPoint = CGPoint(x: fromFrame.origin.x + fromFrame.size.width / 2, y: fromFrame.origin.y)

        let frame = CGRect(x: viewPoint.x - size.width / 2, y: viewPoint.y - size.height - arrowHeight, width: size.width, height: size.height + arrowHeight)

        let boundSize = UIScreen.main.bounds.size ze;
        var f = frame

        if f.origin.x < 0 {
            f.origin.x = 0
        } else if f.origin.x + f.size.width > boundSize.width {
            f.origin.x = boundSize.width - f.size.width
        }
        arrowPoint = CGPoint(x: viewPoint.x - frame.origin.x, y: viewPoint.y - frame.origin.y)
        arrowMid = CGPoint(x: arrowPoint.x, y: arrowPoint.y - arrowHeight)
        let minEdge = cornerArrowRadius + arrowWidth

        if minEdge > arrowMid.x {

            arrowMid.x = minEdge
            let fromRadius = fromFrame.size.height / 2
            let fromCenter = CGPoint(x: fromRadius, y: arrowPoint.y + fromRadius)
            let radiusRatio = fromRadius / (fromRadius + arrowHeight)
            let deltaSize = CGSize(width: (arrowMid.x - fromCenter.x) * radiusRatio, height: (arrowMid.y - fromCenter.y) * radiusRatio)

            arrowPoint = CGPoint(x: fromCenter.x + deltaSize.width, y: fromCenter.y + deltaSize.height)
        } else if minEdge > frame.size.width - arrowMid.x {

            arrowMid.x = frame.size.width - minEdge
            let fromRadius = fromFrame.size.height / 2
            let fromCenter = CGPoint(x: frame.size.width - fromRadius, y: arrowPoint.y + fromRadius)
            let radiusRatio = fromRadius / (fromRadius + arrowHeight)
            let deltaSize = CGSize(width: (arrowMid.x - fromCenter.x) * radiusRatio, height: (arrowMid.y - fromCenter.y) * radiusRatio)

            arrowPoint = CGPoint(x: fromCenter.x + deltaSize.width, y: fromCenter.y + deltaSize.height)
        }
        super.init(frame: frame)

    }

    override func draw(_ rect: CGRect) {

        let maskLayer = CAShapeLayer()
        maskLayer.frame = bounds

        let path = UIBezierPath()
        let size = frame.size
        let r = cornerRadius
        let ra = cornerArrowRadius

        let p1 = CGPoint(x: 0, y: 0)
        let p2 = CGPoint(x: size.width, y: 0)
        let p3 = CGPoint(x: p2.x, y: size.height - arrowHeight)
        let p4 = CGPoint(x: p1.x, y: p3.y)

        let q1s = CGPoint(x: p1.x, y: p1.y + r)
        let q1e = CGPoint(x: p1.x + r, y: p1.y)
        let q2s = CGPoint(x: p2.x - r, y: p2.y)
        let q2e = CGPoint(x: p2.x, y: p2.y + r)
        let q3s = CGPoint(x: p3.x, y: p3.y - r)
        var q3e = CGPoint(x: p3.x - ra, y: p3.y)
        var q4s = CGPoint(x: p4.x + ra, y: p4.y)
        let q4e = CGPoint(x: p4.x, y: p4.y - r)

        var la3 = CGPoint(x: arrowMid.x + arrowWidth, y: arrowMid.y)
        var la4 = CGPoint(x: arrowMid.x - arrowWidth, y: arrowMid.y)

        if q3e.x < la3.x {
            q3e.x = (q3e.x + la3.x) / 2
            la3.x = q3e.x
        }

        if q4s.x > la4.x {
            q4s.x = (q4s.x + la4.x) / 2
            la4.x = q4s.x
        }

        path.move(to: q1s)
        path.addQuadCurve(to: q1e, controlPoint: p1)
        path.addLine(to: q2s)
        path.addQuadCurve(to: q2e, controlPoint: p2)
        path.addLine(to: q3s)
        path.addQuadCurve(to: q3e, controlPoint: p3)

        path.addLine(to: la3)
        path.addQuadCurve(to: arrowPoint, controlPoint: arrowMid)
        path.addQuadCurve(to: la4, controlPoint: arrowMid)

        path.addLine(to: q4s)
        path.addQuadCurve(to: q4e, controlPoint: p4)

        path.close()

        UIColor(white: 0, alpha: 0.62).setFill()
        UIColor(white: 1, alpha: 0.62).setStroke()
        path.fill()
        path.stroke()

        maskLayer.strokeColor = UIColor.white.cgColor
        maskLayer.fillColor = UIColor.darkGray.cgColor
        maskLayer.backgroundColor = UIColor.clear.cgColor
        maskLayer.path = path.cgPath

        //Don't add masks to layers already in the hierarchy!
        let superview = self.superview
        removeFromSuperview()
        layer.mask = maskLayer
        superview?.addSubview(self)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
