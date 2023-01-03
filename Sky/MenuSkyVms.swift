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

    let rootTr3 = SkyTr3.shared.root
    var skyVms = [MenuSkyVm]()

    init() {
        let rootNode = MuTr3Node(rootTr3)
        let skyVm = MenuSkyVm([.lower, .left],
                              [(rootNode, .vertical),
                               (rootNode, .horizontal)])
        skyVms.append(skyVm)
    }
}
