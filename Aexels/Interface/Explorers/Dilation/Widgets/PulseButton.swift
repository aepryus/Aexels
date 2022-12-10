//
//  PulseButton.swift
//  Aexels
//
//  Created by Joe Charlier on 12/10/22.
//  Copyright © 2022 Aepryus Software. All rights reserved.
//

import Acheron
import OoviumEngine
import UIKit

class PulseButton: AXButton {
    
//    overriinit() {
//        super.init(frame: .zero)
//        backgroundColor = .clear
//    }
//    required init?(coder: NSCoder) { fatalError() }
    
// UIView ==========================================================================================
    override func draw(_ rect: CGRect) {
        
        let c = UIGraphicsGetCurrentContext()!

        var path = CGMutablePath(roundedRect: rect.inset(by: UIEdgeInsets(top: 3*s, left: 3*s, bottom: 3*s, right: 3*s)), cornerWidth: 7*s, cornerHeight: 7*s, transform: nil)
        c.addPath(path)
        
        path = CGMutablePath()
        let center = CGPoint(x: width/2, y: height/2+10*s)
        let ir: CGFloat = 10
        let or: CGFloat = 20
        let n: Int = 8
        var q: CGFloat = 0
        let dq: CGFloat = 2*Double.pi/Double(n)
        for _ in 0...n {
            path.move(to: center+CGPoint(x: ir*sin(q), y: ir*cos(q)))
            path.addLine(to: center+CGPoint(x: or*sin(q), y: or*cos(q)))
            q += dq
        }
        c.addPath(path)


        let stroke = isHighlighted ? OOColor.lavender.uiColor : UIColor.white

        c.setStrokeColor(stroke.cgColor)
        c.setLineWidth(3)
        c.strokePath()

        let pen = Pen(font: UIFont(name: "Avenir-Heavy", size: 15*s)!, color: stroke, alignment: .center)
        "pulse".draw(in: CGRect(x: (width-50*s)/2, y: 10*s, width: 50*s, height: 20*s), pen: pen)
    }
}
