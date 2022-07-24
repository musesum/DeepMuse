//
//  ThumbDock+Touch.swift
//  Tr3Thumb
//
//  Created by warren on 8/6/19.
//  Copyright © 2019 Muse. All rights reserved.
//

import UIKit
import QuartzCore

extension ThumbDock {


    /// return ThumbDot which is under touchPoint,
    /// otherwise nil
    func dotUnderPoint(_ touchPoint:CGPoint) -> ThumbDot? {

        if state != .showing { return nil }
        if dots.isEmpty { return nil }

        var nearestX = CGFloat(9999)
        var nearestDot = dots.first!

        for dot in dots {

            let distance = dot.center.distance(touchPoint)

            if nearestX > distance {
                nearestX = distance
                nearestDot = dot
            }
        }
        let dotNowRadius = dotNow?.radius ?? 0
        let nearestDistance = nearestDot.center.distance(touchPoint)

        if  nearestX < dotNowRadius,
            nearestDistance < dotNowRadius {

            return nearestDot
        }
        return nil
    }


    func hoveringOverDot(_ touchPoint:CGPoint) {

        if let nearestDot = dotUnderPoint(touchPoint) {

            hovering = true

            if  dotNow != nearestDot {
                updateDotNow(nearestDot)
            }
            panelTimer?.invalidate()
            dotNow?.panel?.showPanel("Dock_hoveringOverDot.B")
        }
        else if hovering {
            hovering = false
            dotNow?.panel?.hidePanel("Dock_hoveringOverDot.C")
            //resetPanelTimer(after: 2)
        }
    }

    /// Respond to to local UITouches, which start near the cursor.
    func beganTouch(_ touch: UITouch?) {

        beganPoint = touch?.location(in: nil) ?? CGPoint.zero
        moving = false
        hovering = false

        let thisTime = CFAbsoluteTimeGetCurrent()
        let deltaBegan = thisTime - beganTime
        let deltaEnded = thisTime - endedTime
        beganTime = thisTime

        let panelShowing = dotNow?.panel?.state ?? .hidden == .showing
        let dockHidden = state != .showing
        let doubleTap = deltaBegan < 0.5
        let tapHide  = deltaEnded < 0.5 && panelShowing // tap after showing to hide

        let dot = dotUnderPoint(beganPoint)
        if let dot = dot    { dot.tap1() } // tapped on dot
        else if doubleTap   { dotNow?.tap2() }
        else if tapHide     { hideDock(after: 0) }
        else if dockHidden  { growDock() }
    }

    /// Respond to movement after moving 8 or more points from beginning.
    func movedTouch(_ touch: UITouch) {

        let touchPoint = touch.location(in: nil)
        let movedThreshold = touchPoint.distance(beganPoint) > 9

        moving = moving || movedThreshold // minimum threshold for moving

        if moving {

            cursorCenter = CGPoint(x: touchPoint.x,
                                   y: cursor.center.y)
            cursor.center = cursorCenter
            cursor.frame = frame.between(cursor.frame)
            calcDotCenters()
            arrangeDots()
            hoveringOverDot(touchPoint)
        }
    }

    func endedTouch(_ touch: UITouch) {

        moving = false

        var panelShowing = false
        switch dotNow?.panel?.state  {
        case .showing?: panelShowing = true
        default: panelShowing = false
        }
        ThumbPrint("Dock_endedTouch panelShowing: \(panelShowing)")
        if panelShowing { hideDock(after: 1.0) }
        else            { hideDock(after: 2.0) }

    }

    // MARK: - override UITouches

    /// Respond only when gesture starts near cursor
    ///
    /// - note: localGesture will pass touch through to next responder
    /// when the touch begins too far away from cursor ring
    ///
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

        if let t = event?.touches(for: self)?.first {
            
            let touchPoint = t.location(in: nil)
            let distance = touchPoint.distance(cursor.center)

            switch state {
            case .hidden:   localGesture = abs(distance) < 64
            default:        localGesture = true
            }
            ThumbPrint("Dock_TouchesBegan distance: \(distance) \(localGesture)")
            if localGesture { beganTouch(t) }
            else { next?.touchesBegan(touches, with: event) }
        }
    }

    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {

        if localGesture, let t = event?.touches(for: self)?.first { movedTouch(t) }
        else { next?.touchesMoved(touches, with: event) }
    }

    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {

        if localGesture, let t = event?.touches(for: self)?.first { endedTouch(t) }
        else { next?.touchesEnded(touches, with: event) }
    }

    override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {

        if localGesture, let t = event?.touches(for: self)?.first { endedTouch(t) }
        else { next?.touchesCancelled(touches, with: event) }
    }

}
