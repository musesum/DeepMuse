//
//  MetNodeCompute.swift
//  DeepMuse
//
//  Created by warren on 4/2/23.
//  Copyright © 2023 DeepMuse. All rights reserved.
//

import Foundation

import Foundation
import Metal
import MetalKit
import QuartzCore
import MuPar

open class MetNodeCompute: MetNode {

public init(_ pipeline: MetPipeline,
            _ name: String,
            _ filename: String = "",
            _ type: MetType = .compute) {

    super.init(pipeline,name,filename,.compute)
    }
}
