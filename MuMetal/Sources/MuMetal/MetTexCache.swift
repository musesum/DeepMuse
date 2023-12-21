
//
//  MtlTexCache.swift
//  Sky
//
//  Created by warren on 2/27/19.
//  Copyright © 2019 DeepMuse All rights reserved.
//

import Foundation
import MetalKit

class MetTexCache {

    static var cache = [MTLTexture]() //TextureCache

    static func recycleTextureFormat(_ pixelFormat: MTLPixelFormat, size: CGSize) -> MTLTexture? {
        for tex in cache {
            if  CGFloat(tex.width)  == size.width,
                CGFloat(tex.height) == size.height,
                tex.pixelFormat == pixelFormat {
                return tex
            }
        }
        return nil
    }

    static func makeTexturePixelFormat(_ pixelFormat: MTLPixelFormat, size: CGSize, device: MTLDevice?) -> MTLTexture? {

        var tex = recycleTextureFormat(pixelFormat, size: size)

        if tex == nil {
            let td = MTLTextureDescriptor()
            td.textureType = .type2D
            td.pixelFormat = pixelFormat
            td.width = Int(size.width)
            td.height = Int(size.height)
            td.usage = [.shaderRead, .shaderWrite]
            tex = device?.makeTexture(descriptor: td)
        }
        return tex
    }
}
 
