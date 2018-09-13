//
//  DilatorView.swift
//  Aexels
//
//  Created by Joe Charlier on 2/12/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import UIKit
import OoviumLib

class DilatorView: UIView, UIGestureRecognizerDelegate {
	var currentSps: CGFloat = 10
	var minimumSps: CGFloat = 1
	var maximumSps: CGFloat = 10
	
	var _actualSps: CGFloat = 10
	var actualSps: CGFloat {
		set {
			_actualSps = newValue
			DispatchQueue.main.async {
				self.setNeedsDisplay()
			}
		}
		get {return _actualSps}
	}
	
	var onChange: ((Double)->())?
	
	init() {
		super.init(frame: CGRect.zero)
		
		backgroundColor = UIColor.clear
		
		let gesture = UIPanGestureRecognizer(target: self, action: #selector(onPan))
		gesture.delegate = self
		addGestureRecognizer(gesture)
	}
	required init? (coder aDecoder: NSCoder) {fatalError()}
	
	var interval: Double {
		if currentSps == maximumSps {return 1.0/60}
		else {return 1/Double(currentSps)}
	}
	
// Events ==========================================================================================
	@objc func onPan (gesture: UIPanGestureRecognizer) {
		let p: CGFloat = 3*Screen.s
		let dw: CGFloat = 0

		let x1: CGFloat = p
		let x5: CGFloat = width - dw - 2*p
		
		var x: CGFloat = gesture.location(in: self).x
		if x < x1 {x = x1}
		else if x > x5 {x = x5}
		
		currentSps = minimumSps + (maximumSps - minimumSps) * (x - x1) / (x5 - x1)
		actualSps = currentSps
		if let onChange = onChange {
			onChange(currentSps == maximumSps ? 60 : Double(round(currentSps)))
		}
		setNeedsDisplay()
	}
	
// UIView ==========================================================================================
	override func draw (_ rect: CGRect) {
		let p: CGFloat = 3*s;
		let crx: CGFloat = 16*s
		let cry: CGFloat = 12*s
		
		let x1: CGFloat = p
		let x5: CGFloat = width - p
		let x3: CGFloat = x1 + crx + (x5-x1-2*crx) * (currentSps - minimumSps) / (maximumSps - minimumSps)
		let x2: CGFloat = x3 - crx
		let x4: CGFloat = x3 + crx
		let y2: CGFloat = height / 2
		let y1: CGFloat = y2 - cry
		
		let path = CGMutablePath()
		
		if (x2 > x1) {
			path.move(to: CGPoint(x: x1, y: y2))
			path.addLine(to: CGPoint(x: x2, y: y2))
		}
		if (x4 < x5) {
			path.move(to: CGPoint(x: x4, y: y2))
			path.addLine(to: CGPoint(x: x5, y: y2))
		}
		path.addEllipse(in: CGRect(x: x2, y: y1, width: 2*crx, height: 2*cry))
		
		let c = UIGraphicsGetCurrentContext();
		c?.addPath(path)

		c?.setStrokeColor(UIColor.white.cgColor)
		c?.setLineWidth(3)
		c?.strokePath()

//		let x6 = rect.size.width - dw + p
//		let x7 = rect.size.width - p

		let pen = Pen(font: UIFont(name: "Avenir-Heavy", size: 15*s)!)
		pen.alignment = .center
		("\(Int(actualSps))" as NSString).draw(in: CGRect(x: x2+6*s, y: y1+2*s, width: 20*s, height: 16*s), withAttributes: pen.attributes)
//		attributes.font = UIFont(name: "GillSans-Italic", size: 10)!
//		("steps / second" as NSString).draw(in: CGRect(x: x7-90, y: 31, width: 90, height: 30), withAttributes: attributes.attributes)
	}

// UIGestureRecognizerDelegate =====================================================================
	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
		if touch.phase != .began {return true}
		
		let p: CGFloat = 3*s
		let cr: CGFloat = 16*s

		let x1: CGFloat = p+cr
		let x5: CGFloat = frame.size.width - cr - p
		let x3 = x1 + (x5-x1) * (currentSps - minimumSps) / (maximumSps - minimumSps)
		let x2 = x3 - cr
		let x4 = x3 + cr
		
		let x = touch.location(in: self).x
		return x > x2-10*s && x < x4+10*s;
	}
}
