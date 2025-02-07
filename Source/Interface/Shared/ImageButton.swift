//
//  ImageButton.swift
//  Aexels
//
//  Created by Joe Charlier on 1/8/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

import OoviumEngine
import UIKit

class ImageButton: AXButton {
    let image: UIImage
    let imageView: UIImageView = UIImageView()
    let overrideColor: UIColor?

    init(named: String, overrideColor: UIColor? = nil) {
        image = UIImage(named: named)!
        self.overrideColor = overrideColor
        
        super.init()
        
        imageView.contentMode = .scaleAspectFill
        imageView.image = image.withTintColor(color)
        imageView.layer.masksToBounds = true
        addSubview(imageView)
    }
    
    var color: UIColor { overrideColor ?? .black.tint(0.4) }
    
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
        imageView.image = image.withTintColor(color)
    }
    
// UIView ==========================================================================================
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted { imageView.image = image.withTintColor(OOColor.lavender.uiColor) }
            else { imageView.image = image.withTintColor(color) }
        }
    }
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return bounds.insetBy(dx: -20, dy: -20).contains(point) ? self : nil
    }
    override func layoutSubviews() {
        imageView.frame = bounds
    }
}
