import UIKit

public class MuOrientation: UIView {
    public static let shared = MuOrientation()

    //?? public var uiOrientation = UIInterfaceOrientation.portrait
    private var orientation = UIDeviceOrientation.portrait

    public var radians = CGFloat(0)
    public var closures = [()->()]()

    public func addClosure(_ closure: @escaping ()->()) { closures.append(closure) }

    /// where to attach panel to dock cursor
    public enum AttachFrom { case above, below, left, right }
    public var attachFrom: AttachFrom  { get { // dock is below panel
        switch (UIApplication.uiOrientation(), orientation) {
            case (.portrait,           .portrait           ): return .below
            case (.portrait,           .landscapeLeft      ): return .above
            case (.portrait,           .portraitUpsideDown ): return .above
            case (.portrait,           .landscapeRight     ): return .below

            case (.landscapeLeft,      .portrait           ): return .above
            case (.landscapeLeft,      .landscapeLeft      ): return .above
            case (.landscapeLeft,      .portraitUpsideDown ): return .below
            case (.landscapeLeft,      .landscapeRight     ): return .below

            case (.portraitUpsideDown, .portrait           ): return .below
            case (.portraitUpsideDown, .landscapeLeft      ): return .above
            case (.portraitUpsideDown, .portraitUpsideDown ): return .below
            case (.portraitUpsideDown, .landscapeRight     ): return .above

            case (.landscapeRight,     .portrait           ): return .above
            case (.landscapeRight,     .landscapeLeft      ): return .below
            case (.landscapeRight,     .portraitUpsideDown ): return .below
            case (.landscapeRight,     .landscapeRight     ): return .above
            default:                                          return .above
        }
    } }

    public init() {

        super.init(frame: .zero)

        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged(_:)), name: NSNotification.Name("UIDeviceOrientationDidChangeNotification"), object: nil)
        #if os(xrOS)
        #else
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        #endif
        updateRadiansFromDevice()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    @objc public func orientationChanged(_ notification: Notification?) {

        updateRadiansFromDevice()
        //printOrientation()
        for closure in closures {
            closure()
        }
    }

    func updateRadiansFromDevice() {
        #if os(xrOS)
        radians = .pi * 1.5 //??? 
        #else
        if  ![.portrait, .landscapeLeft, .portraitUpsideDown, .landscapeRight].contains(UIDevice.current.orientation) { return }

        orientation = UIDevice.current.orientation
        switch (UIApplication.uiOrientation(), orientation) {
            case (.portrait,           .portrait          ):  radians = .pi * 0.0
            case (.portrait,           .landscapeLeft     ):  radians = .pi * 0.5
            case (.portrait,           .portraitUpsideDown):  radians = .pi * 1.0
            case (.portrait,           .landscapeRight    ):  radians = .pi * 1.5

            case (.landscapeLeft,      .portrait          ):  radians = .pi * 0.5
            case (.landscapeLeft,      .landscapeLeft     ):  radians = .pi * 1.0
            case (.landscapeLeft,      .portraitUpsideDown):  radians = .pi * 1.5

            case (.landscapeLeft,      .landscapeRight    ):  radians = .pi * 0.0
            case (.portraitUpsideDown, .portrait          ):  radians = .pi * 0.0
            case (.portraitUpsideDown, .landscapeLeft     ):  radians = .pi * 0.5
            case (.portraitUpsideDown, .portraitUpsideDown):  radians = .pi * 1.0
            case (.portraitUpsideDown, .landscapeRight    ):  radians = .pi * 1.5

            case (.landscapeRight,     .portrait          ):  radians = .pi * 1.5
            case (.landscapeRight,     .landscapeLeft     ):  radians = .pi * 0.0
            case (.landscapeRight,     .portraitUpsideDown):  radians = .pi * 0.5
            case (.landscapeRight,     .landscapeRight    ):  radians = .pi * 1.0
            default:                                          radians = .pi * 0
        }
        #endif
    }

    func printOrientation() {
        var log = ""
        switch UIApplication.uiOrientation() {
            case .unknown:            log = " ?⟳"
            case .portrait:           log = " ^⟳"
            case .landscapeLeft:      log = " <⟳"
            case .portraitUpsideDown: log = " v⟳"
            case .landscapeRight:     log = " >⟳"
            default:                  log = " ◇⟳"
        }
        switch orientation {
            case .unknown:            log += "?"
            case .portrait:           log += "^"
            case .landscapeLeft:      log += "<"
            case .portraitUpsideDown: log += "v"
            case .landscapeRight:     log += ">"
            default:                  log += "◇"
        }
        log += String(format:" %.2f", radians)
        switch attachFrom {
            case .left:     log += " left"
            case .right:    log += " right"
            case .above:    log += " above"
            case .below:    log += " below"
        }
        print(log)
    }
}
