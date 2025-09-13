import MetalKit
import Collections
import ZIPFoundation
import MuFlo
import MuVision
import MuPlato
import MuMenu
import MuHands

public class SkyPipeline: Pipeline {

    private var ripples: Ripples
    private var camera: CameraSession
    private var touchCanvas: TouchCanvas

    public init(_ root˚: Flo,
                _ renderState: RenderState,
                _ archive: ArchiveFlo,
                _ touchDraw: TouchDraw,
                _ scale: CGFloat,
                _ bounds: CGRect,
                _ ripples: Ripples,
                _ camera: CameraSession,
                _ touchCanvas: TouchCanvas,
                _ nextFrame: NextFrame) {
        
        self.ripples = ripples
        self.camera = camera
        self.touchCanvas = touchCanvas
        super.init(root˚, renderState, archive, touchDraw, scale, bounds, nextFrame)
    }

    override public func makePipeNode(_ flo˚: Flo,
                                      _ pipeParent: PipeNode?) {
        let pipeNode: PipeNode
        switch flo˚.name {
        case "camera" : pipeNode = CameraNode(self, flo˚, camera)
        case "camix"  : pipeNode = CamixNode (self, flo˚, camera)
        case "draw"   : pipeNode = DrawNode  (self, flo˚, touchCanvas)
        case "color"  : pipeNode = ColorNode (self, flo˚, ripples)
        case "tile"   : pipeNode = TileNode  (self, flo˚)
        case "flat"   : pipeNode = FlatNode  (self, flo˚)
        case "cube"   : pipeNode = CubeNode  (self, flo˚)
        case "plato"  : pipeNode = PlatoNode (self, flo˚)

        case "slide","zha","ave","fade","melt","tunl","fred"
            /**/      : pipeNode = CellNode  (self, flo˚)
        default       : pipeNode = PipeNode  (self, flo˚)
        }
        pipeParent?.pipeChildren.append(pipeNode)
    }
}

