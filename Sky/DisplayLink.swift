import UIKit
import QuartzCore
import Tr3

protocol DispalayLinkDelegate: NSObjectProtocol {
    func nextFrame()
}

class DisplayLink: NSObject {

    static let shared = DisplayLink()
    static var goAppBlock = false
    static var goAppCount = 0

    var link: CADisplayLink?
   
    var fps = 60

    var delegates = [Int: DispalayLinkDelegate]()

    override init() {
        
        super.init()
        
        link = UIScreen.main.displayLink(withTarget: self, selector: #selector(drawFrame))
        link?.preferredFramesPerSecond = fps
        link?.add(to: RunLoop.current, forMode: .default)
        //tr3Osc = Tr3Osc(sky)
    }

    func updateFps(_ newFps: Int?) {
        if let newFps,
            fps != newFps {
            fps = newFps
            link?.preferredFramesPerSecond = fps
        }
    }

    @objc func drawFrame()  {

        for delegate in delegates.values {
            delegate.nextFrame()
        }
        goApp()
    }

    func goApp() {

        if  DisplayLink.goAppBlock == false {
            DisplayLink.goAppBlock = true

            // tr3Osc?.oscReceiverLoop()
            DisplayLink.goAppCount += 1
            DisplayLink.goAppBlock = false
            
        }
    }
}
