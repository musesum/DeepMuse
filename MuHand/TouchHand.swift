// created by musesum on 1/22/24

import Foundation


class TouchHand {

    var hand  : HandAnchor.Chirality
    var phase = UITouch.Phase.ended
    var pos   = SIMD3<Float>.zero
    var time = TimeInterval.zero
    var hash = hand.hashValue

    init( _ hand: HandAnchor.Chirality) {
        self.hand  = hand
    }
    func touching(_ touching: Bool, pos: SIMD3<Float>) {
        switch (phase, touching) {

        case (.ended, true):

            phase = .began
            TouchCanvas.shared.beginTouch

        case (.began, true),
               (.moved, true):
            phase = .moved

        case (.moved, false),
            (.began, false): // tap?
            
            phase = .ended

        default: return //

        }
        TouchHa
    }
}


open class TouchThumbIndex {


    var leftHand: HandFlo
    var rightHand: HandFlo
    var timeLeft = TimeInterval.zero
    var timeRight = TimeInterval.zero
    var touchLeft = TouchHand(.left)
    var touchRight = TouchHand(.right)

    init(_ handsFlo: HandsFlo) {
        self.leftHand = handsFlo.leftHand
        self.rightHand = handsFlo.rightHand
        leftHand.setJoints([.thumbTip, .indexTip], true)
        rightHand.setJoints([.thumbTip, .indexTip], true)
    }

    var updateTouch() {

        if touchLeft.time < leftHand.time {
            touchLeft.time = leftHand.time
            if let thumbTip = leftHand.joints[.thumbTip],
               let indexTip = leftHand.joints[.indexTip] {
                let tipsDistance = distance(thumbTip, indexTip)
                if tipsDistance < 0.04 {
                    touchLeft.touching(true, indexTip)
                }
            }

        }

        if touchRight.time < rightHand.time {
            touchRight.time = rightHand.time
            if let thumbTip = rightHand.joints[.thumbTip],
               let indexTip = rightHand.joints[.indexTip] {
                let tipsDistance = distance(thumbTip, indexTip)
                if tipsDistance < 0.04 {
                    touchRight.touching(true, indexTip)
                }
            }

        }

    }



    let handsUpdate: HandsUpdate
    let leftJoints  = HandJoints(.left , ["thumb.knuc","thumb.tip","index.tip"])
    let rightJoints = HandJoints(.right, ["thumb.knuc","thumb.tip","index.tip"])

    public init(_ handsUpdate: HandsUpdate)  {

        self.handsUpdate = handsUpdate
    }

    func update() -> Bool {

        guard let leftAnchor  = handsUpdate.left  else { return err("handsUpdate.left = nil") }
        guard let rightAnchor = handsUpdate.right else { return err("handsUpdate.right = nil") }
        if !leftJoints.updatePositions(leftAnchor) { return err("leftHand.joints") }
        if !rightJoints.updatePositions(rightAnchor) { return err("rightHand.joints") }
        return true

        func err(_ msg: String) -> Bool { print("HandsThumbIndex::update err: \(msg)"); return false }
    }

}

