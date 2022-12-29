//
//  MenuSkyVms.swift
//  MuseSky2
//
//  Created by warren on 12/1/22.
//  Copyright © 2022 Muse. All rights reserved.
//

import MuMenuSky
import MuMenu
import Tr3

struct MenuSkyVms {

    static let shared = MenuSkyVms()

    let rootTr3: Tr3
    let leftVm:  MenuSkyVm
    let rightVm: MenuSkyVm

    init() {
        rootTr3 = SkyTr3.shared.root
        let rootNode = MuTr3Node(rootTr3)
        leftVm  = MenuSkyVm([.lower, .left],  .vertical, rootNode)
        rightVm = MenuSkyVm([.lower, .right], .vertical, rootNode)
    }
}
