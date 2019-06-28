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
		universe = AXUniverseCreate(side, side, 40, 0.1, 360, 9, 6)
//		universe = AXUniverseCreateSmooth(side, side, 40, 0.1, 9, 6)
//		universe = AXUniverseCreate(side, side, 20, 0.1, 1672, 9, 6)
//		universe = AXUniverseCreateSmooth(side, side, 20, 0.1, 9, 6)
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
		universe = AXUniverseCreate(side, side, 40, 0.1, 360, 9, 6)
//		universe = AXUniverseCreateSmooth(side, side, 40, 0.1, 9, 6)
//		universe = AXUniverseCreate(side, side, 20, 0.1, 1672, 9, 6)
//		universe = AXUniverseCreateSmooth(side, side, 20, 0.1, 9, 6)
		AXUniverseBind(universe)
		self.renderMode = .started
		self.renderImage()
		setNeedsDisplay()
	}
	func tic() {
		queue.sync {
			AXUniverseStep(self.universe)
			AXUniverseJump(self.universe)
			if (step % 27 == 0) {AXUniverseWarp(self.universe)}
			AXUniverseBind(self.universe)
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

		for i in 0..<Int(universe.pointee.bondCount) {
			let bond = universe.pointee.bonds[i]
			c.move(to: CGPoint(x: bond.a.pointee.s.x, y: bond.a.pointee.s.y))
			c.addLine(to: CGPoint(x: bond.b.pointee.s.x, y: bond.b.pointee.s.y))
		}
		c.drawPath(using: .stroke)

//		for i in 0..<Int(universe.pointee.aexelCount) {
//			let aexel = universe.pointee.aexels![i]!
//
//			for j in 0..<6 {
//				guard let neighbor = aexel.pointee.neighbors[j] else {continue}
//				var shouldRender: Bool = false
//				if neighbor.pointee.s.x > aexel.pointee.s.x {shouldRender = true}
//				if neighbor.pointee.s.x == aexel.pointee.s.x {
//					if neighbor.pointee.s.y > aexel.pointee.s.y {shouldRender = true}
//				}
//				guard shouldRender else {continue}
//				c.move(to: CGPoint(x: aexel.pointee.s.x, y: aexel.pointee.s.y))
//				c.addLine(to: CGPoint(x: neighbor.pointee.s.x, y: neighbor.pointee.s.y))
//			}
//		}
//		c.drawPath(using: .stroke)

//		let relaxed: Double = universe.pointee.relaxed;
		let relaxed: Double = 12;

		c.setStrokeColor(UIColor(rgb: 0xFFFFFF).cgColor)
		c.setFillColor(UIColor(rgb: 0xEEEEEE).alpha(0.5).cgColor);
		c.setLineWidth(0.5)

		for i in 0..<Int(universe.pointee.aexelCount) {
			let aexel = universe.pointee.aexels![i]!
			c.addEllipse(in: CGRect(x: aexel.pointee.s.x-relaxed/2, y: aexel.pointee.s.y-relaxed/2, width: relaxed, height: relaxed))
		}
		c.drawPath(using: .fillStroke)

		// Momentum Vectors
		c.setStrokeColor(UIColor.white.cgColor);
		for i in 0..<Int(universe.pointee.photonCount) {
			let photon = universe.pointee.photons![i]!
			c.move(to: CGPoint(x: photon.pointee.aexel.pointee.s.x, y: photon.pointee.aexel.pointee.s.y))
			c.addLine(to: CGPoint(x: photon.pointee.aexel.pointee.s.x+photon.pointee.v.x*7, y: photon.pointee.aexel.pointee.s.y+photon.pointee.v.y*7))
		}
		
		for i in 0..<Int(universe.pointee.hadronCount) {
			let hadron = universe.pointee.hadrons![i]!
			for quark in Mirror(reflecting: hadron.pointee.quarks).children.map({$0.value}) as! [Quark] {
				c.move(to: CGPoint(x: quark.aexel.pointee.s.x, y: quark.aexel.pointee.s.y))
				c.addLine(to: CGPoint(x: quark.aexel.pointee.s.x+quark.hadron.pointee.v.x*7*10/3, y: quark.aexel.pointee.s.y+quark.hadron.pointee.v.y*7*10/3))
			}
		}
		c.drawPath(using: .stroke)

		// Particles
		let radius: Double = 3
		c.setFillColor(UIColor(rgb: 0x00FF00).cgColor);
		for i in 0..<Int(universe.pointee.photonCount) {
			let photon = universe.pointee.photons![i]!
			c.addEllipse(in: CGRect(x: photon.pointee.aexel.pointee.s.x-radius, y: photon.pointee.aexel.pointee.s.y-radius, width: 2*radius, height: 2*radius))
		}
		c.drawPath(using: .fill)
		
		for i in 0..<Int(universe.pointee.hadronCount) {
			let hadron = universe.pointee.hadrons![i]!
			c.setFillColor(UIColor(rgb: hadron.pointee.anti == 0 ? 0x0000FF : 0xFF0000).cgColor);
			for quark in Mirror(reflecting: hadron.pointee.quarks).children.map({$0.value}) as! [Quark] {
				c.addEllipse(in: CGRect(x: quark.aexel.pointee.s.x-radius, y: quark.aexel.pointee.s.y-radius, width: 2*radius, height: 2*radius))
			}
			c.drawPath(using: .fill)
		}
		
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
