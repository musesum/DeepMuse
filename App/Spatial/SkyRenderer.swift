// created by musesum.

#if os(visionOS)
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
    func updateUniforms(_ layerDrawable: LayerRenderer.Drawable) {
        //???
    }

    func renderLayer(_ commandBuf    : MTLCommandBuffer,
                     _ layerFrame    : LayerRenderer.Frame,
                     _ layerDrawable : LayerRenderer.Drawable) {

        let renderPass = makeRenderPass(layerDrawable: layerDrawable)

        guard let pipeline,
              let renderNode = commandBuf.makeRenderCommandEncoder(
                descriptor: renderPass) else { fatalError(#function) }

        renderNode.label = "Sky"
        renderNode.pushDebugGroup("Sky")

        let viewports = layerDrawable.views.map { $0.textureMap.viewport }
        renderNode.setViewports(viewports)

        if let firstNode = pipeline.firstNode {
            SkyCanvas.shared.pipeline.drawNodes() //???
            //??? firstNode.nextCommand(cmdBuf)
        }

//        starsEyeBuf.setMappings(drawable, viewports, renderCmd)
//        starsMesh.drawMesh(renderCmd, starsPipe, .clockwise)
//        earthEyeBuf.setMappings(drawable, viewports, renderCmd)
//        earthMesh.drawMesh(renderCmd, earthPipe, .counterClockwise)

        renderNode.popDebugGroup()
        renderNode.endEncoding()
        layerDrawable.encodePresent(commandBuffer: commandBuf)
        commandBuf.commit()
    }
}

#endif
