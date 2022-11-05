import Foundation


class ColorSet {

    var hsvs = [String: Hsv]()

    init() {
        makePresets()
    }
    func makePresets() {
        hsvs["nil"]     = Hsv(  0,  0,    0)
        hsvs["red"]     = Hsv(  0, 100, 100)
        hsvs["orange"]  = Hsv( 30, 100, 100)
        hsvs["yellow"]  = Hsv( 60, 100, 100)
        hsvs["green"]   = Hsv(120, 100, 100)
        hsvs["teal"]    = Hsv(180, 100, 100)
        hsvs["blue"]    = Hsv(240, 100, 100)
        hsvs["indigo"]  = Hsv(270, 100, 100)
        hsvs["purple"]  = Hsv(285, 100, 100)
        hsvs["violet"]  = Hsv(300, 100, 100)
        hsvs["magenta"] = Hsv(300, 100, 100)
        hsvs["white"]   = Hsv(  0,   0, 100)
        hsvs["gray"]    = Hsv(  0,   0,  50)
        hsvs["black"]   = Hsv(  0,   0,   0)

        hsvs["k"] = Hsv(  0,   0, 100) // black
        hsvs["w"] = Hsv(  0,   0,   0) // white
        hsvs["r"] = Hsv(  0, 100, 100) // red
        hsvs["o"] = Hsv( 30, 100, 100) // orange
        hsvs["y"] = Hsv( 60, 100, 100) // yellow
        hsvs["g"] = Hsv(120, 100, 100) // green
        hsvs["b"] = Hsv(240, 100, 100) // blue
        hsvs["i"] = Hsv(270, 100, 100) // indigo
        hsvs["v"] = Hsv(300, 100, 100) // violet

    }
}
