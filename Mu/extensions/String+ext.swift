//
//  String+ext.swift
//  Platonix
//
//  Created by warren on 2/28/23.
//  Copyright © 2023 com.deepmuse. All rights reserved.
//

import Foundation

extension String {
    func pad(_ len: Int) -> String {
        return self.padding(toLength: len, withPad: " ", startingAt: 0)
    }
    static func pointer(_ object: AnyObject?) -> String {
        guard let object = object else { return "nil" }
        let opaque: UnsafeMutableRawPointer = Unmanaged.passUnretained(object).toOpaque()
        return String(describing: opaque)
    }
}