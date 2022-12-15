
import Foundation
import Metal
import MetalKit

public typealias DrawTextureFunc = ((_ bytes: UnsafeMutablePointer<UInt32>, _ size: CGSize)->(Bool))
public typealias GetTextureFunc = ((_ size: Int) -> (UnsafeMutablePointer<UInt32>))

public class MtlKernelDraw: MtlKernel {

    var drawFunc: DrawTextureFunc?

    public init(_ name: String,
                _ device: MTLDevice,
                _ size: CGSize,
                _ type: String,
                _ drawFunc: DrawTextureFunc?) {

        super.init(name, device, size, type)
        nameIndex["draw"] = 0
        self.drawFunc = drawFunc
    }

    public override func goCommand(_ command: MTLCommandBuffer?) {

        setupInOutTextures()

        if let outTex {

            let w = outTex.width
            let h = outTex.height
            let pixSize = MemoryLayout<UInt32>.size
            let bytesPerRow = w * pixSize // sizeof(MTLPixelFormatBGRA8Unorm);
            let region = MTLRegionMake3D(0, 0, 0, outTex.width, outTex.height, 1)
            let cellBytes = UnsafeMutablePointer<UInt32>.allocate(capacity: w * h * pixSize)
            // get universe
            inTex?.getBytes(cellBytes, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)
           // draw in uninverse
            let filled = drawFunc?(cellBytes, size) ?? false
            // put back universe
            inTex?.replace(region: region, mipmapLevel: 0, withBytes: cellBytes, bytesPerRow: bytesPerRow)
            // fill both text textures
            if filled {
                outTex.replace(region: region, mipmapLevel: 0, withBytes: cellBytes, bytesPerRow: bytesPerRow)
            }
            free(cellBytes)
        }
        super.execCommand(command)
        outNode?.goCommand(command)
    }
}
