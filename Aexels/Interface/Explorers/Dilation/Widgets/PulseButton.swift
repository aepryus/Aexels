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
        
        let ss: CGFloat = rect.width/60
        
        let c = UIGraphicsGetCurrentContext()!

        var path = CGMutablePath(roundedRect: rect.inset(by: UIEdgeInsets(top: 3*s, left: 3*s*ss, bottom: 3*s*ss, right: 3*s*ss)), cornerWidth: 7*s*ss, cornerHeight: 7*s*ss, transform: nil)
        c.addPath(path)
        
        path = CGMutablePath()
        let center = CGPoint(x: width/2, y: height/2+10*s*ss)
        let ir: CGFloat = 10*ss
        let or: CGFloat = 20*ss
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
        c.setLineWidth(3*ss)
        c.strokePath()

        let pen = Pen(font: UIFont(name: "Avenir-Heavy", size: 15*s*ss)!, color: stroke, alignment: .center)
        "pulse".draw(in: CGRect(x: (width-50*s*ss)/2, y: 10*s*ss, width: 50*s*ss, height: 20*s*ss), pen: pen)
    }
}
