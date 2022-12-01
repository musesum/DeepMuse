
import AVFoundation
import Metal
import UIKit
import Tr3

public final class CameraSession: NSObject {
    public static var shared = CameraSession()
    private var cameraFlip˚: Tr3?

    public override init() {

        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(captureSessionRuntimeError), name: NSNotification.Name.AVCaptureSessionRuntimeError, object: nil)
        initCameraFlip()
    }
    public var uiOrientation = UIInterfaceOrientation.portrait
    var orientation = AVCaptureVideoOrientation.portrait

    public var camTex: MTLTexture?  // optional texture 2
    public var cameraPosition = AVCaptureDevice.Position.front
    public enum CameraType: Int {
        case frontPhone=0, frontPad, backPhone, backPad
        var desciption: String {
            return ""
        }
    }
    public var cameraType: CameraType {
        let idom = UIDevice.current.userInterfaceIdiom
        switch (cameraPosition, idom) {
            case (.front, .phone): return .frontPhone
            case (.back, .phone):  return .backPhone
            case (.front, .pad):   return .frontPad
            case (.back, .pad):    return .backPad
            default:               return .frontPhone
        }
    }
    func initCameraFlip() {
        let camera = SkyTr3.shared.root.findPath("shader.model.pipe.camera")
        cameraFlip˚ = camera?.findPath("flip") ?? nil
        cameraFlip˚?.addClosure  { tr3, _ in CameraSession.shared.flipCamera() }
    }


    /**
     Start capture session.

       - note: Call to start receiving delegate updates with the sample buffers.
     */
    public func startCamera() {

        func initCamera() {
            do {
                captureSession.beginConfiguration()
                try initializeInputDevice()
                try initializeOutputData()
                updateOrientation()
                captureSession.commitConfiguration()

                try initializeTextureCache()
                captureSession.startRunning()
                state = .streaming
            }
            catch let error as AsCameraError {
                handleError(error)
            }
            catch {
                // only throw `AsCameraError` errors.
            }
        }

        switch state {
            case .waiting:

                requestCameraAccess()
                captureQueue.async(execute: initCamera)

            case .ready,
                .stopped:

                captureSession.startRunning()
                updateOrientation()
                state = .streaming

            case .streaming,
                    .error: break
        }
    }

    /// Stop the capture session.
    public func stopCamera() {
        captureQueue.async {
            if self.state != .stopped {
                //print("*** .stop")
                self.captureSession.stopRunning()
                self.state = .stopped
            }
        }
    }

    public func setCameraOn(_ isOn: Bool) {

        if isOn {
            if state != .streaming {
                startCamera()
            }
        } else {
            if state == .streaming {
                stopCamera()
            }
        }
    }

    public func flipCamera() {
        if cameraPosition == .front {
            cameraPosition = .back
        }
        else {
            cameraPosition = .front
        }
        captureSession.beginConfiguration()
        if let currentInput = captureSession.inputs.first as? AVCaptureDeviceInput {
            captureSession.removeInput(currentInput)
            try? initializeInputDevice()
            updateOrientation()
        }
        captureSession.commitConfiguration()
    }

    // MARK: Private properties and methods
    
    /// Current session state.
    public var state: CameraState = .waiting {
        didSet {
            guard state != .error else { return }
            print("   \(#function): \(oldValue) -> \(state)")
        }
    }
    fileprivate var captureSession = AVCaptureSession()
 
    /// Dispatch queue for capture session events.
    fileprivate var captureQueue = DispatchQueue(label: "MetalCameraSessionQueue", attributes: [])

    /// Texture cache we will use for converting frame images to textures
    internal var textureCache: CVMetalTextureCache?

    fileprivate var metalDevice = MTLCreateSystemDefaultDevice()

    /// Current capture input device.
    internal var inputDevice: AVCaptureDeviceInput? {
        didSet {
            if let oldValue = oldValue {
                print("   \(#function): \(oldValue) -> \(inputDevice!)")
                captureSession.removeInput(oldValue)
            }
            if let inputDevice = inputDevice  {
                captureSession.addInput(inputDevice)
            }
        }
    }
    
    /// Current capture output data stream.
    internal var outputData: AVCaptureVideoDataOutput? {
        didSet {
            if let oldValue = oldValue {
                print("   \(#function): \(oldValue) -> \( outputData!)")
                captureSession.removeOutput(oldValue)
            }
            if let outputData = outputData {
                captureSession.addOutput(outputData)
            }
        }
    }

     /// Requests access to camera hardware.
    fileprivate func requestCameraAccess() {

        AVCaptureDevice.requestAccess(for: .video) { (granted: Bool) in
            
            guard granted else {
                self.handleError(.noHardwareAccess)
                return
            }
            if self.state != .streaming && self.state != .error {
                self.state = .ready
            }
        }
    }
    
    func handleError(_ error: AsCameraError) {
        if error.isStreamingError() {
            state = .error
        }
        if error == .captureSessionRuntimeError {
            startCamera() // ignore runtime erros
        }
        else {
            print("🚫 Camera error: \(error)")
        }
    }

    /// camera frames to textures.
    private func initializeTextureCache() throws {

        guard
            let metalDevice = metalDevice,
            CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, metalDevice, nil, &textureCache) == kCVReturnSuccess
        else {
            throw AsCameraError.failedToCreateTextureCache
        }
    }

    /**
     initializes capture input device with media type and device position.

     - throws: `AsCameraError` fails to init or add input device
    */
    fileprivate func initializeInputDevice() throws {

        captureSession.sessionPreset = .hd1920x1080

        let deviceDiscoverySession =
            AVCaptureDevice.default(.builtInWideAngleCamera,
                                    for: AVMediaType.video,
                                    position: cameraPosition)

        guard let captureDevice = deviceDiscoverySession else {
            print("Failed to get the camera device")
            return
        }
        var captureInput: AVCaptureDeviceInput

        do {
            captureInput = try AVCaptureDeviceInput(device: captureDevice)
        }
        catch {
            throw AsCameraError.inputDeviceNotAvailable
        }
        guard captureSession.canAddInput(captureInput) else {
            throw AsCameraError.failedToAddCaptureInputDevice
        }

        self.inputDevice = captureInput
    }

    func updateOrientation() {
        
        let uiVideo: [UIInterfaceOrientation: AVCaptureVideoOrientation] =
        [.portrait:           .portrait,
         .landscapeRight:     .landscapeRight,
         .landscapeLeft:      .landscapeLeft,
         .portraitUpsideDown: .portraitUpsideDown]

       guard let videoOrient = uiVideo[uiOrientation]  else  {
           print("🚫 \(#function) deviceOrient \(uiVideo) not found"); return }
        guard let output = outputData else {
            print("🚫 \(#function) nil outputData"); return }
        guard let connection = output.connection(with: .video) else {
            print("🚫 \(#function) no connection"); return }
        orientation = videoOrient
        connection.videoOrientation = orientation
        //print(" \(#function) orientation: \(uiOrientation.rawValue) -> \(orientation.rawValue) bounds:\(UIScreen.main.bounds)")
    }

    /**
     initialize capture output data stream.

     - throws: `AsCameraError` fails to init or add output data stream
    */
    fileprivate func initializeOutputData() throws {
        let out = AVCaptureVideoDataOutput()
        out.videoSettings = [ kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA ]
        out.alwaysDiscardsLateVideoFrames = true
        out.setSampleBufferDelegate(self as AVCaptureVideoDataOutputSampleBufferDelegate, queue: captureQueue)
        guard captureSession.canAddOutput(out) else {
            throw AsCameraError.failedToAddCaptureOutput
        }
        self.outputData = out
    }
    
    /// `AVCaptureSessionRuntimeErrorNotification` callback.
    @objc fileprivate func captureSessionRuntimeError() {
        if state == .streaming {
            handleError(.captureSessionRuntimeError)
        }
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

