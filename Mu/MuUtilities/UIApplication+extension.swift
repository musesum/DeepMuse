//
//  File.swift
//  
//
//  created by musesum on 8/18/22.
//

import UIKit

extension UIApplication {
    public static func uiOrientation() -> UIInterfaceOrientation {
        let orientation = UIApplication
            .shared
            .connectedScenes
            .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
            .first { $0.isKeyWindow }?.windowScene?.interfaceOrientation ?? .portrait
        return orientation
    }
}
