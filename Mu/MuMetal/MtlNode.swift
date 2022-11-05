
import Foundation
import Metal
import MetalKit
import QuartzCore
import Par

public class MtlNode: Equatable {

    public var id = Visitor.nextId()
    public static func == (lhs: MtlNode, rhs: MtlNode) -> Bool { return lhs.id == rhs.id }
    
    public var name = ""
    public var type = ""
    public var filename = "" // optional filename for runtime compile of shader file

    public var size = CGSize.zero
    public var device: MTLDevice
    public var inTex: MTLTexture?   // input texture 0
    public var outTex: MTLTexture?  // output texture 1
    public var altTex: MTLTexture?  // optional texture 2
    public var mtlSampler: MTLSamplerState?

    public var inNode: MtlNode?    // optional input kernel
    public var outNode: MtlNode?   // optional output kernel

    internal var nameBuffer = [String: MtlBuffer]()
    public var nameIndex = [String: Int]()

    public var loops = 1
    public var isOn = false

    // can override to trigger behaviors, such as turning on  camera
    public func setOn(_ isOn: Bool, _ completion: @escaping ()->()) {
        if self.isOn != isOn { 
            self.isOn = isOn
            completion()
        }
    }

    public init(_ name: String,
                _ device: MTLDevice,
                _ size: CGSize,
                _ type: String) {  

        self.name = name
        self.device = device
        self.size = size
        self.type = type
    }

    func makeNewTex() -> MTLTexture? {
           return MtlTexCache.makeTexturePixelFormat(.bgra8Unorm, size: size, device: device)
    }

    func setupInOutTextures() {
        
        inTex = inNode?.outTex ?? makeNewTex()
        outTex = outTex ?? makeNewTex()
    }

    public func goCommand(_ command: MTLCommandBuffer?) {
        print("🚫 goCommand:\(String(describing: command)) needs override")
    }
    
    public func setupSampler() {

        let samplr = MTLSamplerDescriptor()
        samplr.minFilter = .nearest
        samplr.magFilter = .linear
        samplr.sAddressMode = .repeat
        samplr.tAddressMode = .repeat
        samplr.rAddressMode = .repeat
        mtlSampler = device.makeSamplerState(descriptor: samplr)
    }
    
    func printMetaNodes() {

        let inName = inNode?.name ?? "nil"
        var inTexNow = ""
        var outTexNow = ""
        
        if let t = inTex  { inTexNow  = "\(Unmanaged.passUnretained(t).toOpaque())" }
        if let t = outTex { outTexNow = "\(Unmanaged.passUnretained(t).toOpaque())" }

        print(String(format:"MetaKernal:\(name) in:\(inName) tex:\(inTexNow) outTex:\(outTexNow)"))
        outNode?.printMetaNodes()
    }

}
