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
    private var drawNode: DrawNode?

    public init(_ root˚: Flo,
                _ renderState: RenderState,
                _ archive: ArchiveFlo,
                _ touchDraw: TouchDraw,
                _ scale: CGFloat,
                _ bounds: CGRect,
                _ ripples: Ripples,
                _ camera: CameraSession,
                _ touchCanvas: TouchCanvas) {
        
        self.ripples = ripples
        self.camera = camera
        self.touchCanvas = touchCanvas
        super.init(root˚, renderState, archive, touchDraw, scale, bounds)
        root˚.findPath("pipe.size")?.addClosure { [weak self] f,_ in
            self?.setPipeSize(exp2: f.int)
        }
    }

    override public func makePipeNode(_ flo˚: Flo,
                                      _ pipeParent: PipeNode?) {
        let pipeNode: PipeNode
        switch flo˚.name {
        case "camera" : pipeNode = CameraNode(self, flo˚, camera)
        case "strip"  : pipeNode = StripNode (self, flo˚)
        case "feed",
             "router" : pipeNode = RouterNode(self, flo˚)
        case "draw"   :
            let drawNode = DrawNode(self, flo˚, touchCanvas)
            self.drawNode = drawNode
            pipeNode = drawNode
        case "color"  : pipeNode = ColorNode (self, flo˚, ripples)
        case "tile"   :
            let tileNode = TileNode(self, flo˚)
            // a touch must fold through the tile the same way the kernel gathers pixels
            drawNode?.tileMap = { [weak tileNode] u in tileNode?.sourceFraction(u) ?? u }
            pipeNode = tileNode
        case "flat"   : pipeNode = FlatNode  (self, flo˚)
        case "cube"   :
            let cubeNode = CubeNode(self, flo˚)
            // a stroke lands where the cubemap shows the texture under the finger
            drawNode?.cubeMap = { [weak cubeNode] point in cubeNode?.textureFraction(point) }
            pipeNode = cubeNode
        case "plato"  :
            let platoNode = PlatoNode(self, flo˚)
            touchCanvas.touchBegan = { [weak platoNode] point in platoNode?.touchBegan(point) ?? false }
            pipeNode = platoNode

        case "slide","zha","ave","fade","melt","tunl","fred",
             "drift","warren","noise"
            /**/      : pipeNode = CellNode  (self, flo˚)
        case "shape"  : pipeNode = ShapeNode (self, flo˚)
        case "wave"   : pipeNode = WaveNode  (self, flo˚)
        case "field"  : pipeNode = FieldNode (self, flo˚)
        default       : pipeNode = PipeNode  (self, flo˚)
        }
        pipeParent?.pipeChildren.append(pipeNode)
    }
}

