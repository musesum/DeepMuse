//
//  SkyPipeline+update.swift
//  MuseSky
//
//  Created by warren on 12/11/19.
//  CCopyright © 2019 DeepMuse All rights reserved.
//

import Foundation
import MetalKit
import MuMetal

extension SkyPipeline {

    /// this once as called in addNodeName for case "draw" -- but seems to be superfluous
    func updateSkyTexture(_ node: MtlNode?) {

         guard let inTex = node?.inTex else { return }

         let w = inTex.width
         let h = inTex.height
         let hx = 8 // 8 rows at a time
         let pixSize = MemoryLayout<UInt32>.size
         let bytesPerRow = w * pixSize // sizeof(MTLPixelFormatBGRA8Unorm);

         var index = 0
         var bufSize = 0
         var buf: UnsafeMutablePointer<UInt8>!

         func copyToBuf(_ data: Data) {
             if bufSize != data.count {
                 if bufSize > 0 { free(buf) }
                 bufSize = data.count
                 buf = UnsafeMutablePointer<UInt8>.allocate(capacity: bufSize)
             }
             data.copyBytes(to: buf, count: data.count)
         }

         func updateTex() {

             var done = false
             let y = index / bytesPerRow
             var hs = bufSize / bytesPerRow

             if y >= h { done = true }
             if y+hs > h { hs = h-y-1; done = true }
             // print ("\(y):\(w),\(hs)", terminator:" ")

             if hs > 0 {
                 let region = MTLRegionMake3D(0, y, 0, w, hs, 1)
                 inTex.replace(region: region, mipmapLevel: 0, withBytes: buf, bytesPerRow: bytesPerRow)
                 index += bufSize
             }

             if done {
                 cleanup()
             }
         }
         func cleanup() {
             if buf != nil {
                 free(buf)
                 buf = nil
             }
             bufSize = 0
         }

         // begin -----------------------------------

         if let archive = SkyTr3.shared.archive {

             archive.get("Snapshot.tex", bytesPerRow * hx) { data in
                 if let data = data {
                     copyToBuf(data)
                     updateTex()
                 }
                     // data is completed so cleanup
                 else {
                     cleanup()
                 }
             }
         }
     }
}
