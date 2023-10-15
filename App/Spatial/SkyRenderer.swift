//
// created by musesum.

#if os(xrOS)
import Metal
import MetalKit
import ARKit
import Spatial
import CompositorServices

import MuMetal


/// This is the example specific part of rendering metal within VisionOS.
/// The example uses earth in the foreground and stars in the background.
class SkyRenderer: Renderer {

    var pipeline: MetPipeline!
    var sceneTime =  CFTimeInterval(0)
    var lastRenderTime = CFTimeInterval(0)

    override init(_ layerRenderer: LayerRenderer) {
        super.init(layerRenderer)
        self.lastRenderTime = CACurrentMediaTime()
        self.pipeline = SkyCanvas.shared.pipeline
        setDelegate(self)
        startRenderLoop()
    }
}

extension SkyRenderer: RendererProtocol {

    func makeResources() {
        //??? 
    }
    
    func makePipeline(_ layoutRenderer: LayerRenderer) {
        //???
    }
    func updateUniforms(_ drawable: LayerRenderer.Drawable) {
        //??? 
    }

    func drawAndPresent(_ commandBuf: MTLCommandBuffer,
                        _ frame: LayerRenderer.Frame,
                        _ drawable: LayerRenderer.Drawable) {

        let renderPass = makeRenderPass(drawable: drawable)

        guard let pipeline,
              let renderCommand = commandBuf.makeRenderCommandEncoder(
                descriptor: renderPass) else { fatalError(#function) }

        renderCommand.label = "Sky"
        renderCommand.pushDebugGroup("Sky")

        let viewports = drawable.views.map { $0.textureMap.viewport }
        renderCommand.setViewports(viewports)

        if let firstNode = pipeline.firstNode {
            //SkyCanvas.shared.pipeline.draw() //???
            firstNode.nextCommand(commandBuf)
        }

//        starsEyeBuf.setMappings(drawable, viewports, renderCommand)
//        starsMesh.draw(renderCommand, starsPipe, .clockwise)
//
//        earthEyeBuf.setMappings(drawable, viewports, renderCommand)
//        earthMesh.draw(renderCommand, earthPipe, .counterClockwise)


        renderCommand.popDebugGroup()
        renderCommand.endEncoding()
        drawable.encodePresent(commandBuffer: commandBuf)
        commandBuf.commit()
    }
}

#endif
