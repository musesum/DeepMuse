//
//  ThumbX.swift
//  
//
//  Created by warren on 9/16/19.
//


import UIKit
import Tr3

class ThumbPanelX: ThumbBase {

    override func updateBase() {
        super.updateBase()
        thumb = UIView(frame: frame)
        let imageView = UIImageView(image:icon)
        imageView.frame.origin = .zero

        if let thumb = thumb {
            imageView.frame.size = thumb.frame.size
            thumb.addSubview(imageView)
            thumb.alpha = 0.25
            panel?.addSubview(thumb)
        }
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        panel?.thumbTouched(.moved)
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        panel?.thumbTouched(.moved)
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        panel?.hidePanel("thumbX")
    }
    override func touchesCancelled(_ touches: Set<UITouch>?, with event: UIEvent?) {
    }
}
