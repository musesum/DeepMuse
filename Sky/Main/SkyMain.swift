import AVFoundation
import CoreMedia

class SkyMain: NSObject, WorkLinkDelegate {

    static let shared = SkyMain()
    private var drawBuf: [CVPixelBuffer?] = [nil, nil]
    private var palBuf: CVPixelBuffer?

    override init() {
        super.init()
        initPixelBuffer(SkyTr3.shared.skySize)
        WorkLink.shared.delegates.append(self)
    }

    func initDrawBufIndex(_ index: Int, size: CGSize, options: [AnyHashable: Any]) {

        CVPixelBufferCreate(kCFAllocatorDefault, Int(size.width), Int(size.height),
                            kCVPixelFormatType_32BGRA, options as CFDictionary, &drawBuf[index])
    }

    func initPaletteOptions(_ options: [AnyHashable: Any]) {

        CVPixelBufferCreate(kCFAllocatorDefault, 256, 1,
        kCVPixelFormatType_32BGRA, options as CFDictionary, &palBuf)
    }

    func initPixelBuffer(_ size: CGSize) {

        let options = [
            kCVPixelBufferCGImageCompatibilityKey: NSNumber(value: true),
            kCVPixelBufferCGBitmapContextCompatibilityKey: NSNumber(value: true),
            kCVPixelBufferMetalCompatibilityKey: NSNumber(value: true)
        ]

        initDrawBufIndex(0, size: size, options: options)
        initDrawBufIndex(1, size: size, options: options)
        initPaletteOptions(options)
    }

    // MARK: - Advance Frame
    func nextFrame() {
        SkyPipeline.shared.mtkView.setNeedsDisplay()
    }
}
