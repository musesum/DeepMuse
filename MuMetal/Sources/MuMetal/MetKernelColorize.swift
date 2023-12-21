//  Created by warren on 2/22/19.
//  Copyright © 2019 DeepMuse All rights reserved.

import Foundation
import Metal
import MetalKit

public class MetKernelColor: MetKernel {

    private var getPal: GetTextureFunc?

    public init(_ metItem: MetItem,
                _ getPal: @escaping GetTextureFunc) {

        super.init(metItem)
        nameBufId["color"] = 0
        self.getPal = getPal

    }
    func makePaletteTex() -> MTLTexture? {

        let paletteTex = MetTexCache
            .makeTexturePixelFormat(.bgra8Unorm,
                                    size: CGSize(width: 256, height: 1),
                                    device: metItem.device)
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

    override func setupInOutTextures(via: String) {

        super.setupInOutTextures(via: via)
        altTex = altTex ?? makePaletteTex() // 256 false color palette
    }

    override func nextCommand(_ command: MTLCommandBuffer) {

        setupInOutTextures(via: metItem.name)
        updatePalette()
        execCommand(command)
        outNode?.nextCommand(command) // continue onto the next node in the chain
    }
}
