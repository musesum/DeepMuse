// created by musesum.

#if os(visionOS)
import Metal
import MetalKit
import ARKit
import Spatial
import CompositorServices
import MuVision

import MuMetal

/// This is the example specific part of rendering metal within VisionOS.
/// The example uses earth in the foreground and stars in the background.
class RenderSky: RenderLayer {

    var pipeline: Pipeline!
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

extension RenderSky: RenderLayerProtocol {

    func makeResources() {
        //??? 
    }
    
    func makePipeline() {
        //???
    }

    func updateUniforms(_ layerDrawable: LayerRenderer.Drawable) {
        print(".", terminator: "")
    }

    func renderLayer(_ commandBuf    : MTLCommandBuffer,
                     _ layerFrame    : LayerRenderer.Frame,
                     _ layerDrawable : LayerRenderer.Drawable) {

        updateMetal(layerDrawable)
        let renderPass = makeRenderPass(layerDrawable: layerDrawable)

        guard let pipeline,
              let renderNode = commandBuf.makeRenderCommandEncoder(
                descriptor: renderPass) else { fatalError(#function) }

        renderNode.label = "Sky"
        renderNode.pushDebugGroup("Sky")

        let viewports = layerDrawable.views.map { $0.textureMap.viewport }
        renderNode.setViewports(viewports)

        pipeline.drawNodes()
        //???? pipeline.drawLayer(layerDrawable, renderCmd, viewports)

        renderNode.popDebugGroup()
        renderNode.endEncoding()
        layerDrawable.encodePresent(commandBuffer: commandBuf)
        commandBuf.commit()
    }
}

#endif
