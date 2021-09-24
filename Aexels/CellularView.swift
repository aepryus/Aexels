//
//  CellularView.swift
//  Aexels
//
//  Created by Joe Charlier on 1/6/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import Acheron
import OoviumKit
import UIKit

enum PanMode {
	case child
	case parent
}
enum RenderMode {
	case started
	case rendering
	case rendered
	case displayed
}

struct Cell {
	var x: Int
	var y: Int
	
	init(_ x: Int, _ y: Int) {
		self.x = x
		self.y = y
	}
	static let zero = Cell(0,0)
}

final class CellularView: UIView {
	var engine: CellularEngine!

	var origin: Cell = Cell.zero
	
	var states: Int = 2
	var zoom: Int = 1
	var focus: CGRect?
	var guideOnOverride: Bool = false
	var zoomPoint: CGPoint? = nil
	var startPoint: CGPoint? = nil
	var panStart: CGPoint? = nil
	var panMode: PanMode? = nil
	var renderMode: RenderMode = .started
	
	weak var parentView: CellularView? = nil
	var zoomView: CellularView? {
		didSet {
			addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap)))
		}
	}
	
	var cellSize: Int {
		return Int(frame.size.width) / zoom
	}
	
	private var vw: Int = 0					// view width
	private var cw: Int = 0					// cell width
	private var dw: Int = 0					// data width
	private var size: Int = 0				// total bytes = vw^2*4
	private var data: [UInt8] = []
	
	private var queue: DispatchQueue = DispatchQueue(label: "cellularView")

	var points: Int = 0 {
		didSet {
			vw = points
			let height = Screen.height - Screen.safeTop - Screen.safeBottom
			let s = height / 748
			if Screen.iPad { cw = Int(432*s) }
			else if Screen.iPhone { cw = Int(335*Screen.s) }
			else if Screen.mac { cw = Int(432*s) }
			dw = vw*4
			size = vw*vw*4
			data = [UInt8](repeating: 0, count: size)
		}
	}
	
	private let space: CGColorSpace = CGColorSpaceCreateDeviceRGB()
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
	required init?(coder aDecoder: NSCoder) {fatalError()}
	
	func clear() {
		image = nil
	}
	func configure(auto: Auto) {
		states = auto.states.count
		
		r = [UInt8](repeating: 0, count: states+1)
		g = [UInt8](repeating: 0, count: states+1)
		b = [UInt8](repeating: 0, count: states+1)
		a = [UInt8](repeating: 0, count: states+1)
		
		for i in 0..<states {
			let color = OOColor(rawValue: auto.states[i].color)!.uiColor
			let comps: [CGFloat] = color.cgColor.components!
			r[i] = UInt8(comps[0] * 255)
			g[i] = UInt8(comps[1] * 255)
			b[i] = UInt8(comps[2] * 255)
			a[i] = UInt8(comps[3] * 255)
		}
		
		// Out of Bounds
		let color = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
		let comps: [CGFloat] = color.cgColor.components!
		r[states] = UInt8(comps[0] * 255)
		g[states] = UInt8(comps[1] * 255)
		b[states] = UInt8(comps[2] * 255)
		a[states] = UInt8(comps[3] * 255)
	}
	func start() {
		renderMode = .started
	}
	func renderImage() {
		queue.sync {
			guard renderMode == .started else {return}
			renderMode = .rendering
			
			let sY = origin.y
			let eY = origin.y+vw/zoom
			let sX = origin.x
			let eX = origin.x+vw/zoom
			
			let dnX = 4*zoom
			let dnY = dw * (zoom - 1)
			
			AXDataLoad(&data, engine.cells, sX, eX, dnX, sY, eY, dnY, zoom, Double(states), &r, &g, &b, &a, cw, dw)
			
			let a: CFData? = CFDataCreate(nil, data, size)
			let b: CFData = a!
			let provider: CGDataProvider = CGDataProvider(data: b)!
			let cgImage = CGImage(width: vw, height: vw, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: vw*4, space: space, bitmapInfo: CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue), provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
			self.image = UIImage(cgImage: cgImage)
			
			if focus != nil && (engine.guideOn || guideOnOverride) {
				UIGraphicsBeginImageContext(image!.size)
				image!.draw(at: CGPoint.zero)
				let c = UIGraphicsGetCurrentContext()!
				c.setStrokeColor(UIColor.white.cgColor)
				c.stroke(focus!, width: 1)
				self.image = UIGraphicsGetImageFromCurrentImageContext()
				UIGraphicsEndImageContext()
			}
			renderMode = .rendered
		}
	}
	func flash() {
		start()
		renderImage()
		setNeedsDisplay()
	}
	
	func pointFrom(cell: Cell) -> CGPoint {
		return CGPoint(x: (cell.x-origin.x)*zoom, y: (cell.y-origin.y)*zoom)
	}
	func cellFrom(point: CGPoint) -> Cell {
		return Cell(Int(point.x)/zoom+origin.x, Int(point.y)/zoom+origin.y)
	}
	@discardableResult func zoom(at point: CGPoint, cascade: Bool = true, pushable: Bool = false) -> Cell? {
		guard let zoomView = zoomView else {fatalError()}
		
		let cell = cellFrom(point: point)
		
		let cs = cellSize
		let zcs = zoomView.cellSize
		
		var pushed: Cell? = nil
		if pushable, let parentView = parentView {
			var newX: Int = self.origin.x
			newX = min(newX, cell.x-zcs/2)
			newX = max(newX, cell.x+zcs/2-cs)
			var newY: Int = self.origin.y
			newY = min(newY, cell.y-zcs/2)
			newY = max(newY, cell.y+zcs/2-cs)
			
			if self.origin.x != newX || self.origin.y != newY {
				pushed = Cell(newX-self.origin.x, newY-self.origin.y)
				let point = parentView.pointFrom(cell: Cell(newX+cs/2, newY+cs/2))
				parentView.zoom(at: point, cascade: false)
			}
		}
		
		let x: Int = min(max(cell.x-zcs/2, self.origin.x) , self.origin.x+cs-zcs)
		let y: Int = min(max(cell.y-zcs/2, self.origin.y) , self.origin.y+cs-zcs)
		let origin = Cell(x, y)
		let oP = pointFrom(cell: origin)
		
		focus = CGRect(x: oP.x, y: oP.y, width: CGFloat(zcs*zoom), height: CGFloat(zcs*zoom))
		zoomPoint = CGPoint(x: focus!.midX, y: focus!.midY)
		zoomView.origin = origin
		if zoomView.zoomView != nil {
			if cascade {
				let a = zoomView.width/2
				zoomView.zoom(at: CGPoint(x: a, y: a))
			} else {
				zoomView.flash()
			}
		}
		
		flash()
		if zoomView.zoomView == nil {zoomView.flash()}
		
		return pushed
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
			else if gesture.state == .ended {
				parentView.guideOnOverride = false
				parentView.parentView?.guideOnOverride = false
			}
			if let delta = parentView.zoom(at: (parentView.startPoint! - (point - panStart!)/2), pushable: true) {
				parentView.parentView!.guideOnOverride = true
				parentView.startPoint = parentView.zoomPoint
				panStart = CGPoint(x: point.x-CGFloat(delta.x*2), y: point.y-CGFloat(delta.y*2))
			}
		}
		
		if gesture.state == .ended {panMode = nil}
	}
	
// UIView ==========================================================================================
	override func draw(_ rect: CGRect) {
		guard let image = image?.cgImage else {return}
		let c = UIGraphicsGetCurrentContext()!
		c.translateBy(x: 0, y: CGFloat(vw))
		c.scaleBy(x: 1, y: -1)
		c.draw(image, in: rect)
		renderMode = .displayed
	}
}
