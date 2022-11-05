
import Foundation
import Metal
import MetalKit
import AVKit
import Photos

public class MtlKernelRecord: MtlKernel {

    var isRecording = false
    var recordingStartTime = TimeInterval(0)

    private var assetWriter: AVAssetWriter?
    private var assetWriterInput: AVAssetWriterInput?
    private var inputPixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?

    override public init(_ name: String,
                         _ device: MTLDevice,
                         _ size: CGSize,
                         _ type: String) {

        super.init(name, device, size, type)
        // placeholder nameIndex["record"] = 0
        setupSampler()
    }

    override public func setOn(_ isOn: Bool, _ completion: @escaping ()->()) {
        self.isOn = isOn
        if isOn {
            startRecording() {
            print("-> startRecording")
                completion()
            }
        }
        else {
            endRecording {
                completion()
                print("-> endRecording")
            }
        }
    }

    public override func goCommand(_ command: MTLCommandBuffer?) {

        inTex = inNode?.outTex ?? makeNewTex()
        outTex = inTex

        if isRecording, let inTex = inTex {
            writeFrame(inTex)
        }
        outNode?.goCommand(command)
    }

    // MARK: writer

    var docURL: URL?

    func removeURL(_ url: URL?) {
        guard let url = url else { return }
        if FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)

        }
    }
    func createOutputURL() -> URL? {
        docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        docURL?.appendPathComponent("test.m4v")
        guard let docURL = docURL else { print("🚫 createOutputURL failed"); return nil  }
        removeURL(docURL)
        return docURL
    }


    func setupAssetWriter() -> AVAssetWriter? {
        func bail(_ msg: String) { print("🚫 setupAssetWriter \(msg)") }
        guard let url = createOutputURL() else { print("🚫 createOutputURL failed"); return nil }
        assetWriter = try? AVAssetWriter(outputURL: url, fileType: AVFileType.m4v)
        guard let assetWriter = assetWriter else { print("🚫 assetWriter: nil"); return nil }

        let outputSettings: [String: Any] =
            [ AVVideoCodecKey: AVVideoCodecType.h264,
              AVVideoWidthKey: size.width,
             AVVideoHeightKey: size.height ]

        assetWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: outputSettings)
        guard let assetWriterInput = assetWriterInput else { bail("assetWriterInput: nil"); return assetWriter }
        assetWriterInput.expectsMediaDataInRealTime = true

        let sourcePixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: size.width,
            kCVPixelBufferHeightKey as String: size.height ]

        inputPixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: assetWriterInput,
            sourcePixelBufferAttributes: sourcePixelBufferAttributes)

        assetWriter.add(assetWriterInput)
        return assetWriter
    }

    func startRecording(_ completion: @escaping ()->()) {
        if isRecording { return }

        if let assetWriter = setupAssetWriter() {
            assetWriter.startWriting()
            assetWriter.startSession(atSourceTime: CMTime.zero)

            recordingStartTime = CACurrentMediaTime()
            isRecording = true
            completion()
        } else {
            completion()
        }
    }

    func endRecording(_ completion: @escaping ()->()) {
        
        if !isRecording { return }
        isRecording = false
        func bail(_ msg: String) { print("🚫 endRecording \(msg)"); completion() }
        guard let assetWriterInput = assetWriterInput else { return bail("assetWriterInput: nil)") }
        guard let assetWriter = assetWriter else { return bail("assetWriter: nil)") }

        assetWriterInput.markAsFinished()
        assetWriter.finishWriting {

            guard let docURL = self.docURL else { return bail("docURL: nil)") }

            switch PHPhotoLibrary.authorizationStatus() {
                case .notDetermined, .denied:

                    PHPhotoLibrary.requestAuthorization { auth in
                        if auth == .authorized {
                            self.saveInPhotoLibrary(docURL)
                        } else {
                            return bail("user denied access")
                        }
                    }
                case .authorized:

                    self.saveInPhotoLibrary(docURL)

                default: break
            }
            completion()
        }
    }

    private func saveInPhotoLibrary(_ url: URL) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }) { completed, error in
            if completed {
                self.removeURL(self.docURL)
                print("✔︎ \(#function) saved: \(url.absoluteString)")
            } else if let error = error {
                print("🚫 \(#function) error: \(error)")
            } else {
                print("🚫 \(#function) failed: \(url.absoluteString)")
            }
        }
    }
    func writeFrame(_ texture: MTLTexture) {

        func bail(_ msg: String) { print("🚫 writeFrame \(msg)") }

        if !isRecording { return bail("not recording") }
        guard let input = assetWriterInput else { return bail("assetWriterInput: nil)") }
        while !input.isReadyForMoreMediaData {} //!! TODO: can lockup UI 

        guard let adapter = inputPixelBufferAdaptor else { return bail("inputPixelBufferAdaptor: nil") }
        guard let pixelBufferPool = adapter.pixelBufferPool else { return bail("pixelBufferPool: nil")}

        // pixel buffer
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferPoolCreatePixelBuffer(nil, pixelBufferPool, &pixelBuffer)
        if status != kCVReturnSuccess { return bail("dropping frame...") }
        guard let pixelBuffer = pixelBuffer else { return bail("pixelBuffer: nil") }
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        guard let address = CVPixelBufferGetBaseAddress(pixelBuffer) else { return bail("CVPixelBufferGetBaseAddress nil") }

        // stride may be rounded up to be 16-byte aligned
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let region = MTLRegionMake2D(0, 0, texture.width, texture.height)
        texture.getBytes(address, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)

        // get timeframe
        let frameTime = CACurrentMediaTime() - recordingStartTime
        let presentationTime = CMTimeMakeWithSeconds(frameTime, preferredTimescale: 240)

        adapter.append(pixelBuffer, withPresentationTime: presentationTime)

        CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
    }
}

