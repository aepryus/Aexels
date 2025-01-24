//
//  ImageButton.swift
//  Aexels
//
//  Created by Joe Charlier on 1/8/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

import UIKit

class ImageButton: AXButton {
    let image: UIImage
    let imageView: UIImageView = UIImageView()

    init(named: String) {
        image = UIImage(named: named)!
        
        super.init()
        
        imageView.contentMode = .scaleAspectFill
        imageView.image = image.withTintColor(UIColor.black.tint(0.4))
        imageView.layer.masksToBounds = true
        addSubview(imageView)
    }
    
    func spin() {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveLinear) {
            self.imageView.transform = self.imageView.transform.rotated(by: .pi)
        } completion: { _ in
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveLinear) {
                self.imageView.transform = self.imageView.transform.rotated(by: .pi)
            } completion: { _ in
                self.imageView.transform = .identity
            }
        }
    }
    
// Event ===========================================================================================
    func onHighlight() {
        imageView.image = image.withTintColor(UIColor.black.tint(0.7))
    }
    func onUnHighlight() {
        imageView.image = image.withTintColor(UIColor.black.tint(0.4))
    }
    
// UIView ==========================================================================================
    override func layoutSubviews() {
        imageView.frame = bounds
    }
}
