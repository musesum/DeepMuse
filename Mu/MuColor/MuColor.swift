import Foundation

public struct MuColor {

    private var rgbDef = [Rgb]() // definition of Rgb ramps
    private var splice = ColorSplice.gradient // how to join this color set with its neighbors
    private let black = Rgb(0, 0, 0)
    private let white = Rgb(1, 1, 1)
    private var rendered = [Rgb]() // final render of palette with gradient fades

    public init (hsvs: [Hsv], _ splice: ColorSplice = .gradient) {
        self.splice = splice
        for hsv in hsvs {
            rgbDef.append(hsv.rgb())  // matching rgbs for hsvs
        }
        render(size: 256)
    }
    public init(rgbs: [Rgb], _ splice: ColorSplice = .gradient) {
        self.rgbDef = rgbs
        self.splice = splice
        render(size: 256)
    }

    public init(_ script: String) {
        for s in script {
            switch s {
            case "k": rgbDef.append(Hsv(  0,   0,   0).rgb()) // black
            case "w": rgbDef.append(Hsv(  0,   0, 100).rgb()) // white
            case "r": rgbDef.append(Hsv(  0, 100, 100).rgb()) // red
            case "o": rgbDef.append(Hsv( 30, 100, 100).rgb()) // orange
            case "y": rgbDef.append(Hsv( 60, 100, 100).rgb()) // yellow
            case "g": rgbDef.append(Hsv(120, 100, 100).rgb()) // green
            case "b": rgbDef.append(Hsv(240, 100, 100).rgb()) // blue
            case "i": rgbDef.append(Hsv(270, 100, 100).rgb()) // indigo
            case "v": rgbDef.append(Hsv(300, 100, 100).rgb()) // violet
            case "/": splice.insert(.gradient)
            case "K": splice.insert(.black)
            case "W": splice.insert(.white)
            case "Z": splice.insert(.zeno)
            case "F": splice.insert(.flip)
            case " ": break // skip space
            default: print("🚫 unknown Color shortcut")
            }
        }
        render(size: 256)
    }

    public static func fade(from: MuColor, to: MuColor, _ factor: Float) -> [Rgb] {

        var ret = [Rgb]()
        let count = min(from.rendered.count, to.rendered.count)
        let invFact = 1-factor
        for i in 0 ..< count {
            let fromi = from.rendered[i]
            let toi = to.rendered[i]
            let rgb = Rgb(fromi.r * invFact + toi.r * factor,
                          fromi.g * invFact + toi.g * factor,
                          fromi.b * invFact + toi.b * factor,
                          fromi.a * invFact + toi.a * factor)
            ret.append(rgb)
        }
        return ret
    }

    func makeRamp(_ span: Int, _ left: Rgb, _ mid: Rgb, _ right: Rgb) -> [Rgb] {

        var result = [Rgb]()
        let span1 = span/2
        let span2 = span-span1
        let span1f = Float(span1)
        let span2f = Float(span2)

        for i in 0 ..< span1 {
            let factor = Float(i)/span1f
            let invFact = 1 - factor
            let rgb = Rgb(left.r * invFact + mid.r * factor,
                          left.g * invFact + mid.g * factor,
                          left.b * invFact + mid.b * factor)
            result.append(rgb)
        }
        for i in 0 ..< span2 {
            let factor = Float(i)/span2f
            let invFact = 1 - factor
            let rgb = Rgb(mid.r * invFact + right.r * factor,
                          mid.g * invFact + right.g * factor,
                          mid.b * invFact + right.b * factor)
            result.append(rgb)
        }
        return result
    }
    func makeHard(_ span: Int, _ mid: Rgb) -> [Rgb]  {
        var result = [Rgb]()
        for _ in 0 ..< span {
            result.append(mid)
        }
        return result
    }

    /// render colors into a rgb array
    func renderSub(_ size: Int) -> [Rgb] {

        if size < 1 { return [] }
        if size == 1 { return [rgbDef[0]] }

        var result = [Rgb]()

        let count = rgbDef.count
        let increment = size / count
        var remain = size

        for i in 0 ..< count {

            let lefti = (i+count-1) % count  // wrap around to just left of my color
            let righti = (i+1) % count       // to right of my color with wrap around
            let left = rgbDef[lefti]         // to the left of my color
            let mid = rgbDef[i]              // my color
            let right = rgbDef[righti]       // to the right of my color

            let span = (i == count-1 ? remain : increment)
            remain -= span

            if      splice.contains(.black)    { result.append(contentsOf: makeRamp(span, black, mid, black)) }
            else if splice.contains(.white)    { result.append(contentsOf: makeRamp(span, white, mid, white)) }
            else if splice.contains(.gradient) { result.append(contentsOf: makeRamp(span, left, mid, right)) }
            else                               { result.append(contentsOf: makeHard(span, mid)) }
        }
        if splice.contains(.zeno) { result.append(contentsOf: renderSub((size+1)/2)) }
        return result
    }

    /// runder color palette from
    mutating func render(size: Int) {

        if splice.contains(.zeno) {
            // zeno's paradox fractalizes palette,
            // for size=256: 128 + 64 + 32 + ... + 1
            rendered = renderSub(size/2)
            // for size==256, renders 255 items, so top off with fill color
            let fill = splice.contains(.white) ? white : black
            while rendered.count < size {
                rendered.append(fill)
            }
        }
        else {
            rendered = renderSub(size)
        }
    }

    func flip(_ rgbs: [Rgb]) -> [Rgb]{

        var ret = [Rgb]()
        for rgb in rgbs.reversed() {
            ret.append(rgb)
        }
        return ret
    }

    func middle(_ p: Hsv, _ q: Hsv) -> Hsv {

        let ret = Hsv((p.h + q.h) / 2,
                      (p.s + q.s) / 2,
                      (p.v + q.v) / 2)
        return ret
    }

}
