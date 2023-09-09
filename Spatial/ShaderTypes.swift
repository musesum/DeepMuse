//
//  File.swift
//  
//
//  Created by warren on 9/3/23.
//

import Foundation
import simd

public enum BufferIndex: Int {
    case positions = 0
    case generics = 1
    case uniforms = 2
}

public enum VertexAttribute: Int {
    case position = 0
    case texcoord = 1
}

public enum TextureIndex: Int  {
    case color = 0
}

public struct Uniforms {
    var projectionMatrix: simd_float4x4
    var modelViewMatrix: simd_float4x4
}

typealias Uniforms2 = (Uniforms,Uniforms)
public struct UniformsArray {
    var uniforms: [Uniforms] = []
    init() {
        uniforms.reserveCapacity(2)
    }
}
