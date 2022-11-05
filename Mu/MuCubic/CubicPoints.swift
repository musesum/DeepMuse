import QuartzCore


class Point4 {  // 4 2d points

    var p: [CGPoint] = [.zero, .zero, .zero, .zero]

   
    init(_ p0: CGPoint,
         _ p1: CGPoint,
         _ p2: CGPoint,
         _ p3: CGPoint) {

        p = [p0, p1, p2, p3]
    }
    init(_ p4: Point4) {

        for i in 0..<4 {
            p[i] = p4.p[i]
        }
    }
}

class Float4 { // 4 1D points

    var f: [CGFloat] = [0, 0, 0, 0]

    init(_ f0: CGFloat,
         _ f1: CGFloat,
         _ f2: CGFloat,
         _ f3: CGFloat) {

        f = [f0, f1, f2, f3]
    }
    init(_ f4: Float4) {
        for i in 0..<4 {
            f[i] = f4.f[i]
        }
    }
}

