import UIKit
import QuartzCore
import Tr3

protocol SkyWorkLinkDelegate: NSObjectProtocol {
    func nextFrame()
}

class SkyWorkLink: NSObject {

    static let shared = SkyWorkLink()
    static var goAppBlock = false
    static var goAppCount = 0

    var displayLink: CADisplayLink?
    var mainFps˚: Tr3?
    var fps = 60

    var delegates = [SkyWorkLinkDelegate]()

    override init() {

        super.init()

        displayLink = UIScreen.main.displayLink(withTarget: self, selector: #selector(drawFrame))
        displayLink?.preferredFramesPerSecond = fps
        displayLink?.add(to: RunLoop.current, forMode: .default)
        //tr3Osc = Tr3Osc(sky)
    }

    func updateFps(_ newFps: Int?) {
        if let newFps,
            fps != newFps {
            fps = newFps
            displayLink?.preferredFramesPerSecond = fps
        }
    }

    @objc func drawFrame()  {

        for delegate in delegates {
            delegate.nextFrame()
        }
        goApp()
    }

    func goApp() {

        if  SkyWorkLink.goAppBlock == false {
            SkyWorkLink.goAppBlock = true

            // tr3Osc?.oscReceiverLoop()
            SkyWorkLink.goAppCount += 1
            SkyWorkLink.goAppBlock = false
            
        }
    }
}
