import UIKit
import Tr3
import MuUtilities

extension ThumbPanel {
}
class ThumbPanel: ThumbView {

    var state = ShowState.hidden
    var SkyView: UIView!
    var controls = [ThumbBase]()
    var thumbDot: ThumbDot!
    var title: UILabel?
    var dismiss: UIButton?

    var hideLoop: Timer?    // animation loop to hide panel
    var showLoop: Timer?    // animation loop to show panel


    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    init(_ SkyView_:UIView) {
        super.init()
        SkyView = SkyView_
        addBlur()
        scaled = 1.0
        scale = 0.01
        alpha = 0
    }
    convenience init(_ SkyView_:UIView, tr3: Tr3) {

        self.init(SkyView_)
         makeControlPanel(for: tr3)
    }

    func makeControlPanel(for tr3: Tr3) {

        controls.removeAll()

        for child in tr3.children {
            switch child.name {
            case "base"     : updateBase(for: child)
            case "controls" : child.children.forEach { makeThumbControl($0)}
            default: break
            }
        }
    }

    /// make a control for panel based on `type` value
    func makeThumbControl(_ tr3: Tr3) {

        func addThumb(_ thumb:ThumbBase) {
            controls.append(thumb)
            self.addSubview(thumb)
        }
        if let type = tr3.findPath("type")?.StringVal() {
            switch type {
                case "segment": addThumb(ThumbSegment(tr3: tr3, self))
                case "panelon": addThumb(ThumbPanelOn(tr3: tr3, self))
                case "panelx":  addThumb(ThumbPanelX(tr3: tr3, self))
                case "trigger": addThumb(ThumbTrigger(tr3: tr3, self))
                case "switch":  addThumb(ThumbSwitch(tr3: tr3, self))
                case "slider":  addThumb(ThumbSlider(tr3: tr3, self))
                case "twist":   addThumb(ThumbTwist(tr3: tr3, self))
                case "box":     addThumb(ThumbXY(tr3: tr3, self))
                default: print("*** \(tr3.scriptLineage(3)) has unknown type: \(type)")
            }
        }
        else { print("*** \(tr3.scriptLineage(3)) missing `type`") }
    }
    func updateBase(for tr3:Tr3) {

        if let frame_ = tr3.findPath("frame")?.CGRectVal() {
            if let title_ = tr3.findPath("title")?.StringVal() {

                frame = frame_
                updateTitle(title_)
            }
            else { print("*** \(tr3.scriptLineage(3)) is missing title.") }
        }
        else { print("*** \(tr3.scriptLineage(3)) is missing frame")  }
    }
    func addDismissButton() {

        dismiss = UIButton(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        if let d = dismiss {
            d.setImage(UIImage(named: "icon.thumb.X"), for: .normal)
            d.addTarget(self, action: #selector(hidePanel), for: .touchUpInside)
            d.showsTouchWhenHighlighted = false
            d.alpha = 0.5
            addSubview(d)
        }
    }
    func updateTitle(_ title_: String?) {

        title = UILabel()
        if let t = title {
            t.text = title_
            t.numberOfLines = 1
            t.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: 40)
            t.font = UIFont(name: "HelveticaNeue-Light", size: 17)
            t.textColor = UIColor.white
            t.shadowOffset = CGSize(width: 0, height: 0.5)
            t.shadowColor = UIColor.darkGray
            t.textAlignment = .center
            t.lineBreakMode = .byTruncatingTail
            t.text = title_
            t.alpha = 0.62
            addSubview(t)
        }
    }

    func showPanel(after delay: CFTimeInterval) {
        
        func maybeShowPanel(_ ignore:Timer) {

            let isMyDot = thumbDot.isDotNow()
             ThumbPrint("Panel_maybeShowPanel: \(title?.text ?? "??") isMyDot: \(isMyDot)")


            // user selected something else after this timer was started?
            if !isMyDot {
                hidePanel("changed dotNow")
                return
            }
            switch state {
            case .hidden: showPanel("showPanel(after:\(delay)")
            default: break
            }
        }
        let _ = Timer.scheduledTimer(withTimeInterval: delay, repeats: false, block: maybeShowPanel)
    }

    @objc func showPanel(_ from:String) {
        
        switch state {
        case .animShow, .showing: return
        case .animHide: hideLoop?.invalidate()
        case .hidden:

            removeFromSuperview()
            SkyView.insertSubview(self, at:0)
            center = thumbDot.center
            alpha = 0
            scale = 0.01
            isHidden = false
            transform = OrienteDevice.shared.transform
                .rotated(by: OrienteDevice.shared.radians)
                .scaledBy(x: scale, y: scale)

        }
        state = .animShow
        
        func looping(_ factor:CGFloat) {
            
            center = center + (centerForOrientation() - center) * factor
            scale = scale + (1.00 - scale) * factor
            alpha = alpha + (1.00 - alpha) * factor
            blurView?.alpha = alpha
            transform = OrienteDevice.shared.transform
                .rotated(by: OrienteDevice.shared.radians)
                .scaledBy(x: scale, y: scale)
        }

        func completion() {
            scale = 1
            alpha = 1
            transform = OrienteDevice.shared.transform
                .rotated(by: OrienteDevice.shared.radians)
                .scaledBy(x: scale, y: scale)
            state = .showing
        }
        ThumbPrint("Dot_showPanel:\(thumbDot.name)")
        showLoop = Looper(AnimDuration, LoopTime, looping, completion)
    }

    @objc func hidePanel(_ from:String) {
        
        switch state {
        case .animHide, .hidden: return
        case .animShow: showLoop?.invalidate()
        case .showing:  break
        }
        state = .animHide
        
        func looping(_ factor:CGFloat) {
            center = center + (thumbDot.center - center) * factor
            scale = scale + (0.01 - scale) * factor
            alpha = alpha + (0.00 - alpha) * factor
            blurView?.alpha = alpha
            transform = OrienteDevice.shared.transform
                .rotated(by: OrienteDevice.shared.radians)
                .scaledBy(x: scale, y: scale)
        }
        func completion() {
            isHidden = true
            state = .hidden
        }
        ThumbPrint("Dot_hidePanel:\(thumbDot.name) from:\(from)")
        hideLoop = Looper(AnimDuration, LoopTime, looping, completion)
    }

    func fadeBezel(_ alpha:CGFloat) {
        UIView.animate(withDuration: 1.0) {
            self.blurView?.alpha  = alpha
        }
    }

    func thumbTouched(_ phase: UITouch.Phase) {
        // ThumbPrint("panel:\(title?.text ?? "??") phase:\(phase.rawValue) autoHide: \(autoHide)")
        switch phase {
        case .began, .moved, .stationary:

            fadeBezel(0.2)

        case .ended, .cancelled:

            fadeBezel(0.6)

        default: break
        }

    }
    func dotTap1() {
        ThumbPrint("Panel_dotTap1: \(title?.text ?? "??")")
        showPanel(after:0.50)
        for control in controls {
            if let panelOn = control as? ThumbPanelOn {
                panelOn.tap1()
                return
            }
        }
    }
    func dotTap2() {
        ThumbPrint("Panel_dotTap2  \(title?.text ?? "??")")
        
    }
    
    //--------------------------------------------------------------------------

    func centerForOrientation() -> CGPoint {
        
        if thumbDot == nil { return .zero } // is initializing
        
        let panelW = frame.size.width
        let panelH = frame.size.height
        let dotX = thumbDot.frame.origin.x
        let dotY = thumbDot.frame.origin.y
        let dotCX = thumbDot.center.x
        let dotCY = thumbDot.center.y
        let dotW = thumbDot.frame.size.width
        let dotH = thumbDot.frame.size.height
        var rect = CGRect.zero

        func setRect(_ x:CGFloat,_ y: CGFloat) {
            rect = CGRect(x:x,y:y,width: panelW, height: panelH)
            rect = UIScreen.main.bounds.between(rect)
        }
        switch OrienteDevice.shared.attachFrom {
            
        case .left:  setRect(dotX + dotW, dotCY - panelH/2)
        case .right: setRect(dotX - panelW, dotCY - panelH/2)
        case .above: setRect(dotCX - panelW/2, dotY - panelH)
        case .below: setRect(dotCX - panelW/2, dotY - panelH)
        }
        return rect.center
    }

    override func reorientCenter() {
        
        if state != .showing { return }
        
        func setTransformCenter() {
            transform = OrienteDevice.shared.transform
                .rotated(by: OrienteDevice.shared.radians)
                .scaledBy(x: scale, y: scale)
            center = centerForOrientation()
        }
        UIView.animate(withDuration: AnimDuration, delay: 0, options: AnimUser, animations: setTransformCenter)
    }
    
    //TODO: is this needed?
    // block touches from getting passed onto superview
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) { thumbTouched(.began) }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) { thumbTouched(.moved) }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { thumbTouched(.ended) }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { thumbTouched(.cancelled) }
    
}
