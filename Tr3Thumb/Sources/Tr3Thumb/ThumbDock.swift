
import UIKit
import QuartzCore
import MuCubic
import MuUtilities

public class ThumbDock: UIView {

    var cursorSize = CGSize.zero
    var minfactor = CGFloat(0) // relative size of last place to 2nd and 3rd nearest
    var popFactor = CGFloat(0) // popup size of 1st nearest to 2nd and 3rd nearest
    var maxFactor = CGFloat(0) // largest calculated factor

    var dotIndex = 0             // cursor is pointing to i'th item in list
    var dotPosition = CGFloat(0) // x position for x, account for dock margin
    var dotNames = [String : ThumbDot]() // selected dot, used to animate curosor underneath
    var localGesture = false     // allow touch to draw when not near a collapsed home button

    var beganPoint = CGPoint.zero
    var beganTime = CFTimeInterval(0) // time of most recent TouchesBegin
    var endedTime = CFTimeInterval(0) // time of most recent TouchesEnded

    var moving   = false // only arrange dots for large finger movements
    var dragging = false // user is manually dragging dot around dock
    var hovering = false // thumb is hovering over dot

    var dockStartTime = CFTimeInterval(0) //used by animateDock
    var dockTimer: Timer?   // used by updateDock.animateDock
    var hideTimer: Timer?   // wait for a while before hiding dock's dots
    var panelTimer: Timer?  // wait for a while touching by not hovering to show Panel
    var cursorLoop: Timer?  // animation loop timer for moving curson under dotNow

    var dotRing = ThumbView()
    
    public var dots = [ThumbDot]()
    public var dotNow: ThumbDot?

    var cursor: UIImageView!
    var cursorCenter = CGPoint.zero //adjusted cursor to occomadate growing dots
    var cursorPark   = CGPoint.zero // leftmost parking position for cursor

    var factor = CGFloat(0.010)
    var remain = CGFloat(0.010)
    var state = ShowState.hidden
    var SkyView: UIView!

    var cubic = MuCubic()

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public init(_ SkyView_: UIView) {

        super.init(frame:.zero)
        SkyView = SkyView_

        localGesture = true
        cursorSize = CGSize(width: 48, height: 48)
        updateFrame()

        initFactors()
        initDotRing()

        initCursor(name:"icon.ring.roygbiv.png")

        SkyView.addSubview(dotRing)
        SkyView.addSubview(cursor)
        SkyView.addSubview(self)

        // rotate dots and panels with user changes orientation
        OrienteDevice.shared.addClosure(resetOrientation)

    }

    func getFactor(_ itemNow: Int) -> CGFloat {

        let delta = abs(dotPosition - CGFloat(itemNow))
        let popup = delta < 1.0 ? (1.0 - delta) : 0.0
        let factor = minfactor + popFactor * (popup + min(1.0, 1.0 / delta))
        maxFactor = max(maxFactor, factor)
        return factor
    }

    func calcDotPositions() {

        var radii       = [CGFloat]()
        var minFactor   = CGFloat(9999)
        var maxFactor   = CGFloat(0)
        var deltaFactor = CGFloat(0)

        func calcRunway() -> CGFloat {

            var sumRunway = CGFloat(0) // sum of scaled dot widths

            for i in 0 ..< dots.count {

                let factor = getFactor(i)
                minFactor = min(minFactor, factor)
                maxFactor = max(maxFactor, factor)
                let dot = dots[i]

                let scale  = dot.dragging ? maxFactor : factor
                let radius = dot.radius(forScale: scale)

                radii.append(radius)
                sumRunway += dot.thumbSize.width * scale * dot.scaled
            }
            if let radiFirst = radii.first,
                let radiLast = radii.last {

                let thisRunway = frame.size.width - radiFirst - radiLast
                sumRunway = sumRunway - radiFirst - radiLast

                deltaFactor = maxFactor - minFactor
                if deltaFactor == 0 {  deltaFactor = 1 }
                let factorRunway = thisRunway / sumRunway
                return factorRunway
            }
            return 0
        }

        let factorRunway = calcRunway()
        var nowCenter = radii.first!

        let window = UIApplication.shared.windows.first
        let inset  = window?.safeAreaInsets.bottom ?? 0.0
        let height = UIScreen.main.bounds.height - inset

        for i in 0 ..< dots.count {

            let dot = dots[i]
            let factor = getFactor(i)
            let radius = radii[i]

            nowCenter = i == 0 ? radius : nowCenter + (radii[i-1] + radius) * factorRunway

            let factori = (factor - minFactor) / deltaFactor
            let centerY = height - radius - (cursorSize.height * factori)
            dot.calcCenter = CGPoint(x: nowCenter, y: centerY)
        }
    }

    func relocate(dot dot_: ThumbDot?, hideChild: Bool) {

        if let dot_ = dot_ {

            if dotNow != dot_ {
                updateDotNow(dot_)
            }
            if let dot = dotNow {

                dockTimer?.invalidate()
                hideTimer?.invalidate()
                panelTimer?.invalidate()
                cursorLoop?.invalidate()

                func looping(_ factor: CGFloat) {

                    let distance = dot.center.x - cursor.center.x
                    let deltaX = distance * factor

                    cursor.center.x = cursor.center.x + deltaX
                    calcDotCenters()
                    arrangeDots()
                }
                cursorLoop = Looper(AnimDuration,LoopTime,looping)
            }
        }
    }

    /// update dotNow to new value
    /// hide panels for old dotNow
    func updateDotNow(_ dotNow_:ThumbDot) {
        dotNow = dotNow_
        for dot in dots {
            if dot != dotNow {
                dot.panel?.hidePanel("relocate")
            }
        }
    }

    func calcDotCenters() {

        let firstDot = dots.first
        let lastDot = dots.last

        let firstFactor = getFactor(0)
        let lastFactor = getFactor(dots.count - 1)
        firstDot?.scale = CGFloat(firstFactor)
        lastDot?.scale = CGFloat(lastFactor)

        let firstCenterX = CGFloat(firstDot?.calcCenter.x ?? 0.0) // only cursor
        let lastCenterX = CGFloat(lastDot?.calcCenter.x ?? 0.0)

        cursorCenter.x = firstCenterX.range(cursor.center.x, lastCenterX)

        if cursorCenter.x <= CGFloat(firstCenterX) {

            cursorCenter.x = CGFloat(firstCenterX)
            dotIndex = 0
            dotPosition = 0
        }
        else if cursorCenter.x >= lastCenterX {

            cursorCenter.x = lastCenterX
            dotIndex = dots.count - 1
            dotPosition = CGFloat(dots.count - 1)
        }
        else {
            var minDelta: CGFloat = 999999
            for i in 0..<dots.count {

                let dot = dots[i]
                let deltaX = dot.calcCenter.x - cursorCenter.x

                if abs(deltaX) < abs(minDelta) {
                    minDelta = deltaX
                    dotIndex = i
                }
            }
            let nextIndex = (minDelta > 0 ? max(0, dotIndex - 1) : min(dots.count - 1, dotIndex + 1))
            let nextDot = dots[nextIndex]
            let nearDot = dots[dotIndex]
            let deltaDotX = nextDot.calcCenter.x - nearDot.calcCenter.x
            dotPosition = deltaDotX == 0 ? CGFloat(dotIndex) : CGFloat(dotIndex) + abs(minDelta) / deltaDotX
        }
    }

    public func arrangeDots() {

        calcDotPositions()

        var dotNext = dotNow
        
        for i in 0 ..< dots.count {
            
            let dot = dots[i]
            dot.tag = i
            let delta = dot.calcCenter - cursor.center
            let reveal = dot.calcCenter - delta * remain
            dot.dockCenter = reveal

            if dot.dragging {
                dot.center = dot.touchMove
                dot.scale = maxFactor
            }
            else {

                let factor = max(self.factor, (dot == dotNow ? 0.5 : 0.001))
                dot.scale = getFactor(i) * factor
                dot.center = reveal
            }
            //print(String(format:"%.2f:(%.f,%.f)",dot.scale,reveal.x,reveal.y), terminator:" ")
            if let d = dotNext, d.scale < dot.scale {
                dotNext = dot
            }
        }
        //print()
        arrangeDotViews()
        updateDotNow(dotNext!)

        superview?.bringSubviewToFront(self)
    }

    /// rotate dots and panels when user flips between landscape and portrait orientations
    func resetOrientation() {

        UIView.animate(withDuration: AnimDuration, delay: 0, options: AnimUser, animations: {

            self.cursor.transform = CGAffineTransform.identity
                .rotated(by: OrienteDevice.shared.radians)
                .scaledBy(x: 1, y: 1)

            for dot in self.dots {

                dot.reorientCenter()
                dot.panel?.reorientCenter()
            }
        })
    }

    func initFactors() {

        let isIpad = UIDevice.current.userInterfaceIdiom == .pad
        minfactor = isIpad ? 1.0 : 1.0 // relative size of last place to 2nd and 3rd nearest
        popFactor = isIpad ? 1.0 : 1.0 // popup size of 1st nearest to 2nd and 3rd nearest
        maxFactor = minfactor + popFactor // this get increased by getFactor for all factors
    }

    func initDotRing() {

        dotNow = nil
        dotRing = ThumbView()
        if let img = UIImage(named: "icon.ring.white") {
            dotRing.addImage(img)
        }
        dotRing.isUserInteractionEnabled = false
        dotRing.scaled = 1
    }

    func initCursor(name: String) {

        let img = UIImage(named: name)
        if let scaled = img?.scaledTo(CGSize(width: 48, height: 48)) {
            cursor = UIImageView(image: scaled) //TODO: Catch error
            cursor.isUserInteractionEnabled = false
            cursor.center = cursorPark
        }
        else {
            print("*** missing cursor: \(name)")
        }
    }

    func updateFrame() {

        let bounds = UIScreen.main.bounds
        let window = UIApplication.shared.windows.first
        let inset = window?.safeAreaInsets.bottom ?? 0.0

        let w = bounds.size.width
        let h = cursorSize.height
        let y = bounds.size.height - h - inset

        frame = CGRect(x: 0, y: y, width: w, height: h)

        dotIndex = 0
        cursorPark = CGPoint(x: cursorSize.width / 2,
                             y: bounds.size.height - cursorSize.height / 2 - inset)
        cursorCenter = cursorPark
    }

    /// thumbDot dots never go outside display area
    /// so calculate the range for cursor between
    /// first and last icon, when they are fully expanded
    ///
    func arrangeDotViews() {

        var foundSelection = false

        func bringToFront(_ index: Int) {
            let dot = dots[index]
            if dot == dotNow { foundSelection = true }
            superview?.bringSubviewToFront(dot)
        }

        // stack preceeding views to front
        for i in 0 ..< dotIndex { bringToFront(i) }
        for i in (dotIndex ..< dots.count).reversed() { bringToFront(i) }
        superview?.bringSubviewToFront(cursor)

        if !foundSelection {

            dotNow = nil
            dotRing.alpha = 0
        }
        else {
            dotRing.alpha = 1
            dotRing.scale = dotNow?.scale ?? 0.0
            //PrintThumbDock("*** %.2f ", dotNow?.scale)

            if let dotNow = dotNow {
                 dotRing.center = dotNow.dragging ? dotNow.calcCenter : dotNow.dockCenter
                superview?.insertSubview(dotRing, aboveSubview: dotNow)
            }
        }

    }

    public func reorderDots(_ reorderNames:[String]) {

        var reorderDots = [ThumbDot]()

        // Ot(n^2) for a small number of dots
        func findDot(_ reorderName:String) -> Bool {
            for dot in dots {
                if dot.name == reorderName {
                    reorderDots.append(dot)
                    return true
                }
            }
            return false
        }

        for reorderName in reorderNames {
            if !findDot(reorderName) {
                print("*** dot named: \(reorderName) not found")
            }
        }
        let removeDots = Set(dots).subtracting(reorderDots)
        for dot in removeDots {
            dot.removeFromSuperview()
        }
        dots = reorderDots
    }
    public func printDotNames() {
        print("ThumbDock: ", terminator: "")
        for dot in dots {
            print(dot.name + " ", terminator: "")
        }
    }
    public func updatePanels() {
        for dot in dots {
            if let controls = dot.panel?.controls  {
                for control in controls {
                    if let tr3Node = control.tr3Node,
                        let parent = tr3Node.parent,
                            parent.name == "Version" {

                            tr3Node.activate()
                    }
                }
            }
        }
    }

}
