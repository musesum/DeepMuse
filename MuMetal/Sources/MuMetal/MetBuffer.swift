
//
//  MetalUniform.h
//  Sky
//
//  Created by warren on 2/13/19.
//  Copyright © 2019 DeepMuse All rights reserved.

import Foundation
import Metal
import MetalKit
import MuFlo

// only float buffers are allowed for now

class MetBuffer {

    private var name = "" // name of Metal Kernel
    public var bufIndex = 0  // index in metal buffer
    private var device: MTLDevice // metal device
    private var buf: Any!

    public var mtlBuffer: MTLBuffer? // buffer of constants

    public init(_ name: String,
                _ index: Int,
                _ any: Any,
                _ device: MTLDevice) {

        self.name = name
        self.bufIndex = index
        self.device = device
        newBuf(any)
    }

    func newBuf(_ floats: Array<Float>) {

        switch floats.count {
            case 1:

                buf = floats[0]
                let length = MemoryLayout<Float>.size
                mtlBuffer = device.makeBuffer(bytes: &buf, length: length, options: [])

            case 2:

                buf = SIMD2<Float>(floats[0], floats[1] )
                let length = MemoryLayout<SIMD2<Float>>.size
                mtlBuffer = device.makeBuffer(bytes: &buf, length: length, options: [])

            case 3:

                buf = SIMD3<Float>(floats[0], floats[1], floats[2])
                let length = MemoryLayout<SIMD3<Float>>.size
                mtlBuffer = device.makeBuffer(bytes: &buf, length: length, options: [])

            case 4:

                buf = SIMD4<Float>(floats[0], floats[1], floats[2], floats[3] )
                let length = MemoryLayout<SIMD4<Float>>.size
                mtlBuffer = device.makeBuffer(bytes: &buf, length: length, options: [])

            default:
                print("🚫 updateFloats unknown count: \(floats)")

        }
        //print(String(format:"˚\(name):%.2f", float), terminator:" ")
    }
    func newBuf(_ doubles: [Double]) {
        var floats = [Float]()
        for double in doubles {
            floats.append(Float(double))
        }
        newBuf(floats)
    }
    func newBuf(_ cgFloats: [CGFloat]) {
        var floats = [Float]()
        for cgFloat in cgFloats {
            floats.append(Float(cgFloat))
        }
        newBuf(floats)
    }

    /// add any translated to SIMD?<Float> to mtlBuffer
    func newBuf(_ val: Any) {

        switch val {
            case let v as Float:    newBuf([v])
            case let v as [Float]:  newBuf(v)
            case let v as Double:   newBuf([v])
            case let v as [Double]: newBuf(v)
            case let v as CGPoint:  newBuf(v.floats())
            case let v as CGSize:   newBuf(v.floats())
            case let v as CGRect:   newBuf(v.floats())
            case _ as FloValExprs: break
            default: print("🚫 \(#function) unknown format: \(val)")
        }
    }
}
