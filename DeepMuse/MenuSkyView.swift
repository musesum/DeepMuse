//
//  MenuSkyView.swift
//  DeepMuse
//
//  Created by warren on 9/14/23.
//  Copyright © 2023 DeepMuse. All rights reserved.
//

import SwiftUI
import BackgroundTasks
import MuFlo
import MuMenu

struct MenuSkyView: View {

    public static let shared = MenuSkyView()
    var menuView: MenuView!
    var hostingController: HostingController!
    var skyCanvas: SkyCanvas!
    var hostView: UIView!

    public init() {
        skyCanvas = SkyCanvas.shared
        menuView = MenuView(skyCanvas.archive.root˚, skyCanvas.touchView, skyCanvas)
        hostView = UIHostingController(rootView: menuView).view
        hostingController = HostingController(rootView: self)
        NextFrame.shared.addFrameDelegate("SkyCanvas".hash, skyCanvas)
    }

    var body: some View {
        VStack {
            menuView

        }
    }
}

