//
//  DilatorView.swift
//  Aexels
//
//  Created by Joe Charlier on 2/12/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import Acheron
import UIKit
import OoviumLib

class DilatorView: UIView, UIGestureRecognizerDelegate {
	var position: CGFloat = 1
	var frameRate: Int = 60
	static var maxFrameRate: Int = 60
	var availableFrameRates: [Int] = {
		var frameRates: [Int] = []
		let max = UIScreen.main.maximumFramesPerSecond
		for i: Int in 1...DilatorView.maxFrameRate {
			if max/i*i == max {frameRates.append(i)}
		}
		return frameRates
	}()

	var actualFrameRate: Int = 60 {
		didSet {setNeedsDisplay()}
	}
	
	var onChange: ((Int)->())?
	
	init() {
		super.init(frame: CGRect.zero)
		
		backgroundColor = UIColor.clear
		
		let gesture = UIPanGestureRecognizer(target: self, action: #selector(onPan))
		gesture.delegate = self
		addGestureRecognizer(gesture)
	}
	required init?(coder aDecoder: NSCoder) {fatalError()}
	
// Events ==========================================================================================
	@objc func onPan(gesture: UIPanGestureRecognizer) {
		let p: CGFloat = 3*Screen.s
		let dw: CGFloat = 0

		let x1: CGFloat = p
		let x5: CGFloat = width - dw - 2*p
		
		var x: CGFloat = gesture.location(in: self).x
		if x < x1 {x = x1}
		else if x > x5 {x = x5}
		
		position = (x - x1) / (x5 - x1)
		
		frameRate = availableFrameRates[Int(round(CGFloat(availableFrameRates.count-1) * position))]
		if let onChange = onChange {
			onChange(frameRate)
		}
		setNeedsDisplay()
	}
	
// UIView ==========================================================================================
	override func draw(_ rect: CGRect) {
		let p: CGFloat = 3*s;
		let crx: CGFloat = 16*s
		let cry: CGFloat = 12*s
		
		let x1: CGFloat = p
		let x5: CGFloat = width - p
		let x3: CGFloat = x1 + crx + (x5-x1-2*crx) * position
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

		let pen = Pen(font: UIFont(name: "Avenir-Heavy", size: 15*s)!, color: .white, alignment: .center)
		("\(Int(frameRate))" as NSString).draw(in: CGRect(x: x2+6*s, y: y1+2*s, width: 20*s, height: 16*s), pen: pen)
	}

// UIGestureRecognizerDelegate =====================================================================
	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
		if touch.phase != .began {return true}
		
		let p: CGFloat = 3*s
		let cr: CGFloat = 16*s

		let x1: CGFloat = p+cr
		let x5: CGFloat = frame.size.width - cr - p
		let x3 = x1 + (x5-x1) * position
		let x2 = x3 - cr
		let x4 = x3 + cr
		
		let x = touch.location(in: self).x
		return x > x2-10*s && x < x4+10*s;
	}
}
