//
//  Image+ext.swift
//  Platonix
//
//  Created by warren on 2/18/23.
//  Copyright © 2023 com.deepmuse. All rights reserved.

import Foundation
import CoreImage

extension CGImage {

    func pixelData() -> [UInt8]? {
        let sizeW = width
        let sizeH = height
        let bytesPerPixel = 4
        let faceSize = sizeW * sizeH
        let dataSize = faceSize * bytesPerPixel
        let bytesPerRow = bytesPerPixel * sizeW
        var pixelData = [UInt8](repeating: 0, count: Int(dataSize))
        if let context = CGContext(
            data             : &pixelData,
            width            : sizeW,
            height           : sizeH,
            bitsPerComponent : 8,
            bytesPerRow      : bytesPerRow,
            space            : CGColorSpaceCreateDeviceRGB(),
            bitmapInfo       : CGImageAlphaInfo.noneSkipLast.rawValue) {

            let rect = CGRect(x: 0, y: 0, width: sizeW, height: sizeH)
            context.draw(self, in: rect)
        }
        return pixelData

    }
}

extension CIImage {

    func pixelData(_ rect: CGRect) -> [UInt8]? {
        let context = CIContext()
        let cgImage = context.createCGImage(self, from: rect)
        return cgImage?.pixelData()
    }
}
