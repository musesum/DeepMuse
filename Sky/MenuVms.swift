//  Created by warren on 12/1/22.


import MuMenuSky
import MuMenu
import MuFlo

struct MenuVms {

    static let shared = MenuVms()

    let rootFlo = SkyFlo.shared.root
    var menuVms = [MenuSkyVm]()

    init() {
        let rootNode = MuFloNode(rootFlo)

        menuVms.append(MenuSkyVm(
            [.lower, .left],
            [(rootNode, .vertical),
             (rootNode, .horizontal)]))

        menuVms.append(MenuSkyVm(
            [.lower, .right],
            [(rootNode, .vertical),
             (rootNode, .horizontal)]))

        menuVms.append(MenuSkyVm(
            [.upper, .left],
            [(rootNode, .vertical),
             (rootNode, .horizontal)]))

        menuVms.append(MenuSkyVm(
            [.upper, .right],
            [(rootNode, .vertical),
             (rootNode, .horizontal)]))
    }
}
