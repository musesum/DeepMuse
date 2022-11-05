import QuartzCore

struct CubicPoly {
    
     var c0 = CGFloat(0)
     var c1 = CGFloat(0)
     var c2 = CGFloat(0)
     var c3 = CGFloat(0)
    
    func getFloat(_  t: CGFloat) -> CGFloat {
        
        let t2 = t*t
        let t3 = t2*t
        let r = c0 + c1*t + c2*t2 + c3*t3
        return r
    }

    /// Compute coefficients for a cubic polynomial
    ///
    ///     p(s) = c0 + c1*s + c2*s^2 + c3*s^3 //such that
    ///     p(0) = x0, p(1) = x1 // and
    ///     p'(0) = t0, p'(1) = t1.
    ///
    static func MakeCubicPoly(_ f0: CGFloat,
                              _ f1: CGFloat,
                              _ t0: CGFloat,
                              _ t1: CGFloat) -> CubicPoly {

        var cp = CubicPoly()

        cp.c0 = f0
        cp.c1 = t0
        cp.c2 = -3*f0 + 3*f1 - 2*t0 - t1
        cp.c3 =  2*f0 - 2*f1 + t0 + t1
        return cp
    }

    func getPoint(_ t: CGFloat,
                  _ xy: CubicXY) -> CGPoint {

        let p = CGPoint(x: xy.x.getFloat(t),
                        y: xy.y.getFloat(t))
        return p
    }

    ///  standard Catmull-Rom spline: interpolate between f1 and f2 with
    /// previous/following points f1/f4
    /// (we don't need this here, but it's for illustration)
    ///
    static func MakeCatmullRom(_ f4: Float4) -> CubicPoly {

        // Catmull-Rom with tension 0.5
        let f0 = f4.f[0]
        let f1 = f4.f[1]
        let f2 = f4.f[2]
        let f3 = f4.f[3]

        let cp = MakeCubicPoly(f1, f2, 0.5 * (f2-f0), 0.5 * (f3-f1))
        return cp
    }
}
