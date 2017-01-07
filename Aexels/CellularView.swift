//
//  CellularView.swift
//  Aexels
//
//  Created by Joe Charlier on 1/6/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import UIKit

class CellularView: UIView {
	var cells = [Int]()
	
	var origin: CGPoint = CGPoint.zero
	var zoom: Int = 1
	var guideOn: Bool = false
	
	let w: Int
	let h: Int
	let size: Int
	
	var r: [Int8]!
	var g: [Int8]!
	var b: [Int8]!
	var a: [Int8]!
	
	var data: [Int8]
	
	private var image: UIImage?
	
	override init (frame: CGRect) {
		w = Int(frame.size.width)
		h = Int(frame.size.height)
		size = w*h
		data = [Int8](repeating: 0, count: size)

		super.init(frame: frame)
		backgroundColor = UIColor.clear
		
	}
	required init? (coder aDecoder: NSCoder) {fatalError()}
	
	func clear () {
		image = nil
	}
	
	func tic () {
		
		let cw: Int = 0
		
		let x: Int = Int(origin.x)
		let y: Int = Int(origin.y)
		let m: Int = w*4
		var n: Int = 0
		
		for j in y..<h/zoom {
			for i in x..<x+w/zoom {
				for q in 0..<zoom {
					for p in 0..<zoom {
						let state = cells[i+j*cw]
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
		let cgImage: CGImage = CGImage(width: w, height: h, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: w*4, space: space, bitmapInfo: [.byteOrder32Big,.alphaInfoMask], provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
		
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
