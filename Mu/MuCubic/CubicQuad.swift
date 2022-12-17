
import QuartzCore

public struct QuadXYR {

    var point4 = Point4(.zero, .zero, .zero, .zero) // 4 control points in 2d space for position
    var float4 = Float4(0, 0, 0, 0) // 4 control floats in 1d for radius
    var cubicXYR = CubicXYR() // coeficients for control poinnts
    var index = 0

    public init() {
    }
    mutating func clearAll() {
        point4 = Point4(.zero, .zero, .zero, .zero)
        float4 = Float4(0, 0, 0, 0)
        index = 0
    }

    /// Add cubic poly points.Problem is that control points are drawn in real time.
    /// So need to make special cases for 1st control points.
    /// For example for the first point a, b, c, d, e :
    ///
    ///          control   draw
    ///          position  from
    ///       t  0 1 2 3
    ///       0: a a a a  a to a
    ///       1: a a b b  a to b
    ///       2: a b b c  b to b (redundant)
    ///       3: a b c d  b to c
    ///       4: b c d e  c to d // continue for f, g, ...
    ///
    public mutating func addXYR(_ p: CGPoint,
                                _ f: CGFloat,
                                _ isDone: Bool) {

        let p0 = point4.p[0]
        let p1 = point4.p[1]
        let p2 = point4.p[2]
        let p3 = point4.p[3]

        let f0 = float4.f[0]
        let f1 = float4.f[1]
        let f2 = float4.f[2]
        let f3 = float4.f[3]

        switch index {                                               // 0 1 2 3  draw
        case 0:  point4 = Point4(p,  p,  p,  p) ; float4 = Float4(f,  f,  f,  f) // a a a a  a-a
        case 1:  point4 = Point4(p0, p1, p,  p) ; float4 = Float4(f0, f1, f,  f) // a a b b  a-b
        case 2:  point4 = Point4(p0, p2, p3, p) ; float4 = Float4(f0, f2, f3, f) // a b b c  b-b
        default: point4 = Point4(p1, p2, p3, p) ; float4 = Float4(f1, f2, f3, f) // a b c d  b-c
        }
        //print(scriptPoints())


        if isDone { // reset index at end of stroke
            // do not use the p0...p3 r0...r3 references, as they point to an old locations
            point4 = Point4(point4.p[0], point4.p[1], point4.p[3], point4.p[3])
            float4 = Float4(float4.f[0], float4.f[1], float4.f[3], float4.f[3])
            index = 0 // reset index to beginning of next stroke
        }
        else { // or continue to next index point
            index += 1
        }
        cubicXYR.makeCoeficients(point4, float4)
    }
    // get the maximum linear interval beteen p4's p[2] and p[3]
    func maximumMidInterval() -> CGFloat {
        let deltaX = abs(point4.p[2].x - point4.p[3].x)
        let deltaY = abs(point4.p[2].y - point4.p[3].y)
        return fmax(deltaX, deltaY)
    }

    // return point (xx, yy) from z1, which is in 0...1
    func getXY(_ z1: CGFloat) -> CGPoint {
        let xx = cubicXYR.x.getFloat(z1)
        let yy = cubicXYR.y.getFloat(z1)
        return CGPoint(x: xx, y: yy)
    }
    // return radius rr interpolated from z1, which is in 0...1
    func getR(_ z1: CGFloat) -> CGFloat {
        let rr = cubicXYR.r.getFloat(z1)
        return rr
    }
    func scriptPoints() -> String {

        let s = String(format:"%i: (%3.f,%3.f):%.f  (%3.f,%3.f):%.f  (%3.f,%3.f):%.f  (%3.f,%3.f):%.f",
                       index,
                       point4.p[0].x, point4.p[0].y, float4.f[0],
                       point4.p[1].x, point4.p[1].y, float4.f[1],
                       point4.p[2].x, point4.p[2].y, float4.f[2],
                       point4.p[3].x, point4.p[3].y, float4.f[3])
        return s
    }

    public func iterate12()  {

        // if index<2 { return }

        let p1 = point4.p[1]
        let p2 = point4.p[2]

        // choose longest interval between x and y axis for filling arc
        let iterations = max(1, max(abs(p1.x - p2.x), abs(p1.y - p2.y)))
        let increment = 1.0 / iterations

        // iterate between 0 and 1
        for z1: CGFloat in stride(from: 0, to: 1, by: increment) {

            let p = getXY(z1)
            let r = getR(z1)

            TouchDraw.shared.drawPoint(p, r)
        }
    }
}
