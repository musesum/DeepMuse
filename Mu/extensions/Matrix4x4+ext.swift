//  Created by warren on 3/1/23.
//  Copyright © 2023 com.deepmuse. All rights reserved.

import simd

func perspective(_ aspect: Float,
                 _ fovy  : Float,
                 _ near  : Float,
                 _ far   : Float) -> simd_float4x4 {

    let yScale  = 1 / tan(fovy * 0.5)
    let xScale  = yScale / aspect
    let zRange  = far - near
    let zScale  = -(far + near) / zRange
    let wzScale = -far * near / zRange
    let P = SIMD4<Float>([ xScale, 0, 0, 0  ])
    let Q = SIMD4<Float>([ 0, yScale, 0, 0  ])
    let R = SIMD4<Float>([ 0, 0, zScale, -1 ])
    let S = SIMD4<Float>([ 0, 0, wzScale, 0 ])

    let mat = simd_float4x4([P, Q, R, S])
    return mat
}

var identity: simd_float4x4 = {
    let P = SIMD4<Float>([ 1, 0, 0, 0 ])
    let Q = SIMD4<Float>([ 0, 1, 0, 0 ])
    let R = SIMD4<Float>([ 0, 0, 1, 0 ])
    let S = SIMD4<Float>([ 0, 0, 0, 1 ])

    return simd_float4x4([P, Q, R, S])
} ()

func translation(_ t: vector_float4) -> simd_float4x4 {
    let X = SIMD4<Float>([  1,  0,  0,  0 ])
    let Y = SIMD4<Float>([  0,  1,  0,  0 ])
    let Z = SIMD4<Float>([  0,  0,  1,  0 ])
    let W = SIMD4<Float>([t.x,t.y,t.z,t.w ])

    let mat = simd_float4x4([X,Y,Z,W])
    return mat
}
