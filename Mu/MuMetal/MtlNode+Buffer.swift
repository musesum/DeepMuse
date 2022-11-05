//
//  File.swift
//  
//
//  Created by warren on 12/29/19.
//

import Foundation
import QuartzCore

extension MtlNode {

    public func addBuffer(_ key: String,_ val: Any) {

        if let _ = nameBuffer[key] { return }
        // compute buffer index is in order of declaration in tr3 script
        let index = nameIndex[key] ?? nameBuffer.count
        let mtlBuffer = MtlBuffer(key, index, val, device)
        nameBuffer[key] = mtlBuffer
    }

    public func updateBuffer(_ named: String, _ val: Any) {

        if let buffer = nameBuffer[named] {
            buffer.updateBuffer(val)
        }
        else {
            addBuffer(named, val)
        }
    }
}
