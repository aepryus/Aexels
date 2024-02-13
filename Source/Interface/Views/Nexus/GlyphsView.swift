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
    
    override init() {
        super.init()
        backgroundColor = .clear
    }
    
    func add(glyph: GlyphView) {
        glyphs.append(glyph)
        addSubview(glyph)
    }
    
// AEView ==========================================================================================
    override func draw(_ rect: CGRect) {
        guard let first: GlyphView = glyphs.first else { return }

        let moat: CGFloat = 8*s
        let a: CGFloat = 5*s
        var point: GlyphView = first
        var angle: CGFloat = 0
        var comingFrom: GlyphView? = nil
        var movingTo: GlyphView! = nil
        
        let path: CGMutablePath = CGMutablePath()
        path.move(to: point.center + (point.radius/2+moat)*CGPoint(x: sin(angle), y: -cos(angle)))

        while true {
            if point === first && comingFrom == nil {
                movingTo = point.sortedLinkedTo[0]
            } else if point === first && comingFrom == point.sortedLinkedTo.last! {
                let angleTo: CGFloat = 2 * .pi
                let radius: CGFloat = point.radius/2+moat
                let dq: CGFloat = asin(a/radius)
                path.addArc(center: point.center, radius: radius, startAngle: angle + 3 * .pi/2 + dq, endAngle: angleTo + 3 * .pi/2 - dq, clockwise: false)
                path.closeSubpath()
                break
            } else {
                movingTo = point.linkAfter(comingFrom!)
            }
            let angleTo: CGFloat = point.spoke(to: movingTo)
            let radius: CGFloat = point.radius/2+moat
            let dq: CGFloat = asin(a/radius)
            path.addArc(center: point.center, radius: radius, startAngle: angle + 3 * .pi/2 + dq, endAngle: angleTo + 3 * .pi/2 - dq, clockwise: false)
            let angleBack: CGFloat = movingTo.spoke(to: point)
            comingFrom = point
            angle = angleBack
            point = movingTo
        }

        let c = UIGraphicsGetCurrentContext()!
        c.addPath(path)
        c.setLineWidth(2)
        c.setStrokeColor(UIColor.black.tint(0.5).cgColor)
        c.strokePath()
    }
}

class GlyphView: AEView {
    let radius: CGFloat
    var linkedTo: [GlyphView] = []
    
    init(radius: CGFloat, x: CGFloat, y: CGFloat) {
        self.radius = radius
        super.init()
        frame = CGRect(x: x, y: y, width: radius, height: radius)
        backgroundColor = .clear
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap)))
    }
    
    var color: UIColor { UIColor.black.tint(0.5) }

    func link(to other: GlyphView) {
        linkedTo.append(other)
        other.linkedTo.append(self)
    }
    func spoke(to other: GlyphView) -> CGFloat { .pi/2 - atan2(-(other.center.y-center.y), other.center.x-center.x) }

    static func toClock(_ angle: CGFloat) -> CGFloat { .pi/2 - angle }
    static func fromClock(_ angle: CGFloat) -> CGFloat { -(angle - .pi/2) }
    
    lazy var sortedLinkedTo: [GlyphView] = {
        linkedTo.sorted(by: { spoke(to: $0) < spoke(to: $1) })
    }()
    
    func linkAfter(_ glyphView: GlyphView) -> GlyphView {
        for i in 0..<sortedLinkedTo.count {
            guard sortedLinkedTo[i] === glyphView else { continue }
            if i == sortedLinkedTo.count - 1 { return sortedLinkedTo[0] }
            else { return sortedLinkedTo[i+1] }
        }
        fatalError()
    }
    
// Events ==========================================================================================
    @objc func onTap() {}
}

class ArticleGlyph: GlyphView {
    let article: Article
    let label: UILabel = UILabel()
    
    init(article: Article, radius: CGFloat, x: CGFloat, y: CGFloat) {
        self.article = article
        super.init(radius: radius, x: x, y: y)
        
        layer.borderColor = color.cgColor
        layer.borderWidth = 2
        
        label.pen = Pen(font: .ax(size: 14*s), color: color, alignment: .center)
        label.text = article.name
        label.numberOfLines = -1
        label.layer.borderColor = color.cgColor
        label.layer.borderWidth = 5
        addSubview(label)
    }
    
// Events ==========================================================================================
    override func onTap() {
        Aexels.nexusExplorer.show(article: article)
    }
    
// UIView ==========================================================================================
    override func layoutSubviews() {
        label.center(width: width-10*s, height: height-10*s)
        layer.cornerRadius = width/2
        label.layer.cornerRadius = label.width/2
    }
}

class ExplorerGlyph: GlyphView {
    let explorer: Explorer
    let imageView: UIImageView = UIImageView()
    
    init(explorer: Explorer, radius: CGFloat, x: CGFloat, y: CGFloat) {
        self.explorer = explorer
        super.init(radius: radius, x: x, y: y)
        
        layer.borderColor = color.cgColor
        layer.borderWidth = 3
        
        imageView.contentMode = .scaleAspectFill
        imageView.layer.borderColor = color.cgColor
        imageView.layer.borderWidth = 3
        imageView.image = explorer.icon
        imageView.layer.masksToBounds = true
        addSubview(imageView)
    }

// Events ==========================================================================================
    override func onTap() {
        Aexels.explorerViewController.explorer = explorer
    }
        
// UIView ==========================================================================================
    override func layoutSubviews() {
        imageView.center(width: width-15*s, height: height-15*s)
        layer.cornerRadius = width/2
        imageView.layer.cornerRadius = imageView.width/2
    }
}

class AsideGlyph: GlyphView {
    let article: Article
    let label: UILabel = UILabel()
    
    init(article: Article, radius: CGFloat, x: CGFloat, y: CGFloat) {
        self.article = article
        super.init(radius: radius, x: x, y: y)

        layer.borderColor = color.cgColor
        layer.borderWidth = 3
        
        label.pen = Pen(font: .ax(size: 9*s), color: color, alignment: .center)
        label.text = article.name
        label.numberOfLines = -1
        addSubview(label)
    }
    
// Events ==========================================================================================
    override func onTap() {
        Aexels.nexusExplorer.show(article: article)
    }
        
// UIView ==========================================================================================
    override func layoutSubviews() {
        label.center(width: width-15*s, height: height-15*s)
        layer.cornerRadius = width/2
    }
}
