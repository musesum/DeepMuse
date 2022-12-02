//
//  MenuSkyView.swift
//  MuseSky2
//
//  Created by warren on 12/1/22.
//  Copyright © 2022 Muse. All rights reserved.
//

import SwiftUI
import MuMenu

struct MenuSkyView: View {

    var body: some View {

        ZStack(alignment: .bottomLeading) {

            // add touch handler
            TouchViewRepresentable([MenuSkyVms.shared.leftVm.rootVm.touchVm,
                                    MenuSkyVms.shared.rightVm.rootVm.touchVm])
            // Menus via UITouch (not SwiftUI's DragGesture)
            MenuTouchView(menuVm: MenuSkyVms.shared.leftVm)
            MenuTouchView(menuVm: MenuSkyVms.shared.rightVm)
        }
        .statusBar(hidden: true)
    }
}
