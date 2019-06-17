//
//  GravityView.swift
//  Aexels
//
//  Created by Joe Charlier on 6/16/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import Acheron
import OoviumLib
import UIKit

class GravityView: UIView {
	var universe: UnsafeMutablePointer<Universe>
	
	init() {
		let height: CGFloat = Screen.height - Screen.safeTop - Screen.safeBottom
		let s = height / 748
		let side = Double(height - 30*s)
		universe = AXUniverseCreate(side, side, 20, 0.1, 1000)
		super.init(frame: CGRect.zero)
		backgroundColor = UIColor.clear

		AXUniverseBind(universe)
		
		let gesture = UITapGestureRecognizer(target: self, action: #selector(onTap(_:)))
		addGestureRecognizer(gesture)
	}
	required init?(coder aDecoder: NSCoder) {fatalError()}
	deinit {
		AXUniverseRelease(universe)
	}
	
	func play() {
		Aexels.sync.start()
	}
	func stop() {
		Aexels.sync.stop()
	}
	func reset() {
		let height: CGFloat = Screen.height - Screen.safeTop - Screen.safeBottom
		let s = height / 748
		let side = Double(height - 30*s)
		AXUniverseRelease(universe)
		universe = AXUniverseCreate(side, side, 20, 0.1, 1000)
		AXUniverseBind(universe)
		setNeedsDisplay()
	}
	func tic() {
		AXUniverseJump(universe)
		AXUniverseBind(universe)
		setNeedsDisplay()
		sampleFrameRate()
	}
	
// Sample Frame Rate ===============================================================================
	private var last: Date = Date()
	private var step: Int = 1
	var onMeasure: ((Double)->())? = { (sps: Double)  in
		print("SPS: \(sps)")
	}
	func sampleFrameRate() {
		if self.step % 60 == 0 {
			let now = Date()
			let x = now.timeIntervalSince(self.last)
			if let onMeasure = self.onMeasure {
				onMeasure(60.0/x)
			}
			self.last = now
		}
		self.step += 1
	}
	
// Events ==========================================================================================
	@objc func onTap(_ gesture: UITapGestureRecognizer) {
		let x = gesture.location(in: self)
		print("tap: \(x)")
	}
	
// UIView ==========================================================================================
	override func draw(_ rect: CGRect) {

		let c = UIGraphicsGetCurrentContext()!
		
//		let relaxed: Double = universe.pointee.relaxed;

		c.setStrokeColor(OOColor.lavender.uiColor.cgColor)

		for i in 0..<Int(universe.pointee.noOfAexels) {
			let aexel = universe.pointee.aexels![i]!

			for j in 0..<6 {
				guard let neighbor = aexel.pointee.neighbors[j] else {continue}
				var shouldRender: Bool = false
				if neighbor.pointee.curP.x > aexel.pointee.curP.x {shouldRender = true}
				if neighbor.pointee.curP.x == aexel.pointee.curP.x {
					if neighbor.pointee.curP.y > aexel.pointee.curP.y {shouldRender = true}
				}
				guard shouldRender else {continue}
				c.move(to: CGPoint(x: aexel.pointee.curP.x, y: aexel.pointee.curP.y))
				c.addLine(to: CGPoint(x: neighbor.pointee.curP.x, y: neighbor.pointee.curP.y))
			}
		}
		c.drawPath(using: .stroke)

//		c.setStrokeColor(UIColor(rgb: 0xFFFFFF).cgColor)
//		c.setFillColor(UIColor(rgb: 0xEEEEEE).alpha(0.5).cgColor);
//
//		for i in 0..<Int(universe.pointee.noOfAexels) {
//			let aexel = universe.pointee.aexels![i]!
//
//			c.addEllipse(in: CGRect(x: aexel.pointee.curP.x-relaxed/2, y: aexel.pointee.curP.y-relaxed/2, width: relaxed, height: relaxed))
//		}
//		c.drawPath(using: .fillStroke)
	}
}
