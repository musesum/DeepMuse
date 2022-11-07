//  MtlKernel.swift
//  Sky
//
//  Created by warren on 2/11/19.
//  Copyright © 2019 DeepMuse All rights reserved.
//

import MetalKit

public class MtlKernel: MtlNode {

    private var pipeline: MTLComputePipelineState? // _cellRulePipeline;
    private var threadgroupSize = MTLSize()
    private var threadgroupCount = MTLSize()

    public override init(_ name: String,
                         _ device: MTLDevice,
                         _ size: CGSize,
                         _ type: String) {

        super.init(name, device, size, type)
        compileKernelFunction()
        setupInOutTextures()
        determineThreadGroupSize()
    }
    func compileKernelFunction() {
        if  let defaultLib = device.makeDefaultLibrary(),
            let mtlFunc = defaultLib.makeFunction(name: name) {

            do { pipeline = try device.makeComputePipelineState(function: mtlFunc)  }
            catch { print("Failed to create _pipeline for \(name), error \(error)") }
        }
    }

    func determineThreadGroupSize() {

        threadgroupSize = MTLSizeMake(16, 16, 1)
        let sizeW = size.width
        let sizeH = size.height
        let threadW = CGFloat(threadgroupSize.width)
        let threadH = CGFloat(threadgroupSize.height)
        threadgroupCount.width  = Int((sizeW + threadW - 1.0) / threadW)
        threadgroupCount.height = Int((sizeH + threadH - 1.0) / threadH)
        threadgroupCount.depth  = 1
    }

    public func execCommand(_ command: MTLCommandBuffer?) {
        // setup and execute compute textures

        if let compute = command?.makeComputeCommandEncoder(),
           let pipeline = pipeline {

            if let inTex  = inTex  { compute.setTexture(inTex,  index: 0) }
            if let outTex = outTex { compute.setTexture(outTex, index: 1) }
            if let altTex = altTex { compute.setTexture(altTex, index: 2) }

            compute.setSamplerState(mtlSampler, index: 0)

            // compute buffer index is in order of declaration in tr3 script
            for buf in nameBuffer.values {
                compute.setBuffer(buf.mtlBuffer, offset: 0, index: buf.bufIndex)
            }
            // execute the compute pipeline threads
            compute.setComputePipelineState(pipeline)
            compute.dispatchThreadgroups(threadgroupCount, threadsPerThreadgroup: threadgroupSize)
            compute.endEncoding()
        }
    }
    public override func goCommand(_ command: MTLCommandBuffer?) {

        execCommand(command)
    }
}
