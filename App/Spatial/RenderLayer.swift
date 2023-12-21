//  Created by musesum on 8/4/23.
#if os(visionOS)
import MetalKit
import ARKit
import Spatial
import CompositorServices
import simd

let TripleBufferCount = 3

class RenderLayer {

    let layerRenderer: LayerRenderer
    let device: MTLDevice
    let library: MTLLibrary
    let commandQueue: MTLCommandQueue

    var delegate: RenderLayerProtocol?
    let tripleSemaphore = DispatchSemaphore(value: TripleBufferCount)
    let arSession = ARKitSession()
    let worldTracking = WorldTrackingProvider()

    var rotation: Float = 0

    init(_ layerRenderer: LayerRenderer) {

        self.layerRenderer = layerRenderer
        self.device = MTLCreateSystemDefaultDevice()!
        self.library = device.makeDefaultLibrary()!
        self.commandQueue = device.makeCommandQueue()!
    }

    func setDelegate(_ delegate: RenderLayerProtocol) {
        self.delegate = delegate
        delegate.makeResources()
        delegate.makePipeline()
    }

    func makeRenderPass(layerDrawable: LayerRenderer.Drawable) -> MTLRenderPassDescriptor {

        let renderPass = MTLRenderPassDescriptor()
        renderPass.colorAttachments[0].texture = layerDrawable.colorTextures[0]
        renderPass.colorAttachments[0].loadAction = .clear
        renderPass.colorAttachments[0].storeAction = .store
        renderPass.colorAttachments[0].clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)

        renderPass.depthAttachment.texture = layerDrawable.depthTextures[0]
        renderPass.depthAttachment.loadAction = .clear
        renderPass.depthAttachment.storeAction = .store
        renderPass.depthAttachment.clearDepth = 0.0

        renderPass.rasterizationRateMap = layerDrawable.rasterizationRateMaps.first
        if layerRenderer.configuration.layout == .layered {
            renderPass.renderTargetArrayLength = layerDrawable.views.count
        }
        return renderPass
    }

    func renderFrame() {

        guard let delegate else { return }
        guard let layerFrame = layerRenderer.queryNextFrame() else { return }

        layerFrame.startUpdate()
        // Perform frame independent work
        layerFrame.endUpdate()

        guard let timing = layerFrame.predictTiming() else { return }
        LayerRenderer.Clock().wait(until: timing.optimalInputTime)
        guard let layerDrawable = layerFrame.queryDrawable() else { return }

        tripleSemaphore.wait()
        guard let commandBuf = commandQueue.makeCommandBuffer() else { fatalError("renderFrame::commandBuf") }
        commandBuf.addCompletedHandler { (_ commandBuf)-> Swift.Void in
            self.tripleSemaphore.signal()
        }

        layerFrame.startSubmission()
        let time = LayerRenderer.Clock.Instant.epoch.duration(to:  layerDrawable.frameTiming.presentationTime).timeInterval
        layerDrawable.deviceAnchor = worldTracking.queryDeviceAnchor(atTimestamp: time)
        delegate.renderLayer(commandBuf, layerFrame, layerDrawable)
        layerFrame.endSubmission()
    }

    func startRenderLoop() {
        Task {
            do {
                try await arSession.run([worldTracking])
            } catch {
                fatalError("Failed to initialize ARSession")
            }

            let renderThread = Thread {
                self.renderLoop()
            }
            renderThread.name = "RenderThread"
            renderThread.start()
        }
    }

    func renderLoop() {
        while true {
            switch layerRenderer.state {
            case .paused:  layerRenderer.waitUntilRunning()
            case .running: autoreleasepool { renderFrame() }
            case .invalidated: break
            @unknown default:  print("⁉️ RenderLayer::runLoop @unknown default")
            }
        }
    }
}
#endif
