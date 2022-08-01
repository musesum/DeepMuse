//
//  MuDrawCircle.swift
//  Tr3Thumb
//
//  Created by warren on 7/17/19.
//  Copyright © 2019 DeepMuse All rights reserved.
//

import UIKit
import QuartzCore

class MuDrawCircle: UIView {
    
    var width = CGFloat(0)
    var color = ColorRGBA()

    override init(frame: CGRect) {

        super.init(frame: frame)
        isOpaque = false
        isUserInteractionEnabled = true
    }

    override func draw(_ rect: CGRect) {

        if let context = UIGraphicsGetCurrentContext() {
        let drawRect = CGRect(x: width, y: width, width: frame.size.width - 2 * width, height: frame.size.height - 2 * width)
        context.setStrokeColor(red: color.red, green: color.green, blue: color.blue, alpha: color.alpha)
        context.setLineWidth(width)
        context.strokeEllipse(in: drawRect)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

