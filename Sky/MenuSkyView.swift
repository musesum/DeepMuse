//  Created by warren on 12/1/22.

import SwiftUI
import MuMenu

struct MenuSkyView: View {

    var skyVms = MenuSkyVms.shared.skyVms
    var touchVms: [MuTouchVm] { skyVms.map { $0.rootVm.touchVm } }

    var body: some View {

        ZStack(alignment: .bottomLeading) {

            TouchViewRepresentable(touchVms)
            ForEach(skyVms, id:  \.self) { skyVm in
                MenuTouchView(menuVm: skyVm)
            }
        }
        .statusBar(hidden: true)
    }
}
