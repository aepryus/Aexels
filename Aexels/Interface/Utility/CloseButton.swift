//
//  CloseButton.swift
//  Aexels
//
//  Created by Joe Charlier on 12/16/22.
//  Copyright © 2022 Aepryus Software. All rights reserved.
//

import UIKit

class CloseButton: AXButton {
    private var limboPath: LimboPath = LimboPath()
    
    override init() {
        super.init()
        backgroundColor = UIColor.clear
        
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize.zero
        layer.shadowRadius = 3*s
        layer.shadowOpacity = 0.6
    }
    required init?(coder aDecoder: NSCoder) { fatalError() }
    
    private func buildPath(p: CGFloat, q: CGFloat) -> CGPath {
        let path = CGMutablePath()
        
        let x1 = q
        let x3 = width - p
        let x2 = (x1 + x3) / 2
        let y1 = p
        let y3 = height - q
        let y2 = (y1 + y3) / 2
        let cr: CGFloat = y3-y1
        let radius: CGFloat = 10*s
        
        path.move(to: CGPoint(x: x2, y: y1))
        path.addArc(tangent1End: CGPoint(x: x3, y: y1), tangent2End: CGPoint(x: x3, y: y2), radius: radius)
        path.addLine(to: CGPoint(x: x3, y: y3))
        path.addArc(center: CGPoint(x: x3, y: y1), radius: cr, startAngle: .pi/2, endAngle: .pi, clockwise: false)
        path.addLine(to: CGPoint(x: x2, y: y1))
        
        path.closeSubpath()
        
        return path
    }

    private func renderPaths() {
        let a: CGFloat = 6*s
        let b: CGFloat = 2*s

        limboPath.strokePath = buildPath(p: a, q: a)
        limboPath.maskPath = buildPath(p: a, q: a-b)
        limboPath.shadowPath = buildPath(p: b, q: b)
        
        self.layer.shadowPath = limboPath.shadowPath
        setNeedsDisplay()
    }

// UIView ==========================================================================================
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let path = limboPath.strokePath else { return super.hitTest(point, with: event) }
        if path.contains(point) { return super.hitTest(point, with: event) }
        else { return nil }
    }
    override var frame: CGRect {
        didSet {
            guard frame != CGRect.zero else { return }
            renderPaths()
        }
    }
    override func draw(_ rect: CGRect) {
        let c = UIGraphicsGetCurrentContext()!
        c.addPath(limboPath.strokePath)
        c.setStrokeColor(UIColor(white: 0.3, alpha: 1).cgColor)
        c.setLineWidth(1.5*s)
        c.strokePath()
        
        let d: CGFloat = width*0.29
        let p: CGFloat = width*0.28
        let x1: CGFloat = width - d - p
        let x2: CGFloat = x1 + d
        let y1: CGFloat = p
        let y2: CGFloat = y1 + d
        
        let path: CGMutablePath = CGMutablePath()
        path.move(to: CGPoint(x: x1, y: y1))
        path.addLine(to: CGPoint(x: x2, y: y2))
        path.move(to: CGPoint(x: x2, y: y1))
        path.addLine(to: CGPoint(x: x1, y: y2))
        c.addPath(path)
        c.setLineWidth(3*s)
        c.setLineCap(.round)
        c.setStrokeColor(UIColor.white.cgColor)
        c.drawPath(using: .stroke)
    }
}
