//
//  GlyphsView.swift
//  Aexels
//
//  Created by Joe Charlier on 2/10/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

import Acheron
import OoviumEngine
import OoviumKit
import UIKit

class GlyphsBorderView: AEView {
    let glyphsView: GlyphsView
    
    var dP: CGPoint = .zero
    
    init(glyphView: GlyphsView) {
        self.glyphsView = glyphView
        super.init()
        backgroundColor = .clear
    }
    
// AEView ==========================================================================================
    override func draw(_ rect: CGRect) {
        guard let first: GlyphView = glyphsView.anchor ?? glyphsView.glyphs.first else { return }
        
        let ss: CGFloat = glyphsView.scale
        let s: CGFloat = super.s * ss
        
        let moat: CGFloat = 8*s
        let a: CGFloat = 5*s
        var point: GlyphView = first
        var angle: CGFloat = -0.2
        var comingFrom: GlyphView? = nil
        var movingTo: GlyphView! = nil
        
        let path: CGMutablePath = CGMutablePath()
        path.move(to: point.center + (point.radius*ss/2+moat)*CGPoint(x: sin(angle), y: -cos(angle)))

        while true {
            if point === first && comingFrom == nil {
                movingTo = point.sortedLinkedTo[0]
            } else if point === first && comingFrom == point.sortedLinkedTo.last! {
                let angleTo: CGFloat = 2 * .pi
                let radius: CGFloat = point.radius*ss/2+moat
                let dq: CGFloat = asin(a/radius)
                path.addArc(center: point.center, radius: radius, startAngle: angle + 3 * .pi/2 + dq, endAngle: angleTo + 3 * .pi/2 - dq, clockwise: false)
                path.closeSubpath()
                break
            } else {
                movingTo = point.linkAfter(comingFrom!)
            }
            let angleTo: CGFloat = point.spoke(to: movingTo)
            let radius: CGFloat = point.radius*ss/2+moat
            let dq: CGFloat = asin(a/radius)
            path.addArc(center: point.center, radius: radius, startAngle: angle + 3 * .pi/2 + dq, endAngle: angleTo + 3 * .pi/2 - dq, clockwise: false)
            let angleBack: CGFloat = movingTo.spoke(to: point)
            comingFrom = point
            angle = angleBack
            point = movingTo
        }

        let c = UIGraphicsGetCurrentContext()!
        c.addPath(path)
        c.setLineWidth(2*ss)
        c.setStrokeColor(Screen.iPhone ? UIColor.white.cgColor : UIColor.black.tint(0.5).cgColor)
        c.strokePath()
    }
}

// The main crop circle control of the nexus explorer.
class GlyphsView: AEView {
    var glyphs: [GlyphView] = [] {
        didSet {
            oldValue.forEach { $0.removeFromSuperview() }
            glyphLookup = [:]
            glyphs.forEach {
                $0.glyphsView = self
                addSubview($0)
                glyphLookup[$0.key] = $0
            }
            borderView.setNeedsDisplay()
        }
    }
    var glyphLookup: [String:GlyphView] = [:]
    var anchor: GlyphView? = nil
    var focus: GlyphView? = nil {
        didSet {
            oldValue?.setNeedsLayout()
            focus?.setNeedsLayout()
            
            if let focus: ArticleGlyph = focus as? ArticleGlyph {
                anchor = focus
            } else if let focus: AsideGlyph = focus as? AsideGlyph, let parent: Article = focus.article.parent {
                anchor = glyphLookup["art::\(parent.key)"]
            } else { anchor = nil }
            
            if let anchor { glyphs.forEach { $0.turnedOn = $0 === anchor || anchor.isLinked(to: $0) } }
            else { glyphs.forEach { $0.turnedOn = true } }
            var minX: CGFloat! = nil
            var minY: CGFloat! = nil
            glyphs.forEach({
                $0.isHidden = !$0.turnedOn
                if $0.turnedOn {
                    if minX == nil || minX > $0.x { minX = $0.x }
                    if minY == nil || minY > $0.y { minY = $0.y }
                }
            })
            let p: CGFloat = 10*s
            glyphs.forEach({
                $0.frame = CGRect(x: $0.x*scale - minX*scale + p, y: $0.y*scale - minY*scale + p, width: $0.radius*scale, height: $0.radius*scale)
            })
            borderView.setNeedsDisplay()
        }
    }
    var fingerPrint: GlyphView? = nil {
        didSet { glyphs.forEach({ $0.setNeedsLayout() }) }
    }
    
    var borderView: GlyphsBorderView!
    
    var scale: CGFloat = 1
    var onTapGlyph: ((GlyphView)->())? = nil
    
    override init() {
        super.init()
//        backgroundColor = .black.alpha(0.1)
        borderView = GlyphsBorderView(glyphView: self)
        addSubview(borderView)
    }
    
    func setFocus(key: String) {
        focus = glyphLookup[key]
    }
    
// UIView ==========================================================================================
    override func layoutSubviews() {
        borderView.frame = bounds
    }
}

class GlyphView: AEView {
    let x: CGFloat
    let y: CGFloat
    let radius: CGFloat
    var linkedTo: [GlyphView] = []
    var turnedOn: Bool = true
    
    unowned var glyphsView: GlyphsView!
    
    init(radius: CGFloat, x: CGFloat, y: CGFloat) {
        self.x = x
        self.y = y
        self.radius = radius
        super.init()
        frame = CGRect(x: x, y: y, width: radius, height: radius)
        backgroundColor = .clear
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tap)))
    }
    
    var key: String { "" }
    var color: UIColor { Screen.iPhone ? .white : .black.tint(0.5) }

    func link(to other: GlyphView) {
        linkedTo.append(other)
        other.linkedTo.append(self)
    }
    func isLinked(to other: GlyphView) -> Bool { linkedTo.contains(other) }
    func spoke(to other: GlyphView) -> CGFloat {
        let result: CGFloat = .pi/2 - atan2(-(other.center.y-center.y), other.center.x-center.x) + 2 * .pi
        return result.truncatingRemainder(dividingBy: 2 * .pi)
    }
    
    static func toClock(_ angle: CGFloat) -> CGFloat { .pi/2 - angle }
    static func fromClock(_ angle: CGFloat) -> CGFloat { -(angle - .pi/2) }
    
    var sortedLinkedTo: [GlyphView] {
        linkedTo.filter({ $0.turnedOn }).sorted(by: { spoke(to: $0) < spoke(to: $1) })
    }
    
    var isCurrentFocus: Bool { glyphsView.focus === self }
    var isCurrentFingerPrint: Bool { glyphsView.fingerPrint === self }

    func linkAfter(_ glyphView: GlyphView) -> GlyphView {
        for i in 0..<sortedLinkedTo.count {
            guard sortedLinkedTo[i] === glyphView else { continue }
            if i == sortedLinkedTo.count - 1 { return sortedLinkedTo[0] }
            else { return sortedLinkedTo[i+1] }
        }
        fatalError()
    }
    
    @objc func tap() {
        glyphsView?.onTapGlyph?(self)
    }
    
    func execute() {}
    
// Events ==========================================================================================
    @objc func onTap() {}
}

class ArticleGlyph: GlyphView {
    let article: Article
    let halo: AEView = AEView()
    let label: UILabel = UILabel()
    var contract: Bool = false
    
    init(article: Article, radius: CGFloat, x: CGFloat, y: CGFloat) {
        self.article = article
        super.init(radius: radius, x: x, y: y)
        
        layer.borderColor = color.cgColor
        
        halo.backgroundColor = .clear
        addSubview(halo)
        
        label.text = article.name
        label.numberOfLines = -1
        label.layer.borderColor = color.cgColor
        addSubview(label)
    }
    
// GlyphView =======================================================================================
    override var key: String { "art::\(article.key)" }

    override func execute() {
        if Screen.iPhone { glyphsView.fingerPrint = self }
        Aexels.nexusExplorer.show(article: article)
    }
    
// UIView ==========================================================================================
    override func layoutSubviews() {
        let s: CGFloat = super.s * glyphsView.scale

        layer.borderWidth = 2 * glyphsView.scale

        label.layer.borderWidth = 5*s

        label.center(width: width-10*s, height: height-10*s)
        layer.cornerRadius = width/2
        label.layer.cornerRadius = label.width/2
        
        halo.center(width: label.width-20*s, height: label.height-20*s)
        halo.layer.cornerRadius = halo.width/2

        let pen: Pen = Pen(font: Screen.iPhone ? .avenir(size: 18*s) : .ax(size: 14*s), color: color, alignment: .center)
        if isCurrentFocus || isCurrentFingerPrint {
            halo.layer.backgroundColor = Text.Color.lavender.uiColor.cgColor
            label.pen = pen.clone(color: .white)
            if contract { label.attributedText = label.text?.attributed(pen: pen.clone(color: .white, kern: Screen.iPhone ? -1 : -3)) }
        } else {
            halo.layer.backgroundColor = UIColor.clear.cgColor
            label.pen = pen
            if contract { label.attributedText = label.text?.attributed(pen: pen.clone(kern: Screen.iPhone ? -1 : -3)) }
        }
    }
}

class ExplorerGlyph: GlyphView {
    let explorer: Explorer
    let imageView: UIImageView = UIImageView()
    
    init(explorer: Explorer, radius: CGFloat, x: CGFloat, y: CGFloat) {
        self.explorer = explorer
        super.init(radius: radius, x: x, y: y)
        
        layer.borderColor = color.cgColor
        
        imageView.contentMode = .scaleAspectFill
        imageView.layer.borderColor = color.cgColor
        imageView.image = explorer.icon
        imageView.layer.masksToBounds = true
        addSubview(imageView)
    }

// GlyphView =======================================================================================
    override var key: String { "exp::\(explorer.key)" }
        
    override func execute() {
        Aexels.explorerViewController.explorer = explorer
    }

// UIView ==========================================================================================
    override func layoutSubviews() {
        let ss: CGFloat = glyphsView.scale
        let s: CGFloat = super.s * ss
        
        if Screen.iPhone {
            imageView.layer.borderWidth = 3*ss
            imageView.center(width: width, height: height)
            imageView.layer.cornerRadius = imageView.width/2
        } else {
            layer.borderWidth = 3*ss
            imageView.layer.borderWidth = 3*ss
            imageView.center(width: width-15*s, height: height-15*s)
            layer.cornerRadius = width/2
            imageView.layer.cornerRadius = imageView.width/2
        }
    }
}

class AsideGlyph: GlyphView {
    let article: Article
    let label: UILabel = UILabel()
    
    init(article: Article, radius: CGFloat, x: CGFloat, y: CGFloat) {
        self.article = article
        super.init(radius: radius, x: x, y: y)

        layer.borderColor = color.cgColor
        
        label.text = article.name
        label.numberOfLines = -1
        addSubview(label)
    }
    
// GlyphView =======================================================================================
    override var key: String { "asd::\(article.key)" }
            
    override func execute() {
        if Screen.iPhone { glyphsView.fingerPrint = self }
        Aexels.nexusExplorer.show(article: article)
    }

// UIView ==========================================================================================
    override func layoutSubviews() {
        let s: CGFloat = super.s * glyphsView.scale
        
        layer.borderWidth = 3*glyphsView.scale
        label.center(width: width-15*s, height: height-15*s)
        label.layer.cornerRadius = label.width/2
        layer.cornerRadius = width/2
        
        if isCurrentFocus || isCurrentFingerPrint {
            label.layer.backgroundColor = Text.Color.lavender.uiColor.cgColor
            label.pen = Pen(font: Screen.iPhone ? .avenir(size: 11*s) : .ax(size: 9*s), color: .white, alignment: .center)
        } else {
            label.layer.backgroundColor = UIColor.clear.cgColor
            label.pen = Pen(font: Screen.iPhone ? .avenir(size: 11*s) : .ax(size: 9*s), color: color, alignment: .center)
        }
    }
}
