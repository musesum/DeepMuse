// created by musesum.

#if os(visionOS)
import Metal
import MetalKit
import ARKit
import Spatial
import CompositorServices
import RealityKit

import MuVision
import MuMetal

/// This is the example specific part of rendering metal within VisionOS.
/// The example uses earth in the foreground and stars in the background.
class SkyRender: RenderLayer {

    var pipeline: Pipeline!
    var sceneTime =  CFTimeInterval(0)
    var lastRenderTime = CFTimeInterval(0)

    override init(_ renderer: LayerRenderer) {
        super.init(renderer)
        self.lastRenderTime = CACurrentMediaTime()
        self.pipeline = SkyCanvas.shared.pipeline
        setDelegate(self)
        startRenderLoop()
    }
}

extension SkyRender: RenderLayerProtocol {

    func makeResources() {
        //print("RenderSky:\(#function)")
    }
    
    func makePipeline() {
        //print("RenderSky:\(#function)")
    }

    func updateUniforms(_ layerDrawable: LayerRenderer.Drawable) {
        //print("RenderSky:\(#function)")
    }

    func computeLayer(_ commandBuf: MTLCommandBuffer) {
        
        pipeline?.kernelNodes(commandBuf)
    }

    func renderLayer(_ commandBuf    : MTLCommandBuffer,
                     _ layerDrawable : LayerRenderer.Drawable) {

       var node = pipeline?.renderNode

        // render
        if node?.metType == .rendering,
           let renderCmd = commandBuf.makeRenderCommandEncoder(descriptor: makeRenderPass(layerDrawable: layerDrawable)) {

            RenderLayer.setViewMappings(renderCmd, layerDrawable)

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
        func err(_ msg: String) {  print("\(#function) err: \(msg)") }
    }
}

#endif
