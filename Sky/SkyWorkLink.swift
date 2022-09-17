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
    var mainFrame˚: Tr3?
    var mainFps˚: Tr3?
    var fps = 0

    var delegates = [SkyWorkLinkDelegate]()

    override init() {

        super.init()
        fps = 60

        displayLink = UIScreen.main.displayLink(withTarget: self, selector: #selector(drawFrame))
        displayLink?.preferredFramesPerSecond = fps
        displayLink?.add(to: RunLoop.current, forMode: .default)
        
        if let sky = SkyTr3.shared.root.findPath("sky") {
            mainFrame˚ = sky.findPath("main.frame")
            mainFps˚ = sky.findPath("main.fps")
            mainFps˚?.addClosure { tr3, _ in
                self.updateFps(tr3.IntVal())
            }
        }
        //tr3Osc = Tr3Osc(sky)
    }

    func updateFps(_ newFps: Int?) {
        if  let newFps = newFps,
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
            mainFrame˚?.setAny(SkyWorkLink.goAppCount, [.activate])

            SkyWorkLink.goAppBlock = false
        }
    }
}
