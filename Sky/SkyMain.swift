import AVFoundation
import CoreMedia
import MuMenu // DisplayLink
import MuTime // NextFrame
import MuFlo

class SkyMain {

    static let shared = SkyMain()
    private var drawBuf: [CVPixelBuffer?] = [nil, nil]
    private var palBuf: CVPixelBuffer?
    var mainFps˚: Flo?
    

    init() {
        initPixelBuffer(SkyFlo.shared.skySize)
        NextFrame.shared.addFrameDelegate("SkyMain".hash, self)
        mainFps˚ = SkyFlo.shared.root˚.bind("sky.main.fps") { f,_ in
            NextFrame.shared.updateFps(f.int) }
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
}
extension SkyMain: NextFrameDelegate {
    func nextFrame() -> Bool {
        SkyPipeline.shared.mtkView.draw()
        return true
    }
}
