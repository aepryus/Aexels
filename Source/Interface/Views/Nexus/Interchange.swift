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

class Exploret: AEControl {
    let imageView: UIImageView = UIImageView()
    
    init(explorer: Explorer) {
        super.init()
        
        imageView.contentMode = .scaleAspectFill
        imageView.layer.borderColor = UIColor.black.tint(0.4).cgColor
        imageView.layer.borderWidth = 3
        imageView.image = explorer.icon
        imageView.layer.masksToBounds = true
        addSubview(imageView)
        addAction { Aexels.explorerViewController.explorer = explorer }
    }

// UIView ==========================================================================================
    override func layoutSubviews() {
        imageView.center(width: width, height: height)
        imageView.layer.cornerRadius = imageView.width/2
    }
}

class Interchange: AEView {
    var article: Article? = nil {
        didSet {
            capsules.forEach { $0.removeFromSuperview() }
            explorets.forEach { $0.removeFromSuperview() }
            capsules = []
            explorets = []
            guard let article else { return }
            capsules.append(AnchorCapsule())
            if let parent: Article = article.parent { capsules.append(ArticleCapsule("parent", article: parent)) }
            if let prev: Article = article.prev { capsules.append(ArticleCapsule("prev", article: prev)) }
            if let next: Article = article.next { capsules.append(ArticleCapsule("next", article: next)) }
            article.children.forEach { capsules.append(ArticleCapsule("child", article: $0)) }
            article.explorers.forEach { explorets.append(Exploret(explorer: $0)) }
            capsules.forEach { addSubview($0) }
            explorets.forEach { addSubview($0) }
        }
    }
    
    var capsules: [Capsule] = []
    var explorets: [Exploret] = []
    
// UIViewController ================================================================================
    override func layoutSubviews() {
        var y: CGFloat = 0
        capsules.forEach {
            $0.topLeft(dy: y)
            y += 23*s
        }
        var x: CGFloat = 0
        y += 3*s
        explorets.forEach {
            $0.topLeft(dx: x, dy: y, width: 35*s, height: 35*s)
            x += 39*s
        }
    }
}
