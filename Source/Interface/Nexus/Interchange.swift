//
//  Interchange.swift
//  Aexels
//
//  Created by Joe Charlier on 2/14/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

import Acheron
import UIKit

/* The article navigation elements.
    Interchange - the related links control situated to the right of the article containing all the [Capsule]s and [Exploret]s
    Capsule - related links base class
    AnchorCapsule - the link back to the crop circles
    ArticleCapsule - each of the related articles
    Exploret - the articles related explorers
 */

class Capsule: AEControl {
    var lhs: String { didSet { render() } }
    var rhs: String { didSet { render() } }
    
    static let pen: Pen = Pen(font: .optima(size: 12*Screen.s), color: .black.tint(0.4))
    
    init(_ lhs: String, _ rhs: String) {
        self.lhs = lhs
        self.rhs = rhs
        super.init()
        backgroundColor = .clear
        render()
    }
    
    func render() {
        let lw: CGFloat = lhs.size(pen: Capsule.pen).width+6*s
        let rw: CGFloat = rhs.size(pen: Capsule.pen).width+10*s
        frame = CGRect(origin: frame.origin, size: CGSize(width: lw+rw+11*s, height: 20*s))
        setNeedsDisplay()
    }
    
// UIView ==========================================================================================
    override func draw(_ rect: CGRect) {
        let p: CGFloat = 2*s
        let radius: CGFloat = (height - 2*p)/2
        let lw: CGFloat = lhs.size(pen: Capsule.pen).width+6*s
        let rw: CGFloat = rhs.size(pen: Capsule.pen).width+10*s

        let x1: CGFloat = p
        let x2: CGFloat = x1+lw
        let x3: CGFloat = x2+7*s
        let x4: CGFloat = x3+rw
        let y1: CGFloat = p
        let y3: CGFloat = height - p
        let y2: CGFloat = (y1+y3)/2
        
        let color: CGColor = UIColor.black.tint(0.4).cgColor
        let c = UIGraphicsGetCurrentContext()!
        c.move(to: CGPoint(x: x3, y: y1))
        c.addLine(to: CGPoint(x: x2, y: y3))
        c.addArc(tangent1End: CGPoint(x: x1, y: y3), tangent2End: CGPoint(x: x1, y: y2), radius: radius)
        c.addArc(tangent1End: CGPoint(x: x1, y: y1), tangent2End: CGPoint(x: x3, y: y1), radius: radius)
        c.addLine(to: CGPoint(x: x3, y: y1))
        c.setLineWidth(2*s)
        c.setStrokeColor(color)
        c.setFillColor(color)
        c.drawPath(using: .eoFillStroke)

        c.move(to: CGPoint(x: x3, y: y1))
        c.addArc(tangent1End: CGPoint(x: x4, y: y1), tangent2End: CGPoint(x: x4, y: y2), radius: radius)
        c.addArc(tangent1End: CGPoint(x: x4, y: y3), tangent2End: CGPoint(x: x2, y: y3), radius: radius)
        c.addLine(to: CGPoint(x: x2, y: y3))
        c.strokePath()

        lhs.draw(at: CGPoint(x: x1+6*s, y: (y3-y1)/2-5.5*s), pen: Capsule.pen.clone(color: .white.shade(0.1)))
        rhs.draw(at: CGPoint(x: x3+3*s, y: (y3-y1)/2-5.5*s), pen: Capsule.pen)
    }
}

class AnchorCapsule: Capsule {
    init() {
        super.init("home", "Circles")
        addAction { Aexels.nexusExplorer.showGlyphs() }
    }
}

class ArticleCapsule: Capsule {
    var article: Article { didSet { rhs = article.nameWithoutNL } }
    
    init(_ lhs: String, article: Article) {
        self.article = article
        super.init(lhs, article.nameWithoutNL)
        addAction { Aexels.nexusExplorer.show(article: self.article) }
    }
}
