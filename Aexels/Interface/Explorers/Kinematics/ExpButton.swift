//
//  ExpButton.swift
//  Aexels
//
//  Created by Joe Charlier on 9/11/18.
//  Copyright © 2018 Aepryus Software. All rights reserved.
//

import Acheron
import OoviumEngine
import OoviumKit
import UIKit

class ExpButton: UIControl {
    enum Shape { case line, rectangle, box, ring, circle, nothing }
	
	var name: String?
    var shape: Shape?
	var color: UIColor
	var backColor: UIColor? = nil
	var size: CGFloat = 13*Screen.s
	var radius: CGFloat = 5*Screen.s
	var activated: Bool = false {
		didSet{ setNeedsDisplay() }
	}
	
    init(name: String? = nil, shape: Shape? = nil) {
		self.name = name
        self.shape = shape
		color = UIColor.white
		super.init(frame: CGRect.zero)
		backgroundColor = .clear
	}
	init(name: String? = nil, color: UIColor) {
		self.name = name
		self.color = color
		super.init(frame: CGRect.zero)
		backgroundColor = .clear
	}
	required init?(coder aDecoder: NSCoder) {fatalError()}
	
// UIView ==========================================================================================
	override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
		let inside = super.point(inside: point, with: event)
		if inside && !isHighlighted && event?.type == .touches {
			isHighlighted = true
		}
		return inside
	}
	override var isHighlighted: Bool {
		didSet {setNeedsDisplay()}
	}
	override func draw(_ rect: CGRect) {
		let c = UIGraphicsGetCurrentContext()!
		
		let color = !isHighlighted ? self.color : OOColor.lavender.uiColor
		
		let path = CGPath(roundedRect: rect.insetBy(dx: 0.5, dy: 0.5), cornerWidth: radius, cornerHeight: radius, transform: nil)
		c.addPath(path)
		color.setStroke()
		if !activated {
			if let backColor = backColor {
				backColor.setFill()
				c.drawPath(using: .fillStroke)
			} else {
				c.drawPath(using: .stroke)
			}
		} else {
			color.setFill()
			c.drawPath(using: .fillStroke)
		}
        
        if let name {
            let pen: Pen = Pen(font: UIFont.axBold(size: self.size), color: (activated ? .black : color), alignment: .center)
            let size = (name as NSString).size(withAttributes: pen.attributes)
            name.draw(in: CGRect(x: rect.origin.x, y: (rect.size.height-size.height)/2, width: rect.size.width, height: size.height), withAttributes: pen.attributes)
        }
        if let shape {
            let path: CGMutablePath
            var mode: CGPathDrawingMode = .stroke
            let activatedColor: UIColor = .black.tint(0.4)
            (activated ? activatedColor : color).setStroke()
            (activated ? activatedColor : color).setFill()
            switch shape {
                case .line:
                    path = CGMutablePath()
                    path.move(to: CGPoint(x: rect.width*0.5, y: rect.height*0.2))
                    path.addLine(to: CGPoint(x: rect.width*0.5, y: rect.height*0.8))
                case .rectangle:
                    path = CGMutablePath(rect: CGRect(x: rect.width*0.3, y: rect.height*0.2, width: rect.width*0.4, height: rect.height*0.6), transform: nil)
                case .box:
                    path = CGMutablePath(rect: CGRect(x: rect.width*0.3, y: rect.height*0.2, width: rect.width*0.4, height: rect.height*0.6), transform: nil)
                    mode = .fillStroke
                case .ring:
                    let r: CGFloat = width*0.3
                    path = CGMutablePath(ellipseIn: CGRect(x: width/2-r, y: height/2-r, width: 2*r, height: 2*r), transform: nil)
                case .circle:
                    let r: CGFloat = width*0.3
                    path = CGMutablePath(ellipseIn: CGRect(x: width/2-r, y: height/2-r, width: 2*r, height: 2*r), transform: nil)
                    mode = .fillStroke
                case .nothing:
                    path = CGMutablePath()
            }
            c.setLineWidth(3)
            c.addPath(path)
            c.drawPath(using: mode)
        }
	}
}
