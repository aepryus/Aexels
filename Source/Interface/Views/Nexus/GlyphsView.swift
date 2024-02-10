//
//  GlyphsView.swift
//  Aexels
//
//  Created by Joe Charlier on 2/10/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

import Acheron
import UIKit

class GlyphsView: AEView {
    var glyphs: [GlyphView] = []
    
    func add(glyph: GlyphView) {
        glyphs.append(glyph)
        addSubview(glyph)
    }
    
    
}

class GlyphView: AEView {
    let radius: CGFloat
    var linkedTo: [GlyphView] = []
    
    init(radius: CGFloat) {
        self.radius = radius
        super.init()
//        layer.shadowColor = UIColor.black.cgColor
//        layer.shadowOffset = .zero
//        layer.shadowRadius = 0.5
//        layer.shadowOpacity = 1
    }
    
    var color: UIColor { UIColor.black.tint(0.5) }
    
    func link(to other: GlyphView) {
        linkedTo.append(other)
        other.linkedTo.append(self)
    }
    private func spoke(to other: GlyphView) -> CGFloat { .pi - atan2(other.frame.origin.x-frame.origin.x, other.frame.origin.y-frame.origin.y) }
    
    var spokes: [CGFloat] {
        let spokes: [CGFloat] = linkedTo.map { spoke(to: $0) }
        return spokes.sorted()
    }
}

class ArticleGlyph: GlyphView {
    let name: String
    let label: UILabel = UILabel()
    
    init(name: String, radius: CGFloat) {
        self.name = name
        super.init(radius: radius)
        backgroundColor = .clear
        
        layer.borderColor = color.cgColor
        layer.borderWidth = 2
        
        label.pen = Pen(font: .ax(size: 14*s), color: color, alignment: .center)
        label.text = name
        label.numberOfLines = -1
        label.layer.borderColor = color.cgColor
        label.layer.borderWidth = 5
        addSubview(label)
    }
    
// UIView ==========================================================================================
    override func layoutSubviews() {
        label.center(width: width-10*s, height: height-10*s)
        layer.cornerRadius = width/2
        label.layer.cornerRadius = label.width/2
    }
}

class ExplorerGlyph: GlyphView {
    let image: UIImage
    let imageView: UIImageView = UIImageView()
    
    init(image: UIImage, radius: CGFloat) {
        self.image = image
        super.init(radius: radius)
        backgroundColor = .clear
        
        layer.borderColor = color.cgColor
        layer.borderWidth = 3
        
        imageView.contentMode = .scaleAspectFill
        imageView.layer.borderColor = color.cgColor
        imageView.layer.borderWidth = 3
        imageView.image = image
        imageView.layer.masksToBounds = true
        addSubview(imageView)
    }

// UIView ==========================================================================================
    override func layoutSubviews() {
        imageView.center(width: width-15*s, height: height-15*s)
        layer.cornerRadius = width/2
        imageView.layer.cornerRadius = imageView.width/2
    }
}

class AsideGlyph: GlyphView {
    let name: String
    let label: UILabel = UILabel()
    
    init(name: String, radius: CGFloat) {
        self.name = name
        super.init(radius: radius)
        backgroundColor = .clear
        
        layer.borderColor = color.cgColor
        layer.borderWidth = 3
        
        label.pen = Pen(font: .ax(size: 9*s), color: color, alignment: .center)
        label.text = name
        label.numberOfLines = -1
        addSubview(label)
    }
    
// UIView ==========================================================================================
    override func layoutSubviews() {
        label.center(width: width-15*s, height: height-15*s)
        layer.cornerRadius = width/2
    }
}
