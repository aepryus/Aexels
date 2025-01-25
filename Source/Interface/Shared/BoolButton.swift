//
//  BoolButton.swift
//  Aexels
//
//  Created by Joe Charlier on 1/23/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

import Acheron
import OoviumEngine
import UIKit

class BoolView: AEView {
    var on: Bool = false {
        didSet { setNeedsDisplay() }
    }
    var isHighlighted: Bool = false
    
    override init() {
        super.init()
        backgroundColor = .clear
    }
    
// UIView ==========================================================================================
    override func draw(_ rect: CGRect) {
        let p: CGFloat = 1*s
        let m: CGFloat = 4*s
        let or: CGFloat = 5*s
        let ir: CGFloat = 2*s

        let x1 = p
        let x2 = x1 + m
        let x4 = width - p
        let x3 = x4 - m
        
        let y1 = p
        let y2 = x1 + m
        let y4 = height - p
        let y3 = x4 - m
        
        let color: UIColor = isHighlighted ? OOColor.lavender.uiColor : UIColor.white

        let c = UIGraphicsGetCurrentContext()!
        c.move(to: CGPoint(x: x1, y: (y1+y4)/2))
        c.addArc(tangent1End: CGPoint(x: x1, y: y1), tangent2End: CGPoint(x: (x1+x4)/2, y: y1), radius: or)
        c.addArc(tangent1End: CGPoint(x: x4, y: y1), tangent2End: CGPoint(x: x4, y: (y1+y4)/2), radius: or)
        c.addArc(tangent1End: CGPoint(x: x4, y: y4), tangent2End: CGPoint(x: (x1+x4)/2, y: y4), radius: or)
        c.addArc(tangent1End: CGPoint(x: x1, y: y4), tangent2End: CGPoint(x: x1, y: (y1+y4)/2), radius: or)
        c.closePath()
        
        c.setLineWidth(1.5*s)
        c.setStrokeColor(color.cgColor)
        c.drawPath(using: .stroke)
        
        if on {
            c.move(to: CGPoint(x: x2, y: (y2+y3)/2))
            c.addArc(tangent1End: CGPoint(x: x2, y: y2), tangent2End: CGPoint(x: (x2+x3)/2, y: y2), radius: ir)
            c.addArc(tangent1End: CGPoint(x: x3, y: y2), tangent2End: CGPoint(x: x3, y: (y2+y3)/2), radius: ir)
            c.addArc(tangent1End: CGPoint(x: x3, y: y3), tangent2End: CGPoint(x: (x2+x3)/2, y: y3), radius: ir)
            c.addArc(tangent1End: CGPoint(x: x2, y: y3), tangent2End: CGPoint(x: x2, y: (y2+y3)/2), radius: ir)
            c.closePath()
            
            c.setLineWidth(1.0*s)
            c.setStrokeColor(color.cgColor)
            c.setFillColor(color.cgColor)
            c.drawPath(using: .fillStroke)
        }
    }
}

protocol BoolButtonDelegate {
}

class BoolButton: AXButton {
    let name: String
    
    let boolView: BoolView = BoolView()
    let label: UILabel = UILabel()
    
    var on: Bool = false {
        didSet {
            self.boolView.on = self.on
            self.onChange?(self.on)
        }
    }

    var onChange: ((Bool)->())?
    
    init(name: String) {
        self.name = name
        super.init()
        
        boolView.isUserInteractionEnabled = false
        addSubview(boolView)
        
        label.text = name
        label.pen = Pen(font: .avenir(size: 12*s), color: .white)
        addSubview(label)
        
        addAction {
            self.on = !self.on
            self.boolView.on = self.on
            self.onChange?(self.on)
        }
    }
    
// UIView ==========================================================================================
    override func layoutSubviews() {
        boolView.left(size: CGSize(width: 20*s, height: 20*s))
        label.left(dx: boolView.right+3*s, width: 200*s, height: height)
    }
    override var isHighlighted: Bool {
        didSet {
            boolView.isHighlighted = isHighlighted
            boolView.setNeedsDisplay()
            label.textColor = isHighlighted ? OOColor.lavender.uiColor : .white
        }
    }
}
