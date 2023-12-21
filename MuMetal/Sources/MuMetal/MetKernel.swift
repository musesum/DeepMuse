//  MetKernel.swift

//  Created by warren on 2/11/19.
//  Copyright © 2019 DeepMuse All rights reserved.

import MetalKit

public class MetKernel: MetNode {

    private var computePipeline: MTLComputePipelineState? // _cellRulePipeline;
    private var threadgroupSize = MTLSize()
    private var threadgroupCount = MTLSize()

    public override init(_ metItem: MetItem) {
 
        super.init(metItem)
        compileKernelFunction()
        determineThreadGroupSize()
    }
    func compileKernelFunction() {
        if  let defaultLib = metItem.device.makeDefaultLibrary(),
            let mtlFunction = defaultLib.makeFunction(name: metItem.name) {

            do { computePipeline = try metItem.device.makeComputePipelineState(function: mtlFunction)  }
            catch { print("Failed to create _pipeline for \(metItem.name), error \(error)") }
        }
    }

    func determineThreadGroupSize() {

        threadgroupSize = MTLSizeMake(16, 16, 1)
        let sizeW = metItem.size.width
        let sizeH = metItem.size.height
        let threadW = CGFloat(threadgroupSize.width)
        let threadH = CGFloat(threadgroupSize.height)
        threadgroupCount.width  = Int((sizeW + threadW - 1.0) / threadW)
        threadgroupCount.height = Int((sizeH + threadH - 1.0) / threadH)
        threadgroupCount.depth  = 1
    }

    func execCommand(_ command: MTLCommandBuffer) {
        // setup and execute compute textures

        if let cc = command.makeComputeCommandEncoder(),
           let computePipeline {

            if let inTex  { cc.setTexture(inTex,  index: 0) }
            if let outTex { cc.setTexture(outTex, index: 1) }
            if let altTex { cc.setTexture(altTex, index: 2) }

            cc.setSamplerState(samplr, index: 0)

            // compute buffer index is in order of declaration in flo script
            for buf in nameBuffer.values {
                cc.setBuffer(buf.mtlBuffer, offset: 0, index: buf.bufIndex)
            }
            // execute the compute pipeline threads
            cc.setComputePipelineState(computePipeline)
            cc.dispatchThreadgroups(threadgroupCount, threadsPerThreadgroup: threadgroupSize)
            cc.endEncoding()
        }
    }
    override func nextCommand(_ command: MTLCommandBuffer) {

        execCommand(command)
    }
}
