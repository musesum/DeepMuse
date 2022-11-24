//
//  MetalSnapshot.swift
//  
//
//  Created by warren on 9/23/19.
//

import Foundation
import MetalKit

extension MTLTexture {

       public func bytes() -> (UnsafeMutableRawPointer, Int) {

           let width = self.width
           let height = self.height
           let pixSize = MemoryLayout<UInt32>.size
           let rowBytes = self.width * pixSize
           let totalSize = width * height * pixSize
           let p = malloc(totalSize)
           self.getBytes(p!, bytesPerRow: rowBytes, from: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0)
           return (p!, totalSize)
       }

       public func toImage() -> CGImage? {
           let pixSize = MemoryLayout<UInt32>.size
           let (p, totalSize) = bytes()

           let pColorSpace = CGColorSpaceCreateDeviceRGB()

           let rawBitmapInfo = (CGImageAlphaInfo.noneSkipFirst.rawValue |
                                CGBitmapInfo.byteOrder32Little.rawValue)
           let bitmapInfo: CGBitmapInfo = CGBitmapInfo(rawValue: rawBitmapInfo)

           let rowBytes = self.width * pixSize
           let releaseCallback: CGDataProviderReleaseDataCallback = { (info: UnsafeMutableRawPointer?, data: UnsafeRawPointer, size: Int) -> () in
               return
           }
           let provider = CGDataProvider(dataInfo: nil, data: p, size: totalSize, releaseData: releaseCallback)
           
           let cgImageRef = CGImage(width: self.width, height: self.height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: rowBytes, space: pColorSpace, bitmapInfo: bitmapInfo, provider: provider!, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)!

           return cgImageRef
       }
}


