
import Foundation
import Metal
import MetalKit

public class MetKernelCamera: MetKernel {

    private var bypassTex: MTLTexture?  // bypass outTex when not on
    public var drawTex: MTLTexture? { get { return outTex ?? nil } }

    override init(_ metItem: MetItem) {

        super.init(metItem)
        nameBufId["mix"] = 0
        nameBufId["frame"] = 1
        setupSampler()
    }
    
    // get clipping frame from altTex
    func getAspectFill() -> CGRect {

        if  let altTex,
            let outTex {

            let ow = CGFloat(max(outTex.width, outTex.height))
            let oh = CGFloat(min(outTex.width, outTex.height))
            let oa = ow/oh

            let iw = CGFloat(max(altTex.width, altTex.height))
            let ih = CGFloat(min(altTex.width, altTex.height))
            let ia = iw/ih

            if oa < ia { // ipad front, back
                let x = round((iw - ih*oa)/2)
                let y = CGFloat.zero
                return CGRect(x: x, y: y, width: iw, height: ih)
            } else { // phone front, back (1.218)
                let y = round((ih - iw/oa)/2)
                let x = CGFloat.zero
                return CGRect(x: x, y: y, width: iw, height: ih)
            }
        }
        return .zero
    }

    override public func setMetalNodeOn(_ isOn: Bool,
                                        _ completion: @escaping ()->()) {
        print("Camera::setOn: \(isOn)")

        self.isOn = isOn

        if isOn {
            outTex = bypassTex ?? outTex ?? makeNewTex("setMetalNodeOn::\(metItem.name)")
        } else {
            bypassTex = outTex // push old outTex, restore later
            outTex = inTex // pass through outTex
        }
        print("\(metItem.name) in:\(String.pointer(inTex)) out:\(String.pointer(outTex)) bypass:\(String.pointer(bypassTex))")
        completion()
    }
    

    override func setupInOutTextures(via: String) {

        inTex = inNode?.outTex ?? makeNewTex(via)
        outTex = isOn ? outTex ?? makeNewTex(via) : inTex
    }

    override func nextCommand(_ command: MTLCommandBuffer) {

        setupInOutTextures(via: metItem.name)

        if isOn {
            let cameraSession = CameraSession.shared
            altTex = cameraSession.cameraTexture

            if let _ = altTex, cameraSession.cameraState == .streaming {

                let frame = getAspectFill()
                if frame != .zero {
                    updateBuffer("frame", frame)
                }
                execCommand(command)
            }
        }
        outNode?.nextCommand(command)
    }

}
