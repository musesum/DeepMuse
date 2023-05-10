
//  Created by warren on 7/19/19.
//  Copyright © 2019 DeepMuse All rights reserved.

import Foundation
import QuartzCore
import UIKit

extension CGRect {

    public func horizontal() -> Bool {
        return size.width > size.height
    }

    public func between(_ p: CGPoint) -> CGPoint {

        let x = origin.x
        let y = origin.y
        let w = size.width
        let h = size.height

        let pp = CGPoint(x: max(x, min(p.x, x + w)),
                         y: max(y, min(p.y, y + h)))
        return pp
    }
    public func between(_ p: CGRect, _ insets: UIEdgeInsets = .zero) -> CGRect {

        let x = origin.x + insets.left
        let y = origin.y + insets.right
        let w = size.width - insets.left - insets.right
        let h = size.height - insets.top - insets.bottom

        var px = p.origin.x
        var py = p.origin.y
        var pw = p.size.width
        var ph = p.size.height

        if pw > w { pw = w }
        if ph > h { ph = h }
        if px < insets.left { px = insets.left }
        if py < insets.top { py = insets.top }
        if px + pw > x + w { px = x + w - pw }
        if py + ph > y + h { py = y + h - ph }

        let pp = CGRect(x: px, y: py, width: pw, height: ph)

        return pp
    }
    public var center: CGPoint {
        get {
            let x = origin.x
            let y = origin.y
            let w = size.width
            let h = size.height
            let pp = CGPoint(x: x + w/2, y: y + h/2)
            return pp
        }
    }

    /// normalize to 0...1
    public func normalize() -> ClipRect {
        let x = origin.x
        let y = origin.y
        let w = size.width
        let h = size.height

        let pp = ClipRect(x: x / w,
                          y: y / h,
                          width: (w - 2*x) / w,
                          height:(h - 2*y) / h)
        return pp
    }


    /// scale up for a point p normalized between 0...1
    public func scaleUpFrom01(_ p: CGPoint) -> CGPoint {

        let x = origin.x
        let y = origin.y
        let w = size.width
        let h = size.height

        let pp = CGPoint(x: x + p.x * w,
                         y: y + p.y * h)
        return pp
    }

    /// scale down to a point p normalized between 0...1
    public func normalizeTo01(_ p: CGPoint) -> CGPoint {

        let x = origin.x
        let y = origin.y
        let w = size.width
        let h = size.height

        let pp = between(p)
        let xx = w == 0 ? 0 : (pp.x - x) / w
        let yy = h == 0 ? 0 : (pp.y - y) / h
        let ppp = CGPoint(x: xx,  y: yy)
        return ppp
    }

    func cornerDistance() -> CGFloat {

        let w = size.width
        let h = size.height

        let d = sqrt((w*w)+(h*h))
        return d
    }


    /// before and after are two finger pinch bounding rectangle.
    /// while pinching, rescale the current rect
    /// while shifting center shifting based on direction of pinch
    func reScale(before: CGRect, after: CGRect) -> CGRect {

        let scale = after.cornerDistance() / before.cornerDistance()
        let delta = after.center - before.center

        let x = origin.x
        let y = origin.y
        let w = size.width
        let h = size.height

        let r = CGRect(x: x - delta.x,
                       y: y - delta.y,
                       width: w * scale,
                       height: h * scale)
        return r
    }
}

extension CGPoint {

    public static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        let p = CGPoint(x: lhs.x - rhs.x,
                        y: lhs.y - rhs.y)
        return p
    }

    public static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        let p = CGPoint(x: lhs.x + rhs.x,
                        y: lhs.y + rhs.y)
        return p
    }

    public static func / (lhs: CGPoint, rhs: CGPoint) -> CGPoint {

        let xx = rhs.x > 0 ? lhs.x / rhs.x : 0
        let yy = rhs.y > 0 ? lhs.y / rhs.y : 0
        let p = CGPoint(x: xx, y: yy)
        return p
    }
    
    public static func / (lhs: CGPoint, rhs: CGSize) -> CGPoint {

        let xx = rhs.width  > 0 ? lhs.x / rhs.width  : 0
        let yy = rhs.height > 0 ? lhs.y / rhs.height : 0
        let p = CGPoint(x: xx, y: yy)
        return p
    }
    public static func * (lhs: CGPoint, rhs: CGFloat) -> CGPoint {

        let xx = lhs.x * rhs
        let yy = lhs.y * rhs
        let p = CGPoint(x: xx, y: yy)
        return p
    }
    public func distance(_ from: CGPoint) -> CGFloat {
        
        return sqrt( (x-from.x) * (x-from.x) + (y-from.y) *  (y-from.y) )
    }
    
    /// round to nearest grid
    public func grid(_ divisions: CGFloat) -> CGPoint {
        if divisions > 0 {
            return  CGPoint(x: round(x * divisions) / divisions,
                            y: round(y * divisions) / divisions)
        }
        return self
    }

}


extension CGSize {

    public static func - (lhs: CGSize, rhs: CGSize) -> CGSize {
        let ww = lhs.width - rhs.width
        let hh = lhs.height - rhs.height
        let s = CGSize(width: ww, height: hh)
        return s
    }
    public static func + (lhs: CGSize, rhs: CGSize) -> CGSize {
        let ww = lhs.width + rhs.width
        let hh = lhs.height + rhs.height
        let s = CGSize(width: ww, height: hh)
        return s
    }

    public static func / (lhs: CGSize, rhs: CGFloat) -> CGSize {

        let ww = lhs.width / rhs
        let hh = lhs.height / rhs
        let s = CGSize(width: ww, height: hh)
        return s
    }
    public static func * (lhs: CGSize, rhs: CGFloat) -> CGSize {

        let ww = lhs.width * rhs
        let hh = lhs.height * rhs
        let s = CGSize(width: ww, height: hh)
        return s
    }
}

extension CGFloat {

    public func range(_ min: CGFloat, _ max: CGFloat) -> CGFloat {
        if      self < min { return min }
        else if self > max { return max }
        else               { return self }

    }
}


