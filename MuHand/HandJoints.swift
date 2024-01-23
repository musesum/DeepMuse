// created by musesum on 1/20/24

import ARKit

public enum HandJoints: String {

    case thumbKnuc  = "thumb.knuc"
    case thumbBase  = "thumb.base"
    case thumbNter  = "thumb.nter"
    case thumbTip   = "thumb.tip"

    case indexMeta  = "index.meta"
    case indexKnuc  = "index.knuc"
    case indexBase  = "index.base"
    case indexNter  = "index.nter"
    case indexTip   = "index.tip"

    case middleMeta = "middle.meta"
    case middleKnuc = "middle.knuc"
    case middleBase = "middle.base"
    case middleNter = "middle.nter"
    case middleTip  = "middle.tip"

    case ringMeta   = "ring.meta"
    case ringKnuc   = "ring.knuc"
    case ringBase   = "ring.base"
    case ringNter   = "ring.nter"
    case ringTip    = "ring.tip"

    case littleMeta = "little.meta"
    case littleKnuc = "little.knuc"
    case littleBase = "little.base"
    case littleNter = "little.nter"
    case littleTip  = "little.tip"

    var arJoint: HandSkeleton.JointName? {
        ARHandJoint[self] 
    }
}

let ARHandJoint: [HandJoints: HandSkeleton.JointName] = [

    .thumbKnuc : .thumbKnuckle,
    .thumbBase : .thumbIntermediateBase,
    .thumbNter : .thumbIntermediateTip,
    .thumbTip  : .thumbTip,
    .indexMeta : .indexFingerMetacarpal,
    .indexKnuc : .indexFingerKnuckle,
    .indexBase : .indexFingerIntermediateBase,
    .indexNter : .indexFingerIntermediateTip,
    .indexTip  : .indexFingerTip,
    .middleMeta: .middleFingerMetacarpal,
    .middleKnuc: .middleFingerKnuckle,
    .middleBase: .middleFingerIntermediateBase,
    .middleNter: .middleFingerIntermediateTip,
    .middleTip : .middleFingerTip,
    .ringMeta  : .ringFingerMetacarpal,
    .ringKnuc  : .ringFingerKnuckle,
    .ringBase  : .ringFingerIntermediateBase,
    .ringNter  : .ringFingerIntermediateTip,
    .ringTip   : .ringFingerTip,
    .littleMeta: .littleFingerMetacarpal,
    .littleKnuc: .littleFingerKnuckle,
    .littleBase: .littleFingerIntermediateBase,
    .littleNter: .littleFingerIntermediateTip,
    .littleTip : .littleFingerTip,
]
