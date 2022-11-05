
//
//  MetaDraw.h
//  Sky
//
//  Created by warren on 2/22/19.
//  Copyright © 2019 DeepMuse All rights reserved.
//

import Foundation
import Metal
import MetalKit

public class MtlKernelCompute: MtlKernel {
    
    // cellular automata uses double buffering
    override func setupInOutTextures() {

        if !isOn && outTex != nil { return }
        nameIndex[""] = 0
        inTex = inNode?.outTex
        outTex = outTex ?? makeNewTex()
    }

    // cellular automata uses double buffering
    func flipInOutTextures() {
        let temp = inTex
        inTex = outTex
        outTex = temp
    }

    public override func goCommand(_ command: MTLCommandBuffer?) {

        setupInOutTextures()
        
        if isOn {

            super.execCommand(command)

            for _ in 1 ..< loops {
                flipInOutTextures()
                super.execCommand(command)
            }
        }
        outNode?.goCommand(command) // continue onto the next node in the chain
    }
}
