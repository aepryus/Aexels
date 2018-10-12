//
//  CellularView.swift
//  Aexels
//
//  Created by Joe Charlier on 1/6/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import UIKit
import OoviumLib

enum PanMode {
	case child
	case parent
}

struct Cell {
	var x: Int
	var y: Int
	
	init (_ x: Int, _ y: Int) {
		self.x = x
		self.y = y
	}
	static let zero = Cell(0,0)
}

final class CellularView: UIView {
	var engine: CellularEngine?

	var origin: Cell = Cell.zero
	
	var zoom: Int = 1
	var focus: CGRect?
	var guideOnOverride: Bool = false
	var zoomPoint: CGPoint? = nil
	var startPoint: CGPoint? = nil
	var panStart: CGPoint? = nil
	var panMode: PanMode? = nil
	
	weak var parentView: CellularView? = nil
	var zoomView: CellularView? {
		didSet {
			addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap)))
		}
	}
	
	var cellSize: Int {
		return Int(frame.size.width) / zoom
	}
	
	private var w: Int = 0
	private var h: Int = 0
	private var size: Int = 0
	private var data: [UInt8] = []
		
	var cells: Int = 0 {
		didSet {
			w = cells
			h = cells
			size = w*h*4
			data = [UInt8](repeating: 0, count: size)
		}
	}
	
	private var image: UIImage?

	private var r: [UInt8]!
	private var g: [UInt8]!
	private var b: [UInt8]!
	private var a: [UInt8]!
	
	init() {
		super.init(frame: CGRect.zero)
		backgroundColor = UIColor.clear
		addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(onPan)))
	}
	override init (frame: CGRect) {
		w = Int(frame.size.width)
		h = Int(frame.size.height)
		size = w*h*4
		data = [UInt8](repeating: 0, count: size)

		super.init(frame: frame)
		backgroundColor = UIColor.clear
	}
	required init? (coder aDecoder: NSCoder) {fatalError()}
	
	func clear() {
		image = nil
	}
	func configure(auto: Auto) {
		r = [UInt8](repeating: 0, count: auto.states.count)
		g = [UInt8](repeating: 0, count: auto.states.count)
		b = [UInt8](repeating: 0, count: auto.states.count)
		a = [UInt8](repeating: 0, count: auto.states.count)
		
		for i in 0..<auto.states.count {
			let color = OOColor(rawValue: auto.states[i].color)!.uiColor
			let comps: [CGFloat] = color.cgColor.components!
			r[i] = UInt8(comps[0] * 255)
			g[i] = UInt8(comps[1] * 255)
			b[i] = UInt8(comps[2] * 255)
			a[i] = UInt8(comps[3] * 255)
		}
	}
	func tic() {
		guard let engine = engine else {return}
		
		let cw: Int = Screen.iPad ? Int(432*s) : Int(335*s)
		let x: Int = Int(origin.x)
		let y: Int = Int(origin.y)
		let m: Int = w*4
		var n: Int = 0
		
		for j in y..<y+h/zoom {
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
		
		let provider: CGDataProvider = CGDataProvider(dataInfo: nil, data: &data, size: size, releaseData: {(info: UnsafeMutableRawPointer?, data: UnsafeRawPointer, size: Int) ->() in })!
		let space: CGColorSpace = CGColorSpaceCreateDeviceRGB()
		let cgImage: CGImage = CGImage(width: w, height: h, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: w*4, space: space, bitmapInfo: CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue), provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
		
		image = UIImage(cgImage: cgImage)
		
		if focus != nil && (engine.guideOn || guideOnOverride) {
			UIGraphicsBeginImageContext(image!.size)
			image?.draw(at: CGPoint.zero)
			let c = UIGraphicsGetCurrentContext()
			c?.setStrokeColor(UIColor.white.cgColor)
			c?.stroke(focus!, width: 1)
			self.image = UIGraphicsGetImageFromCurrentImageContext();
			UIGraphicsEndImageContext();
		}
		
		DispatchQueue.main.async {
			self.setNeedsDisplay()
		}
	}
	
	func pointFrom (cell: Cell) -> CGPoint {
		return CGPoint(x: (cell.x-origin.x)*zoom, y: (cell.y-origin.y)*zoom)
	}
	func cellFrom (point: CGPoint) -> Cell {
		return Cell(Int(point.x)/zoom+origin.x, Int(point.y)/zoom+origin.y)
	}
	func zoom(at point: CGPoint) {
		zoomPoint = point
		let cell = cellFrom(point: point)
		
		let cs = cellSize
		let zcs = zoomView!.cellSize
		
		let x: Int = min(max(cell.x-zcs/2, self.origin.x) , self.origin.x+cs-zcs)
		let y: Int = min(max(cell.y-zcs/2, self.origin.y) , self.origin.y+cs-zcs)
		let origin = Cell(x, y)
		let oP = pointFrom(cell: origin)
		
		focus = CGRect(x: oP.x, y: oP.y, width: CGFloat(zcs*zoom), height: CGFloat(zcs*zoom))
		zoomPoint = CGPoint(x: focus!.midX, y: focus!.midY)
		zoomView!.origin = origin
		if zoomView!.engine == nil, let engine = engine {
			engine.addView(zoomView!)
			zoomView?.configure(auto: engine.auto)
		}
		if zoomView!.zoomView != nil {
			let a = zoomView!.width/2
			zoomView!.zoom(at: CGPoint(x: a, y: a))
		}
		
		if !Aexels.timer.running {
			tic()
			if zoomView!.zoomView == nil {zoomView!.tic()}
		}
	}
	
// Events ==========================================================================================
	@objc func onTap(gesture: UITapGestureRecognizer) {
		let point = gesture.location(in: self)
		zoom(at: point)
	}
	@objc func onPan(gesture: UIPanGestureRecognizer) {
		let point = gesture.location(in: self)
		
		if panMode == nil {
			if parentView == nil || (zoomView != nil && engine!.guideOn && focus!.contains(point)) {
				panMode = .child
			} else if parentView != nil {
				panMode = .parent
			}
		}
		
		if panMode! == .child {
			if gesture.state == .began {guideOnOverride = true}
			else if gesture.state == .ended {guideOnOverride = false}
			zoom(at: point)
		} else if let parentView = parentView {
			if gesture.state == .began {
				parentView.startPoint = parentView.zoomPoint
				panStart = point
				parentView.guideOnOverride = true
			}
			else if gesture.state == .ended {parentView.guideOnOverride = false}
			parentView.zoom(at: (parentView.startPoint! - (point - panStart!)/2))
		}
		
		if gesture.state == .ended {panMode = nil}
	}
	
// UIView ==========================================================================================
	override func draw (_ rect: CGRect) {
		if let image = image {
			image.draw(at: CGPoint.zero)
		}
	}
}
