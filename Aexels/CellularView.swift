//
//  CellularView.swift
//  Aexels
//
//  Created by Joe Charlier on 1/6/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import UIKit
import OoviumLib

final class CellularView: UIView {
	var engine: CellularEngine!
	
	var origin: CGPoint = CGPoint.zero
	var zoom: Int = 1
	var focus: CGRect = CGRect.zero
	var guideOn: Bool = false
	
	private let w: Int
	private let h: Int
	private let size: Int
	
	private var data: [UInt8]
	private var image: UIImage?

	private var r: [UInt8]!
	private var g: [UInt8]!
	private var b: [UInt8]!
	private var a: [UInt8]!
	
	override init (frame: CGRect) {
		w = Int(frame.size.width)
		h = Int(frame.size.height)
		size = w*h*4
		data = [UInt8](repeating: 0, count: size)

		super.init(frame: frame)
		backgroundColor = UIColor.clear
		
	}
	required init? (coder aDecoder: NSCoder) {fatalError()}
	
	func clear () {
		image = nil
	}
	func configure (auto: Auto) {
		r = [UInt8](repeating: 0, count: auto.states.count)
		g = [UInt8](repeating: 0, count: auto.states.count)
		b = [UInt8](repeating: 0, count: auto.states.count)
		a = [UInt8](repeating: 0, count: auto.states.count)
		
		for i in 0..<auto.states.count {
			let color = OOColor(rawValue: auto.states[i].color)!.toUIColor()
			let comps: [CGFloat] = color.cgColor.components!
			r[i] = UInt8(comps[0] * 255)
			g[i] = UInt8(comps[1] * 255)
			b[i] = UInt8(comps[2] * 255)
			a[i] = UInt8(comps[3] * 255)
		}
	}
	func tic () {
		let cw: Int = 432
		let x: Int = Int(origin.x)
		let y: Int = Int(origin.y)
		let m: Int = w*4
		var n: Int = 0
		
		for j in y..<h/zoom {
			for i in x..<x+w/zoom {
				for q in 0..<zoom {
					for p in 0..<zoom {
						let state = Int(engine.cells[i+j*cw].a.x)
						data[n+0+4*p+m*q] = r[state]
						data[n+1+4*p+m*q] = g[state]
						data[n+2+4*p+m*q] = b[state]
						data[n+3+4*p+m*q] = a[state]
					}
				}
				n += 4 * zoom
			}
			n += m * (zoom - 1)
		}
		
		let provider: CGDataProvider = CGDataProvider(dataInfo: nil, data: &data, size: size, releaseData: {(info: UnsafeMutableRawPointer?, data: UnsafeRawPointer, size: Int) -> () in })!
		let space: CGColorSpace = CGColorSpaceCreateDeviceRGB()
		let cgImage: CGImage = CGImage(width: w, height: h, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: w*4, space: space, bitmapInfo: CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue), provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
		
		image = UIImage(cgImage: cgImage)
		
		DispatchQueue.main.async {
			self.setNeedsDisplay()
		}
	}
	
// UIView ==========================================================================================
	override func draw (_ rect: CGRect) {
		if let image = image {
			image.draw(at: CGPoint.zero)
		}
	}
}
