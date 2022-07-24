
import UIKit
import QuartzCore

public enum ShowState {  case hidden, animShow,  showing, animHide }
public let AutoHideDuration = CFTimeInterval(8)
public let AnimDuration = CFTimeInterval(0.5)
public let AnimUser: UIView.AnimationOptions =  [.allowUserInteraction, .beginFromCurrentState]
public let DoubleTapTime = CFTimeInterval(0.5)

