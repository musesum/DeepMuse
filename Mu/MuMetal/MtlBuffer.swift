
//
//  MetalUniform.h
//  Sky
//
//  Created by warren on 2/13/19.
//  Copyright © 2019 DeepMuse All rights reserved.

import Foundation
import Metal
import MetalKit
import Tr3

// only float buffers are allowed for now

class MtlBuffer: NSObject {

    private var name = "" // name of Metal Kernel
    public var bufIndex = 0  // index in metal buffer
    public var device: MTLDevice? // metal device

    private var bufi = Int(0)
    private var buf1 = Float(0)
    private var buf2 = SIMD2<Float>(repeating: 0)
    private var buf3 = SIMD3<Float>(repeating: 0)
    private var buf4 = SIMD4<Float>(repeating: 0)
    private var buf: Any?

    public  var mtlBuffer: MTLBuffer? // buffer of constants

    public convenience init(_ name: String, _ index: Int, _ any: Any, _ device: MTLDevice) {
        self.init()
        self.name = name
        self.bufIndex = index
        self.device = device
        updateBuffer(any)
    }

    func updateInt(_ int: Int) {

        bufi = int
        let length = MemoryLayout<Int>.size
        mtlBuffer = device?.makeBuffer(bytes: &bufi, length: length, options: [])
        //print(String(format:"˚\(name):%.2f", float), terminator:" ")
    }
    func updateFloats(_ floats: Array<Float>) {

        switch floats.count {
            case 1:

                buf1 = floats[0]
                let length = MemoryLayout<Float>.size
                mtlBuffer = device?.makeBuffer(bytes: &buf1, length: length, options: [])

            case 2:

                buf2 = SIMD2<Float>(floats[0], floats[1] )
                let length = MemoryLayout<SIMD2<Float>>.size
                mtlBuffer = device?.makeBuffer(bytes: &buf2, length: length, options: [])

            case 3:

                buf3 = SIMD3<Float>(floats[0], floats[1], floats[2])
                let length = MemoryLayout<SIMD3<Float>>.size
                mtlBuffer = device?.makeBuffer(bytes: &buf3, length: length, options: [])

            case 4:

                buf4 = SIMD4<Float>(floats[0], floats[1], floats[2], floats[3] )
                let length = MemoryLayout<SIMD4<Float>>.size
                mtlBuffer = device?.makeBuffer(bytes: &buf4, length: length, options: [])

            default:
                print("🚫 updateFloats unknown count: \(floats)")

        }
        //print(String(format:"˚\(name):%.2f", float), terminator:" ")
    }
    func updateBuffer(_ val: Any) {

        switch val {
            case let v as Int:      updateInt(v)
            case let v as Float:    updateFloats([v])
            case let v as [Float]:  updateFloats(v)
            case let v as CGPoint:  updateFloats([Float(v.x), Float(v.y)])
            case let v as CGSize:   updateFloats([Float(v.width), Float(v.height)])
            case let v as CGRect:   updateFloats([Float(v.minX), Float(v.minY),
                                                  Float(v.width), Float(v.height)])
            case _ as Tr3Exprs: break
            default: print("🚫 \(#function) unknown val: \(val)")
        }
    }
}
