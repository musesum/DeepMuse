//
//  Matric-util.swift
//  DeepMuse
//
//  Created by warren on 9/17/23.
//

import Foundation
import simd

// Generic matrix math utility functions
#if os(xrOS)
func matrix4x4_rotation(radians: Float, axis: SIMD3<Float>) -> matrix_float4x4 {
    let unitAxis = normalize(axis)
    let ct = cosf(radians)
    let st = sinf(radians)
    let ci = 1 - ct
    let x = unitAxis.x, y = unitAxis.y, z = unitAxis.z
    let col0 = vector_float4(x*x*ci + ct  , y*x*ci + z*st, z*x*ci - y*st, 0)
    let col1 = vector_float4(x*y*ci - z*st, y*y*ci +   ct, z*y*ci + x*st, 0)
    let col2 = vector_float4(x*z*ci + y*st, y*z*ci - x*st, z*z*ci + ct  , 0)
    let col3 = vector_float4(            0,             0,             0, 1)
    return matrix_float4x4.init(columns:(col0,col1,col2,col3))
}

func matrix4x4_translation(_ translationX: Float, _ translationY: Float, _ translationZ: Float) -> matrix_float4x4 {
    return matrix_float4x4.init(columns:(vector_float4(1, 0, 0, 0),
                                         vector_float4(0, 1, 0, 0),
                                         vector_float4(0, 0, 1, 0),
                                         vector_float4(translationX, translationY, translationZ, 1)))
}

func radians_from_degrees(_ degrees: Float) -> Float {
    return (degrees / 180) * .pi
}

#endif
