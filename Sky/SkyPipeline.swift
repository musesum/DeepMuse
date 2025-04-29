import MetalKit
import Collections
import ZIPFoundation
import MuFlo
import MuVision
import MuPlato
import MuMenu

public class SkyPipeline: Pipeline {

    private var ripples: Ripples

    public init(_ root˚: Flo,
                _ archive: ArchiveFlo,
                _ touchDraw: TouchDraw,
                _ scale: CGFloat,
                _ bounds: CGRect,
                _ ripples: Ripples) {
        self.ripples = ripples
        super.init(root˚, archive, touchDraw, scale, bounds)
    }

    override public func makePipeNode(_ pipeNode˚: Flo,
                                      _ pipeParent: PipeNode?) {
        let pipeNode: PipeNode
        switch pipeNode˚.name {
        case "camera" : pipeNode = CameraNode(self, pipeNode˚)
        case "camix"  : pipeNode = CamixNode (self, pipeNode˚)
        case "draw"   : pipeNode = DrawNode  (self, pipeNode˚)
        case "color"  : pipeNode = ColorNode (self, pipeNode˚, ripples)
        case "tile"   : pipeNode = TileNode  (self, pipeNode˚)
        case "flat"   : pipeNode = FlatNode  (self, pipeNode˚)
        case "cube"   : pipeNode = CubeNode  (self, pipeNode˚)
        case "plato"  : pipeNode = PlatoNode (self, pipeNode˚)

        case "slide","zha","ave","fade","melt","tunl","fred"
            /**/      : pipeNode = CellNode  (self, pipeNode˚)
        default       : pipeNode = PipeNode  (self, pipeNode˚)
        }
        pipeParent?.pipeChildren.append(pipeNode)
    }
}

