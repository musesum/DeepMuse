//
//  File.swift
//  
//
//  Created by warren on 12/29/19.
//

import Foundation
import QuartzCore

extension MetNode {

    public func addBuffer(_ key: String,_ val: Any) {

        if let _ = nameBuffer[key] { return }
        // compute buffer index is in order of declaration in flo script
        let index = nameBufId[key] ?? nameBuffer.count
        nameBuffer[key] = MetBuffer(key, index, val, metItem.device)
    }

    public func updateBuffer(_ named: String, _ val: Any) {

        if let buffer = nameBuffer[named] {
            buffer.newBuf(val)
        }
        else {
            addBuffer(named, val)
        }
    }
}
