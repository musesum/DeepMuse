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
        print("RenderSky:\(#function)")
    }
    
    func makePipeline() {
        print("RenderSky:\(#function)")
    }

    func updateUniforms(_ layerDrawable: LayerRenderer.Drawable) {
        print("RenderSky:\(#function)")
    }

    func renderLayer(_ commandBuf    : MTLCommandBuffer,
                     _ layerDrawable : LayerRenderer.Drawable) {

        // compute
        var node = pipeline?.computeNodes(commandBuf)

        // render
        if node?.metType == .rendering,
           let renderCmd = commandBuf.makeRenderCommandEncoder(descriptor: makeRenderPass(layerDrawable: layerDrawable)) {

            let viewports = layerDrawable.views.map { $0.textureMap.viewport }
            renderCmd.setViewports(viewports)
            setViewMappings(renderCmd, layerDrawable, viewports)

            while let nodeNow = node as? RenderNode {
                nodeNow.updateUniforms(layerDrawable)
                nodeNow.updateTextures()
                nodeNow.renderNode(renderCmd)
                node = nodeNow.outNode
            }
            renderCmd.endEncoding()
        }
        layerDrawable.encodePresent(commandBuffer: commandBuf)
        commandBuf.commit()
        commandBuf.waitUntilCompleted()
    }
    
}

#endif
