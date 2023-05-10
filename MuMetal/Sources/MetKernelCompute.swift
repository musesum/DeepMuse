//  Created by warren on 2/22/19.

import Foundation
import Metal
import MetalKit

public class MetKernelCompute: MetKernel {
    
    // cellular automata uses double buffering
    override func setupInOutTextures(via: String) {

        if !isOn && outTex != nil { return }
        nameBufId[""] = 0
        inTex = inNode?.outTex
        outTex = outTex ?? makeNewTex(via)
    }

    // cellular automata uses double buffering
    func flipInOutTextures() {
        let temp = inTex
        inTex = outTex
        outTex = temp
    }

    override func nextCommand(_ command: MTLCommandBuffer) {

        setupInOutTextures(via: metItem.name)
        
        if isOn {

            execCommand(command)

            for _ in 1 ..< loops {
                flipInOutTextures()
                execCommand(command)
            }
        }
        outNode?.nextCommand(command)
    }
}
