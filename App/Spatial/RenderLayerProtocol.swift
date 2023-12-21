// created by musesum.

#if os(visionOS)

import Metal
import CompositorServices

public protocol RenderLayerProtocol {

    func makeResources()

    func makePipeline()

    func updateUniforms(_ drawable: LayerRenderer.Drawable)

    func renderLayer(_ commandBuf: MTLCommandBuffer,
                     _ layerFrame: LayerRenderer.Frame,
                     _ layerDrawable: LayerRenderer.Drawable)
}

#endif
