
//
//  MetaDraw.h
//  Sky
//
//  Created by warren on 2/22/19.
//  Copyright © 2019 DeepMuse All rights reserved.
//

import Foundation
import Metal
import MetalKit

public class MtlKernelColor: MtlKernel {

    private var getPal: GetTextureFunc?

    public init(_ name: String,
                _ device: MTLDevice,
                _ size: CGSize,
                _ type: String,
                _ getPal: @escaping GetTextureFunc) {

        super.init(name, device, size, type)
        nameIndex["color"] = 0
        self.getPal = getPal

    }
    func makePaletteTex() -> MTLTexture? {

        let d = MTLTextureDescriptor()
        d.textureType = .type2D
        d.pixelFormat = .bgra8Unorm
        d.width = 256
        d.height = 1
        d.usage = [.shaderRead, .shaderWrite]
        let paletteTex = device.makeTexture(descriptor: d)
        return paletteTex
    }

    func updatePalette() {

        // draw into palette texture

        if let altTex = altTex,
           let getPal = getPal {

            let palSize = 256
            let pixSize = MemoryLayout<UInt32>.size
            let palRegion = MTLRegionMake3D(0, 0, 0, palSize, 1, 1)
            let bytesPerRow = palSize * pixSize
            let palBytes = getPal(palSize)
            altTex.replace(region: palRegion, mipmapLevel: 0, withBytes: palBytes, bytesPerRow: bytesPerRow)
        }
    }

    override func setupInOutTextures() {

        super.setupInOutTextures()
        altTex = altTex ?? makePaletteTex() // 256 false color palette
    }

    public override func goCommand(_ command: MTLCommandBuffer?) {

        setupInOutTextures()
        updatePalette()
        super.execCommand(command)
        outNode?.goCommand(command) // continue onto the next node in the chain
    }
}
