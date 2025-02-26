import MetalKit
import Collections
import ZIPFoundation
import MuFlo
import MuVision
import MuPlato
import MuMenu

public class SkyPipeline: Pipeline {
    
    override public func makePipeNode(_ childFlo: Flo,
                                      _ pipeParent: PipeNode?) {
        let pipeNode: PipeNode
        switch childFlo.name {
        case "camera" : pipeNode = CameraNode(self, childFlo)
        case "camix"  : pipeNode = CamixNode (self, childFlo)
        case "draw"   : pipeNode = DrawNode  (self, childFlo)
        case "color"  : pipeNode = ColorNode (self, childFlo)
        case "tile"   : pipeNode = TileNode  (self, childFlo)
        case "flat"   : pipeNode = FlatNode  (self, childFlo)
        case "cube"   : pipeNode = CubeNode  (self, childFlo)
        case "plato"  : pipeNode = PlatoNode (self, childFlo)

        case "slide","zha","ave","fade","melt","tunl","fred"
            /**/      : pipeNode = CellNode  (self, childFlo)
        default       : pipeNode = PipeNode  (self, childFlo)
        }
        pipeParent?.pipeChildren.append(pipeNode)
    }
}

