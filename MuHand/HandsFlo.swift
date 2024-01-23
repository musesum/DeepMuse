// created by musesum on 1/19/24

import MuFlo
import ARKit



public class HandsFlo {

    private var root    : Flo?
    private var archive : FloArchive?

    var leftHand = HandFlo()
    var rightHand = HandFlo()

    public func parseRoot(_ root: Flo,
                          _ archive: FloArchive) {

        self.root = root
        self.archive = archive
        let hand = root.bind("hand")

        leftHand.parseHand( hand.bind("left"))
        rightHand.parseHand(hand.bind("right"))
        //??? print(hand.scriptFull)
    }
    public func setHand(_ chirality: HandAnchor.Chirality, joints: [HandJoints], on: Bool) {
        switch chirality {
        case .left: leftHand.setJoints(joints, on)
        case .right: rightHand.setJoints(joints, on)
        }
    }
    public func updateHand(_ chirality: HandAnchor.Chirality, 
                           _ anchor: HandAnchor) {
        switch chirality {
        case .left: leftHand.updateAnchor(anchor)
        case .right: rightHand.updateAnchor(anchor)
        }

    }
}


// (2 hands * 4 fingers * 3 joints) => 24 control points =>
// 24 * (tap, tap2, hold, swipe) => 96 discreet gestures
// (24 xyz controllers + 8 slidders) => 80 conintuous paramaters
//
// so 96 modes * 80 continuos parameters =>
//     3840 modal continuous parameters with one hand
//     7680 modal continuos parameters with boths hands
//
// Use other hand to interogate by touching joint
// other hand dit-dit-dit-dah (V) to bind to menu leaf
// ASL Trainable
