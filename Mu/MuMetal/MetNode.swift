
import Foundation
import Metal
import MetalKit
import QuartzCore
import MuPar

public class MetNode: Equatable {

    var id = Visitor.nextId()
    public static func == (lhs: MetNode, rhs: MetNode) -> Bool { return lhs.id == rhs.id }
    
    var metItem: MetItem

    var filename = "" // optional filename for runtime compile of shader file
    var inTex: MTLTexture?   // input texture 0
    var outTex: MTLTexture?  // output texture 1
    var altTex: MTLTexture?  // optional texture 2
    var samplr: MTLSamplerState?

    var inNode: MetNode?    // optional input kernel
    var outNode: MetNode?   // optional output kernel

    typealias BufId = Int
    internal var nameBufId = [String: BufId]()
    internal var nameBuffer = [String: MetBuffer]()

    var loops = 1
    var isOn = false

    // can override to trigger behaviors, such as turning on  camera
    func setMetalNodeOn(_ isOn: Bool,
                        _ completion: @escaping ()->()) {
        if self.isOn != isOn {
            self.isOn = isOn
            completion()
        }
    }

    init(_ metItem: MetItem) {
        self.metItem = metItem
    }

    func makeNewTex(_ via: String) -> MTLTexture? {
        if let tex = MetTexCache.makeTexturePixelFormat(.bgra8Unorm, size: metItem.size, device: metItem.device) {
            let texPtr = String.pointer(tex)
            print("makeNewTex via: \(via) => \(texPtr)")

            return tex
        }
        return nil
    }

    func setupInOutTextures(via: String) {
        
        inTex = inNode?.outTex ?? makeNewTex(via)
        outTex = outTex ?? makeNewTex(via)
    }

    /// continue onto next node to execute command
    func nextCommand(_ command: MTLCommandBuffer) {
        print("🚫 goCommand:\(String(describing: command)) needs override")
    }
    
    func setupSampler() {

        let sd = MTLSamplerDescriptor()
        sd.minFilter    = .nearest
        sd.magFilter    = .linear
        sd.sAddressMode = .repeat
        sd.tAddressMode = .repeat
        sd.rAddressMode = .repeat
        samplr = metItem.device.makeSamplerState(descriptor: sd)
    }
    
    func printMetaNodes() {

        let inName = inNode?.metItem.name ?? "nil"
        var inTexNow = ""
        var outTexNow = ""
        
        if let t = inTex  { inTexNow  = "\(Unmanaged.passUnretained(t).toOpaque())" }
        if let t = outTex { outTexNow = "\(Unmanaged.passUnretained(t).toOpaque())" }

        print(String(format:"MetaKernal:\(metItem.name) in:\(inName) tex:\(inTexNow) outTex:\(outTexNow)"))
        outNode?.printMetaNodes()
    }

}
