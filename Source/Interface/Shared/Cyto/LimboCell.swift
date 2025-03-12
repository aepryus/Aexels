//
//  LimboCell.swift
//  Aexels
//
//  Created by Joe Charlier on 2/4/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

import Acheron
import UIKit

class LimboCell: Cyto.Cell {
    enum Cutout: CaseIterable, Equatable { case upperLeft, upperRight, lowerLeft, lowerRight }
    class Path {
        var strokePath: CGPath!
        var shadowPath: CGPath!
        var maskPath: CGPath!
    }
    
    let path: Path = Path()
    var content: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
            guard let content else { return }
            addSubview(content)
            layoutContent()
        }
    }
    var contentSize: CGSize? {
        didSet { layoutContent() }
    }
    
    let cutouts: [Cutout]
    
    let p: CGFloat
    
    init(content: UIView? = nil, size: CGSize? = nil, c: Int = 0, r: Int = 0, w: Int = 1, h: Int = 1, p: CGFloat = 15*Screen.s, cutouts: [Cutout] = []) {
        self.contentSize = size
        self.p = p
        self.cutouts = cutouts
        
        super.init(c: c, r: r, w: w, h: h)

        backgroundColor = .clear
        
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize.zero
        layer.shadowRadius = 3*Screen.s
        layer.shadowOpacity = 0.6
        
        defer {
            self.content = content
        }
    }

    func layoutContent() {
        guard let content else { return }
        if let contentSize { content.center(size: contentSize) }
        else { content.center(size: CGSize(width: width-2*p, height: height-2*p)) }
    }
    
    private func buildPath(p: CGFloat) -> CGPath {
        let path = CGMutablePath()
        
        let x1 = p
        let x3 = width - p
        let x2 = (x1 + x3) / 2
        let y1 = p
        let y3 = height - p
        let y2 = (y1 + y3) / 2
        let r: CGFloat = 10*s

        path.move(to: CGPoint(x: x1, y: y2))
        if !cutouts.contains(.upperLeft) {
            path.addArc(tangent1End: CGPoint(x: x1, y: y1), tangent2End: CGPoint(x: x2, y: y1), radius: r)
        } else {
            let radius: CGFloat = 29*s
            path.addArc(center: CGPoint(x: 20*s, y: 20*s), radius: radius, startAngle: 1/2 * .pi + atan(radius/20), endAngle: -atan(radius/20), clockwise: true)
        }
        if !cutouts.contains(.upperRight) {
            path.addArc(tangent1End: CGPoint(x: x3, y: y1), tangent2End: CGPoint(x: x3, y: y2), radius: r)
        } else {
            let radius: CGFloat = 24*s
            path.addArc(center: CGPoint(x: width-20*s, y: 20*s), radius: radius, startAngle: 3/2 * .pi - atan(radius/20), endAngle: atan(radius/20), clockwise: true)
        }
        if !cutouts.contains(.lowerRight) {
            path.addArc(tangent1End: CGPoint(x: x3, y: y3), tangent2End: CGPoint(x: x2, y: y3), radius: r)
        } else {
            let radius: CGFloat = 29*s
            path.addArc(center: CGPoint(x: width-20*s, y: height-20*s), radius: radius, startAngle: -atan(radius/20), endAngle: 1/2 * .pi + atan(radius/20), clockwise: true)
        }
        if !cutouts.contains(.lowerLeft) {
            path.addArc(tangent1End: CGPoint(x: x1, y: y3), tangent2End: CGPoint(x: x1, y: y2), radius: r)
        } else {
            let radius: CGFloat = 29*s
            path.addArc(center: CGPoint(x: 20*s, y: height-20*s), radius: radius, startAngle: 1/2 * .pi - atan(radius/20), endAngle: .pi + atan(radius/20), clockwise: true)
        }
        path.closeSubpath()
        
        return path
    }
    private func renderPaths() {
        let a: CGFloat = 6*Screen.s
        let b: CGFloat = 2*Screen.s

        path.strokePath = buildPath(p: a)
        path.maskPath = buildPath(p: a)
        path.shadowPath = buildPath(p: b)
        
        self.layer.shadowPath = path.shadowPath
        setNeedsDisplay()
    }
    
// UIView ==========================================================================================
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let path = path.strokePath else { return super.hitTest(point, with: event) }
        if path.contains(point) { return super.hitTest(point, with: event) }
        else { return nil }
    }
    override var frame: CGRect {
        didSet {
            guard frame != CGRect.zero else { return }
            renderPaths()
            layoutContent()
        }
    }
    override func draw(_ rect: CGRect) {
        let c = UIGraphicsGetCurrentContext()!
        c.addPath(path.strokePath)
        c.setStrokeColor(UIColor(white: 0.3, alpha: 1).cgColor)
        c.setLineWidth(1.5*s)
        c.strokePath()
    }
}
