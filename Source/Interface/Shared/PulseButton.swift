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
    let name: String?
    
    init(name: String?) {
        self.name = name
        super.init()
    }
    
// UIView ==========================================================================================
    override func draw(_ rect: CGRect) {
        
        let ss: CGFloat = rect.width/60/Screen.s
        
        let c = UIGraphicsGetCurrentContext()!

        var path = CGMutablePath(roundedRect: rect.inset(by: UIEdgeInsets(top: 3*s, left: 3*s*ss, bottom: 3*s*ss, right: 3*s*ss)), cornerWidth: 7*s*ss, cornerHeight: 7*s*ss, transform: nil)
        c.addPath(path)
        
        path = CGMutablePath()
        let center = CGPoint(x: width/2, y: height/2+(name == nil ? 0 : 10*s*ss))
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


        let stroke = isHighlighted ? Text.Color.lavender.uiColor : UIColor.white

        c.setStrokeColor(stroke.cgColor)
        c.setLineWidth(3*ss)
        c.strokePath()

        if let name {
            let pen = Pen(font: UIFont(name: "Avenir-Heavy", size: 15*s*ss)!, color: stroke, alignment: .center)
            name.draw(in: CGRect(x: (width-50*s*ss)/2, y: 10*s*ss, width: 50*s*ss, height: 20*s*ss), pen: pen)
        }
    }
}
