//
//  NewtonianView.swift
//  Aexels
//
//  Created by Joe Charlier on 2/18/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import OoviumLib
import UIKit

class NewtownianView: UIView, Simulation {
	var x: V2
	var v: V2
	var w: Double = 0
	var h: Double = 0
	
	var onTic: ((V2)->())
	
	var timer = AXTimer()
	
	var image: UIImage?
	
	init (_ onTic: @escaping (V2)->()) {
		x = V2(100, 100)
		v = V2(5 , 3)
		self.onTic = onTic
		super.init(frame: CGRect.zero)
		
		backgroundColor = UIColor.clear
		timer.configure(interval: 1.0/60.0) {
			self.tic()
		}
	}
	required init? (coder aDecoder: NSCoder) {fatalError()}
	
	func tic() {
		x.x += v.x
		x.y += v.y
		
		let r: Double = 31
		
		if (x.x<r && v.x<0) || (x.x>w-r && v.x>0) {v.x = -v.x}
		if (x.y<r && v.y<0) || (x.y>h-r && v.y>0) {v.y = -v.y}

		onTic(v)
		
		DispatchQueue.main.async {
			self.setNeedsDisplay()
		}
}
	
// UIView ==========================================================================================
	override var frame: CGRect {
		didSet {
			w = Double(width)
			h = Double(height)
		}
	}
	override func draw (_ rect: CGRect) {
		let r: CGFloat = 26
		
		let path = CGMutablePath()
		path.addEllipse(in: CGRect(x: CGFloat(x.x)-r, y: CGFloat(x.y)-r, width: 2*r, height: 2*r))
		path.addEllipse(in: CGRect(x: x.x-1.5, y: x.y-1.5, width: 3, height: 3))
		path.move(to: CGPoint(x: x.x, y: x.y))
		path.addLine(to: CGPoint(x: CGFloat(x.x)+CGFloat(v.x)/10*r, y: CGFloat(x.y)+CGFloat(v.y)/10*r))
		
		let c = UIGraphicsGetCurrentContext()!
		c.addPath(path)
		c.setStrokeColor(UIColor.white.cgColor)
		c.setFillColor(UIColor(red: 198.0/255, green: 181.0/255, blue: 241.0/255, alpha: 0.5).cgColor)
		c.drawPath(using: .fillStroke)
	}
	
// Simulation ======================================================================================
	func play() {
		timer.start()
	}
	func stop() {
		timer.stop()
	}
	func reset() {
	}
}
