//
//  MidiLog.swift
//  MuseSky2
//
//  Created by warren on 11/4/22.
//  Copyright © 2022 Muse. All rights reserved.
//

import Foundation

class MidiLog {
    static var lastIcon = ""
    static func nextIcon(_ icon: String)  -> String {
        //?? if icon == lastIcon { return "" }
        lastIcon = icon
        return icon
    }

    static func print(_ icon: String, _ msg: String, terminator: String = " ") {
        Swift.print(icon + msg) //??? , terminator: terminator)
        if !icon.isEmpty {
            lastIcon = icon
        }
    }
}
