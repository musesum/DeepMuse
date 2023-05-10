//  Created by warren on 12/1/22.

import SwiftUI
import MuMenu

struct MenuView: View {

    var menuVms = MenuVms.shared.menuVms
    var touchVms: [MuTouchVm] { menuVms.map { $0.rootVm.touchVm } }

    var body: some View {

        ZStack(alignment: .bottomLeading) {

            TouchViewRepresentable(touchVms)
            ForEach(menuVms, id:  \.self) { menuVm in
                MenuTouchView(menuVm: menuVm)
            }
        }
        .statusBar(hidden: true)
    }
}
