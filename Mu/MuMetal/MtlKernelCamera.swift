
import Foundation
import Metal
import MetalKit

public class MtlKernelCamera: MtlKernel {

    private var bypassTex: MTLTexture?  // bypass outTex when not on
    public var drawTex: MTLTexture? { get { return outTex ?? nil } }

    public init(_ name: String,
                _ device: MTLDevice,
                _ size: CGSize,
                _ type: String,
                _ uiOrientation: UIInterfaceOrientation) {

        CameraSession.shared.uiOrientation = uiOrientation
        super.init(name, device, size, type)
        nameIndex["face"] = 0
        nameIndex["mix"] = 1
        nameIndex["frame"] = 2
        addBuffer("face", CameraSession.shared.cameraType.rawValue)
        setupSampler()
    }
    
    // get clipping frame from altTex
    func getAspectFill() -> CGRect {

        if  let altTex = altTex,
            let outTex = outTex {

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

    override public func setOn(_ isOn: Bool, _ completion: @escaping ()->()) {
        print("   Camera::setOn: \(isOn)")
        self.isOn = isOn
        CameraSession.shared.setCameraOn(isOn)
        if isOn {
            if bypassTex != nil {
                // was bypassing so restore
                outTex = bypassTex
                bypassTex = nil
            } else {
                // not bypassing so continue or create outTex
                outTex = outTex ?? makeNewTex()
            }
        } else { // is not on
            // push old outTex to bypass, maybe restore later
            bypassTex = outTex
            // pass through outTex
            outTex = inTex
        }
        completion()
    }

    override func setupInOutTextures() {

        inTex = inNode?.outTex ?? makeNewTex()
        outTex = isOn ? outTex ?? makeNewTex() : inTex
    }

    public override func goCommand(_ command: MTLCommandBuffer?) {

        setupInOutTextures()

        if isOn {

            let cameraSession = CameraSession.shared
            altTex = cameraSession.camTex

            if let _ = altTex, cameraSession.state == .streaming {

                updateBuffer("face", cameraSession.cameraType.rawValue)

                let frame = getAspectFill()
                if frame != .zero {
                    updateBuffer("frame", frame)
                }
                super.execCommand(command)
            }
        }
        outNode?.goCommand(command)
    }

}
