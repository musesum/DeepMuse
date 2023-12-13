// created by musesum.

#if os(visionOS)
import Metal
import CompositorServices

public protocol RendererProtocol {

    func makeResources()

    func makePipeline(_ layoutRenderer: LayerRenderer)

    func updateUniforms(_ layerDrawable: LayerRenderer.Drawable)

    func renderLayer(_ commandBuf: MTLCommandBuffer,
                   _ layerFrame: LayerRenderer.Frame,
                   _ layerDrawable: LayerRenderer.Drawable)
}
#endif
