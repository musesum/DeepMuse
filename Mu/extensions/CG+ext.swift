// created by musesum on 1/10/24

import Foundation
extension CGRect {
    var script: String {
        "(\(minX.digits(0...2)),\(minY.digits(0...2)), \(width.digits(0...2)),\(height.digits(0...2)))"
    }
}
extension CGSize {
    public var script: String {
        "(\(width.digits(0...2)),\(height.digits(0...2)))"
    }
    public static func * (lhs: CGSize, rhs: CGFloat) -> CGSize {

        let ww = lhs.width * rhs
        let hh = lhs.height * rhs
        let s = CGSize(width: ww, height: hh)
        return s
    }
}
extension CGPoint {
    var script: String {
        "(\(x.digits(0...2)),\(y.digits(0...2)))"
    }
}
