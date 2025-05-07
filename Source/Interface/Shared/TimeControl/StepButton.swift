//
//  StepButton.swift
//  Aexels
//
//  Created by Joe Charlier on 1/22/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

import Acheron
import OoviumEngine
import UIKit

class StepButton: AXButton {
    
    override init() {
        super.init(frame: CGRect(origin: .zero, size: CGSize(width: 32*Screen.s, height: 26*Screen.s)))
    }
    
// UIView ==========================================================================================
    override func draw(_ rect: CGRect) {
        let s: CGFloat = Screen.s * 0.9
        let h: CGFloat = 16*s                // height
        let bw: CGFloat = 3*s                // bar width
        let mw: CGFloat = 3*s                // margin width
        
        let x1: CGFloat = 13*s
        let x3 = x1+bw
        let x2 = (x1+x3)/2
        let x4 = x3+mw
        
        let y1: CGFloat = 6.5*s
        let y3 = y1+h
        let y2 = (y1+y3)/2

        let path = CGMutablePath()
        path.move(to: CGPoint(x: x1, y: y2))
        path.addArc(tangent1End: CGPoint(x: x1, y: y1), tangent2End: CGPoint(x: x2, y: y1), radius: 1)
        path.addArc(tangent1End: CGPoint(x: x3, y: y1), tangent2End: CGPoint(x: x3, y: y2), radius: 1)
        path.addArc(tangent1End: CGPoint(x: x3, y: y3), tangent2End: CGPoint(x: x2, y: y3), radius: 1)
        path.addArc(tangent1End: CGPoint(x: x1, y: y3), tangent2End: CGPoint(x: x1, y: y2), radius: 1)
        path.closeSubpath()
        
        let q: CGFloat = -0.05*s
        path.move(to: CGPoint(x: x4, y: y3))
        path.addLine(to: CGPoint(x: x4, y: y1))
        path.addArc(center: CGPoint(x: x4, y: y2), radius: h/2, startAngle: CGFloat.pi/2+q, endAngle: -CGFloat.pi/2+q, clockwise: true)

        let stroke = isHighlighted ? Text.Color.lavender.uiColor : UIColor.white
        let fill = stroke.shade(0.5)
        let c = UIGraphicsGetCurrentContext()!
        c.addPath(path)
        c.setFillColor(fill.cgColor)
        c.setStrokeColor(stroke.cgColor)
        c.setLineWidth(1.5*s)
        c.drawPath(using: .fillStroke)
    }
}
