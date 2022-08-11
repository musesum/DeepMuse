//  Created by warren on 9/9/19.
//  Copyright © 2019 DeepMuse All rights reserved.

import Foundation
import Tr3

class SkyDock {

    private var thumbDock: ThumbDock
    private var tr3Root: Tr3

    init(_ thumbDock: ThumbDock, _ tr3Root : Tr3) {

        self.thumbDock = thumbDock
        self.tr3Root = tr3Root

        if let panel = tr3Root.findPath("panel") {
            for child in panel.children {
                if child.name == "cell" || child.name == "shader" {
                    child.children.forEach { thumbDock.addTr3Child($0) }
                }
                else {
                    thumbDock.addTr3Child(child)
                }
            }
        }
        if let shader = tr3Root.findPath("sky.shader") {
            for child in shader.children {
                SkyMetal.shared.makeShader(for: child)
            }
        }

        // get dock dot order from script
        var reorderNames = [String]()
        var selectName = ""
        var selectIndex = 0
        var currentIndex = 0

        if let skyDock = tr3Root.findPath("sky.dock") {
            for child in skyDock.children {
                reorderNames.append(child.name)
                if child.CGFloatVal() ?? 0 > 0 {
                    selectIndex = currentIndex
                    selectName = child.name
                }
                currentIndex += 1
            }
            thumbDock.reorderDock(reorderNames)
            thumbDock.dotNow = thumbDock.dots[selectIndex]
        }
        else {
            reorderNames = ["fade", "ave", "melt", "tunl", "zha", "slide", "fred", "brush", "color", "scroll", "tile", "speed", "camera", "record"]
            thumbDock.reorderDock(reorderNames)
            thumbDock.dotNow = thumbDock.dots.first
        }

        //dock.printDotNames()
        thumbDock.reorderDock(reorderNames)
        thumbDock.arrangeDots()
        thumbDock.updatePanels()
        thumbDock.splashWithCompletion { }

        let panelName = "panel.cell.\(selectName).controls"
        let controls = tr3Root.findPath(panelName)
        controls?.findPath("ruleOn.value")?.setAny(1, [.activate])
        controls?.findPath("bitplane.value")?.setAny(0.30, [.activate])
    }
}
