//  Created by warren on 12/11/22.

import SwiftUI
import MuMenu

struct TouchViewRepresentable: UIViewRepresentable {

    typealias Context = UIViewRepresentableContext<TouchViewRepresentable>
    var touchVms: [MuTouchVm]
    var touchV = TouchV.shared

    init(_ touchVms: [MuTouchVm]) {
        self.touchVms = touchVms
        for touchVm in touchVms {
            CornerTouchVm[touchVm.corner.rawValue] = touchVm
        }
    }
    public func makeUIView(context: Context) -> TouchV {
        return touchV
    }
    public func updateUIView(_ uiView: TouchV, context: Context) {
        //print("updateUIView", terminator: " ")
    }
}
