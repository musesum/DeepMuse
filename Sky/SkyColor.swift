import Foundation
import Tr3

public class SkyColor {

    private var xfade˚: Tr3?        // cross fade tr3 between two current palettes
    private var xfade = Float(0.5)  // cross fade current value
    private var pal0˚: Tr3?
    private var pal0 = "rgbK"      // Red Green Blue with blacK interstitials
    private var pal1˚: Tr3?
    private var pal1 = "wKZ"       // White with blacK inter pluz zeno fractal

    private var colors = [Color("rgbK"), Color("wKZ")] // dual color palette
    private var rgbs = [Rgb]()      // rendered color palette
    private var changed = true
    private var mix: UnsafeMutablePointer<UInt32>! = nil
    private var mixSize = 0

    public init(_ root: Tr3) {
        if let color = root.findPath("sky.color") {
            xfade˚ = color.findPath("xfade")
            xfade˚?.addClosure { tr3, _ in
                let fade = tr3.FloatVal() ?? self.xfade
                if fade == 0 {
                    print(".", terminator: "")
                }
                self.xfade = fade 
                self.changed = true
            }

            pal0˚ = color.findPath("pal0")
            pal0˚?.addClosure { tr3, _ in
                if let pal = tr3.StringVal() {
                    self.pal0 = pal
                    self.colors[0] = Color(pal)
                }
                self.changed = true
            }
            pal0˚?.activate()

            pal1˚ = color.findPath("pal1")
            pal1˚?.addClosure { tr3, _ in
                if let pal = tr3.StringVal() {
                    self.pal1 = pal
                    self.colors[1] = Color(pal)
                }
                self.changed = true
            }
            pal1˚?.activate()
        }
        changed = true
    }
    deinit {
        mix?.deallocate()
    }

    func getMix(_ palSize: Int) -> UnsafeMutablePointer<UInt32> {
        
        if changed || palSize != mixSize {
            changed = false
            rgbs.removeAll()
            rgbs = Color.fade(from: colors[0], to: colors[1], xfade)
            if mixSize != palSize {
                mixSize = palSize
                mix?.deallocate()
                mix = UnsafeMutablePointer<UInt32>.allocate(capacity: mixSize)
            }

            // convert [Rgb] to [Uint32]
            for i in 0 ..< rgbs.count {
                let rgb = rgbs[i]
                let b8 = UInt32(rgb.b * 255.0)
                let g8 = UInt32(rgb.g * 255.0) << 8
                let r8 = UInt32(rgb.r * 255.0) << 16
                let a8 = UInt32(rgb.a * 255.0) << 24
                let bgra = b8 | g8 | r8 | a8
                mix[i] = bgra
                //print(String(format:"%08X", val), terminator: " ")
            }
        }
        return mix
    }

}
