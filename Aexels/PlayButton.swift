//
//  PlayButton.swift
//  Aexels
//
//  Created by Joe Charlier on 1/7/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import OoviumLib
import UIKit

class PlayButton: AXButton {
	var onPlay:()->()
	var onStop:()->()
	
	private let color: UIColor
	
	var playing: Bool = false
	
	override init() {
		self.onPlay = {}
		self.onStop = {}
		color = UIColor(red: 0.99, green: 0.99, blue: 0.99, alpha: 1)
		super.init()
		addAction(for: .touchUpInside) { 
			self.playing = !self.playing
			self.setNeedsDisplay()
			if self.playing {
				self.onPlay()
			} else {
				self.onStop()
			}
		}
	}
	required init? (coder aDecoder: NSCoder) {fatalError()}
	
	func play() {
		if playing {return}
		playing = true
		self.setNeedsDisplay()
		onPlay()
	}
	func stop() {
		if !playing {return}
		playing = false
		self.setNeedsDisplay()
		onStop()
	}
	
// UIView ==========================================================================================
	override func draw(_ rect: CGRect) {
		let ir: CGFloat = 11*s
		
		let path = CGMutablePath()
		
		if !playing {
			let p: CGFloat = 3*s
			let ph: CGFloat = 12*s
			let pl: CGFloat = 6*s
			let pr: CGFloat = 11*s
			
			let x4: CGFloat = frame.size.width/2
			let ix10: CGFloat = CGFloat(x4-pl)
			let ix11: CGFloat = x4+pr
			let iy1: CGFloat = p
			let iy2: CGFloat = iy1+ir
			let iy6: CGFloat = iy2-ph
			let iy9: CGFloat = iy2+ph
			let iy7: CGFloat = iy6+ph*pl/(pr+pl)
			let iy8: CGFloat = iy9-ph*pl/(pr+pl)
			
			path.move(to: CGPoint(x: ix10, y: iy2))
			path.addArc(tangent1End: CGPoint(x: ix10, y: iy6), tangent2End: CGPoint(x: x4, y: iy7), radius: 2, transform: .identity)
			path.addArc(tangent1End: CGPoint(x: ix11, y: iy2), tangent2End: CGPoint(x: x4, y: iy8), radius: 2, transform: .identity)
			path.addArc(tangent1End: CGPoint(x: ix10, y: iy9), tangent2End: CGPoint(x: ix10, y: iy2), radius: 2, transform: .identity)
			path.closeSubpath()
			
		} else {
			let p: CGFloat = 3*s
			let ph: CGFloat = 9*s
			let sp: CGFloat = 2*s
			let pw: CGFloat = 3*s
			
			let x4: CGFloat = frame.size.width/2
			let ix12: CGFloat = x4-sp
			let ix11: CGFloat = ix12-pw
			let ix10: CGFloat = ix11-pw
			let ix13: CGFloat = x4+sp
			let ix14: CGFloat = ix13+pw
			let ix15: CGFloat = ix14+pw
			let iy2: CGFloat = p+ir
			let iy6: CGFloat = iy2-ph
			let iy9: CGFloat = iy2+ph
			let r: CGFloat = 2*s
			
			path.move(to: CGPoint(x: ix10, y: iy2))
			path.addArc(tangent1End: CGPoint(x: ix10, y: iy6), tangent2End: CGPoint(x: ix11, y: iy6), radius: r, transform: .identity)
			path.addArc(tangent1End: CGPoint(x: ix12, y: iy6), tangent2End: CGPoint(x: ix12, y: iy2), radius: r, transform: .identity)
			path.addArc(tangent1End: CGPoint(x: ix12, y: iy9), tangent2End: CGPoint(x: ix11, y: iy9), radius: r, transform: .identity)
			path.addArc(tangent1End: CGPoint(x: ix10, y: iy9), tangent2End: CGPoint(x: ix10, y: iy2), radius: r, transform: .identity)
			path.closeSubpath()

			path.move(to: CGPoint(x: ix13, y: iy2))
			path.addArc(tangent1End: CGPoint(x: ix13, y: iy6), tangent2End: CGPoint(x: ix14, y: iy6), radius: r, transform: .identity)
			path.addArc(tangent1End: CGPoint(x: ix15, y: iy6), tangent2End: CGPoint(x: ix15, y: iy2), radius: r, transform: .identity)
			path.addArc(tangent1End: CGPoint(x: ix15, y: iy9), tangent2End: CGPoint(x: ix14, y: iy9), radius: r, transform: .identity)
			path.addArc(tangent1End: CGPoint(x: ix13, y: iy9), tangent2End: CGPoint(x: ix13, y: iy2), radius: r, transform: .identity)
			path.closeSubpath()
		}
		
		let stroke = UIColor.white
		let fill = UIColor(white: 0.5, alpha: 1)
		let c = UIGraphicsGetCurrentContext()!
		c.addPath(path)
		c.setFillColor(fill.cgColor)
		c.setStrokeColor(stroke.cgColor)
		c.setLineWidth(2)
		c.drawPath(using: .fillStroke)
	}
}
