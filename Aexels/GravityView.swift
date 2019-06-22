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
	
	private var queue: DispatchQueue = DispatchQueue(label: "gravityView")
	var renderMode: RenderMode = .started
	private var image: UIImage?
	private var vw: Int = 0

	init() {
		let height: CGFloat = Screen.height - Screen.safeTop - Screen.safeBottom
		let s = height / 748
		let side = Double(height - 30*s)
		vw = Int(side)
		universe = AXUniverseCreate(side, side, 20, 0.1, 1672, 9, 0)
//		universe = AXUniverseCreateSmooth(side, side, 20, 0.1, 1, 0)
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
		universe = AXUniverseCreate(side, side, 20, 0.1, 1672, 9, 0)
//		universe = AXUniverseCreateSmooth(side, side, 20, 0.1, 1, 0)
		AXUniverseBind(universe)
		self.renderMode = .started
		self.renderImage()
		setNeedsDisplay()
	}
	func tic() {
		queue.sync {
			AXUniverseJump(self.universe)
			AXUniverseBind(self.universe)
			AXUniverseStep(self.universe)
			self.renderMode = .started
			self.renderImage()
			self.sampleFrameRate()
			DispatchQueue.main.async {
				self.setNeedsDisplay()
			}
		}
	}
	
	func renderImage() {
		guard renderMode == .started else {return}
		renderMode = .rendering
		
		UIGraphicsBeginImageContext(bounds.size)
		let c = UIGraphicsGetCurrentContext()!
		
		c.setStrokeColor(OOColor.lavender.uiColor.cgColor)
		
		for i in 0..<Int(universe.pointee.aexelCount) {
			let aexel = universe.pointee.aexels![i]!
			
			for j in 0..<6 {
				guard let neighbor = aexel.pointee.neighbors[j] else {continue}
				var shouldRender: Bool = false
				if neighbor.pointee.s.x > aexel.pointee.s.x {shouldRender = true}
				if neighbor.pointee.s.x == aexel.pointee.s.x {
					if neighbor.pointee.s.y > aexel.pointee.s.y {shouldRender = true}
				}
				guard shouldRender else {continue}
				c.move(to: CGPoint(x: aexel.pointee.s.x, y: aexel.pointee.s.y))
				c.addLine(to: CGPoint(x: neighbor.pointee.s.x, y: neighbor.pointee.s.y))
			}
		}
		c.drawPath(using: .stroke)

//			let relaxed: Double = universe.pointee.relaxed;
//
//			c.setStrokeColor(UIColor(rgb: 0xFFFFFF).cgColor)
//			c.setFillColor(UIColor(rgb: 0xEEEEEE).alpha(0.5).cgColor);
//			c.setLineWidth(0.5)
//
//			for i in 0..<Int(universe.pointee.noOfAexels) {
//				let aexel = universe.pointee.aexels![i]!
//
//				c.addEllipse(in: CGRect(x: aexel.pointee.curP.x-relaxed/2, y: aexel.pointee.curP.y-relaxed/2, width: relaxed, height: relaxed))
//			}
//			c.drawPath(using: .fillStroke)
		
		let radius: Double = 3
		for i in 0..<Int(universe.pointee.photonCount) {
			let photon = universe.pointee.photons![i]!
			
			c.setStrokeColor(UIColor.white.cgColor);
			c.setFillColor(UIColor(rgb: 0x00FF00).cgColor);
			c.addEllipse(in: CGRect(x: photon.pointee.aexel.pointee.s.x-radius, y: photon.pointee.aexel.pointee.s.y-radius, width: 2*radius, height: 2*radius))
			c.move(to: CGPoint(x: photon.pointee.aexel.pointee.s.x, y: photon.pointee.aexel.pointee.s.y))
			c.addLine(to: CGPoint(x: photon.pointee.aexel.pointee.s.x+photon.pointee.v.x*7, y: photon.pointee.aexel.pointee.s.y+photon.pointee.v.y*7))
		}
		c.drawPath(using: .fillStroke)

		
		self.image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		
		renderMode = .rendered
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
		if image == nil {renderImage()}
		guard let image = image?.cgImage else {return}
		let c = UIGraphicsGetCurrentContext()!
		c.translateBy(x: 0, y: CGFloat(vw))
		c.scaleBy(x: 1, y: -1)
		c.draw(image, in: rect)
		renderMode = .displayed
	}
}
