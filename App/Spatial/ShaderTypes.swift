//  Created by musesum on 9/17/23.

import simd

struct Vertexi {
    static let position = 0
    static let texcoord = 1
    static let normal   = 2
    static let uniforms = 3
}

struct Texturei {
    static let colori = 0
}

enum RendererError: Error {
    case badVertex
}

public struct Uniforms {
    var projection: matrix_float4x4
    var viewModel: matrix_float4x4
}

public struct UniformEyes {
    // a uniform for each eye
    var eye: (Uniforms, Uniforms)
}
