//
//  File.swift
//  
//
//  Created by warren on 9/17/19.
//

import Foundation

class ThumbPanelOn : ThumbSwitch {

    func tap1() {
        updateTr3User(true)
        panel?.thumbTouched(.began)
        userSetCursor(.zero)
    }
    
}
