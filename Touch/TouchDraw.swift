
import QuartzCore
import UIKit
import Tr3
import MuUtilities

class TouchDraw {

    static var shared = TouchDraw()
    private var brushTilt˚: Tr3?
    private var brushPress˚: Tr3?
    private var brushSize˚: Tr3?
    private var linePrev˚: Tr3?            // beginning of line
    private var lineNext˚: Tr3?            // end of line
    private var inForce˚: Tr3?             // pressure
    private var inRadius˚: Tr3?            // finger radius
    private var inAzimuth˚: Tr3?           // apple pencil
    private var brushTilt = false          // via brushTilt˚
    private var brushPress = true          // via brushPress˚
    private var brushSize = CGFloat(1)     // via brushSize˚
    private var linePrev = CGPoint.zero    // via linePrev˚
    private var lineNext = CGPoint.zero    // via lineNext˚
    private var inForce = CGFloat(0)       // via inForce˚
    private var inRadius = CGFloat(0)      // via inRadius˚
    private var inAzimuth = CGPoint.zero   // var inAzimuth˚
    internal var fillValue = Float(-1)
    internal var textureData: Data?

    
    func bindTr3(_ root: Tr3) {

        let sky = root.bindPath("sky")
        let input = sky.bindPath("input")
        let brush = sky.bindPath("draw.brush")
        let line = sky.bindPath("draw.line")

        brushTilt˚  = input.bindPath("tilt"   ) { t, _ in self.brushTilt  = t.BoolVal() }
        brushPress˚ = brush.bindPath("press"  ) { t, _ in self.brushPress = t.BoolVal() }
        brushSize˚  = brush.bindPath("size"   ) { t, _ in self.brushSize  = t.CGFloatVal() ?? 1 }
        linePrev˚   = line .bindPath("prev"   ) { t, _ in self.linePrev   = t.CGPointVal() ?? .zero }
        lineNext˚   = line .bindPath("next"   ) { t, _ in self.lineNext   = t.CGPointVal() ?? .zero }
        inForce˚    = input.bindPath("force"  ) { t, _ in self.inForce    = t.CGFloatVal() ?? 1 }
        inRadius˚   = input.bindPath("radius" ) { t, _ in self.inRadius   = t.CGFloatVal() ?? 1 }
        inAzimuth˚  = input.bindPath("azimuth") { t, _ in self.inAzimuth  = t.CGPointVal() ?? .zero }
    }

    public func update(_ item: TouchItem) -> CGFloat {

        // if using Apple Pencil and brush tilt is turned on
        if item.force > 0, brushTilt {
            let azi = CGPoint(x: -item.azimuth.dy, y: -item.azimuth.dx)
            inAzimuth˚?.setAny(azi, [.activate]) // will update local azimuth via Tr3Graph
        }
        
        // if brush press is turned on
        var radiusNow = CGFloat(1)
        if brushPress  {
            if inForce > 0 || item.azimuth.dx != 0.0 {
                inForce˚?.setAny(item.force, [.activate]) // will update local azimuth via Tr3Graph
                radiusNow = brushSize
            } else {
                inRadius˚?.setAny(item.radius, [.activate])
                radiusNow = inRadius
            }
        }
        else {
            radiusNow = brushSize
        }
        return radiusNow //PrintGesture("azimuth dXY(%.2f,%.2f)", item.azimuth.dx, item.azimuth.dy)
    }
    
    func drawPoint(_ point: CGPoint, _ radius: CGFloat, _ value: UInt32, _  buf: UnsafeMutablePointer<UInt32>, _ drawSize: CGSize) {

        if point == .zero { return }
        let p = point * UIScreen.main.scale
        let viewSize = SkyPipeline.shared.viewSize
        let p1 = MuAspect.viewPointToTexture(p, viewSize: viewSize, texSize: drawSize)
        // let p2 = MuAspect.texturePointToView(p1, texSize: drawSize, viewSize: viewSize) ; assert(p==p2)

        var radius = radius
        if brushPress {

            inRadius˚?.setAny(radius, [])
            brushSize˚?.setAny(radius, [.activate]) // will update brushSize via closure
            radius = brushSize
        }

        let r = radius * 2.0 - 1
        let r2 = Int(r * r / 4.0)
        let xs = Int(drawSize.width)
        let ys = Int(drawSize.height)
        let px = Int(p1.x)
        let py = Int(p1.y)

        var x0 = Int(p1.x - radius - 0.5)
        var y0 = Int(p1.y - radius - 0.5)
        var x1 = Int(p1.x + radius + 0.5)
        var y1 = Int(p1.y + radius + 0.5)

        if x0 < 0 { x0 += xs }
        if y0 < 0 { y0 += ys }
        while x1 < x0 { x1 += xs }
        while y1 < y0 { y1 += ys }

        if radius == 1 {
            buf[y0 * xs + x0] = value
            return
        }
        
        for y in y0 ..< y1 {

            for x in x0 ..< x1  {

                let xd = (x - px) * (x - px)
                let yd = (y - py) * (y - py)

                if xd + yd < r2 {

                    let yy = (y+ys)%ys      // wrapped pixel y index
                    let xx = (x+xs)%xs      // wrapped pixel x index
                    let ii = yy * xs + xx   // final pixel x, y index into buffer

                    buf[ii] = value         // set the buffer to value
                }
            }
        }
    }


    /**
     Either fill or draw inside texture

      - returns: true if filled, false if drawn
    */
    func drawTexture(_ bytes: UnsafeMutablePointer<UInt32>, size: CGSize) -> Bool {

        let w = Int(size.width)
        let h = Int(size.height)
        let count = w * h // count

        // single color
        func drawFill(_ val: UInt32) {
            for i in 0 ..< count {
                bytes[i] = val
            }
        }
        func drawData() {
            textureData?.withUnsafeBytes { texPtr in
                let tex32Ptr = texPtr.bindMemory(to: UInt32.self)
                for i in 0 ..< count {
                    bytes[i] = tex32Ptr[i]
                }
            }
        }

        if textureData != nil {
            fillValue = -1 // preempt fill after data
            drawData()
            textureData = nil
            return false //? true // did fill, so copy to 2nd texture
        }
        else if fillValue > 255 {
            drawFill(UInt32(fillValue))
            fillValue = -1
            return false //? true // did fill, so copy to 2nd texture
        }
        else if fillValue >= 0 {

            let v8 = UInt32(fillValue * 255)
            let val = (v8 << 24) + (v8 << 16) + (v8 << 8) + v8
            drawFill(val)
            fillValue = -1
            return false //? true // did fill, so copy to 2nd texture
        }
        else {
            // draw finger touches
            func draw(point: CGPoint, radius: CGFloat) {
                self.drawPoint(point, radius, 127, bytes, size)
            }
            func done() {
            }
            TouchView.shared.flushFingersBuf(draw, done)
            return false // didn't fill so don't duplicate 2nd texture
        }
    }

}
