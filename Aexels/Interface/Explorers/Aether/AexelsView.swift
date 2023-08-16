//
//  AetherView.swift
//  Aexels
//
//  Created by Joe Charlier on 6/16/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import Acheron
import OoviumEngine
import OoviumKit
import UIKit

class AexelsView: UIView {
	var universe: UnsafeMutablePointer<Universe>
	
	private var queue: DispatchQueue = DispatchQueue(label: "aexelsView")
	var renderMode: RenderMode = .started
	private var image: UIImage?
	private var vw: Int = 0

	init() {
		let height: CGFloat = Screen.height - Screen.safeTop - Screen.safeBottom
		let s = height / 748
		let side = Double(height - 30*s)
		vw = Int(side)
		let q: Double = Double(Screen.iPhone ? 100*s : 150*s)
		universe = AXUniverseCreate(Double(vw), Double(vw), q, q*2, 0.1, 12, 0, 0)
		super.init(frame: CGRect.zero)
		backgroundColor = UIColor.clear

		addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap(_:))))
        addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(onPan(_:))))

        let gesture = UITapGestureRecognizer(target: self, action: #selector(onDoubleTap(_:)))
        gesture.numberOfTapsRequired = 2
        addGestureRecognizer(gesture)
    }
	required init?(coder aDecoder: NSCoder) {fatalError()}
	deinit {
		AXUniverseRelease(universe)
	}
	
	func play() {
		Aexels.sync.link.preferredFramesPerSecond = 60
		Aexels.sync.start()
	}
	func stop() {
		Aexels.sync.stop()
	}
	private func reset(next: UnsafeMutablePointer<Universe>) {
		AXUniverseRelease(universe)
		universe = next
		self.renderMode = .started
		self.renderImage()
		setNeedsDisplay()
	}
	func experimentA() {
		let q: Double = Double(Screen.iPhone ? 100*s : 150*s)
		reset(next: AXUniverseCreate(Double(width), Double(height), q, q*2, 0.1, 12, 0, 0))
	}
	func experimentB() {
		let q: Double = Double(Screen.iPhone ? 60*s : 80*s)
		reset(next: AXUniverseCreate(Double(width), Double(height), q, q*2, 0.1, 60, 0, 0))
	}
	func experimentC() {
		let q: Double = Double(Screen.iPhone ? 24*s : 32*s)
		reset(next: AXUniverseCreate(Double(width), Double(height), q, q*2, 0.1, 360, 0, 0))
	}
	func experimentD() {
		let q: Double = Double(Screen.iPhone ? 24*s : 32*s)
		let universe: UnsafeMutablePointer<Universe> = AXUniverseCreate(Double(width), Double(height), q, q*2, 0.1, 360, 0, 0)
		universe.pointee.gol = 1
		reset(next: universe)
	}
    func experimentE() {
        let q: Double = Double(Screen.iPhone ? 50*s : 72*s)
        reset(next: AXUniverseCreateE(Double(width), Double(height), q))
    }
    func experimentF() {
        let q: Double = Double(Screen.iPhone ? 100*s : 150*s)
        reset(next: AXUniverseCreateF(Double(width), Double(height), q))
    }
    func experimentG() {
        let q: Double = Double(Screen.iPhone ? 100*s : 150*s)
        reset(next: AXUniverseCreateG(Double(width), Double(height), q))
    }
    func experimentH() {
        let q: Double = Double(Screen.iPhone ? 100*s : 150*s)
        reset(next: AXUniverseCreateH(Double(width), Double(height), q))
    }
    func experimentI() {
        let q: Double = Double(Screen.iPhone ? 50*s : 72*s)
        reset(next: AXUniverseCreateI(Double(width), Double(height), q))
    }
    func experimentJ() {
        let q: Double = Double(Screen.iPhone ? 50*s : 72*s)
        reset(next: AXUniverseCreateJ(Double(width), Double(height), q))
    }

	func renderImage() {
		guard renderMode == .started else {return}
		renderMode = .rendering
		
		UIGraphicsBeginImageContext(bounds.size)
		let c = UIGraphicsGetCurrentContext()!

//		for i in 0..<Int(universe.pointee.hadronCount) {
//			let hadron = universe.pointee.hadrons![i]!
//			let q1: CGPoint = CGPoint(x: hadron.pointee.quarks.0.aexel.pointee.s.x, y: hadron.pointee.quarks.0.aexel.pointee.s.y)
//			let q2: CGPoint = CGPoint(x: hadron.pointee.quarks.1.aexel.pointee.s.x, y: hadron.pointee.quarks.1.aexel.pointee.s.y)
//			let q3: CGPoint = CGPoint(x: hadron.pointee.quarks.2.aexel.pointee.s.x, y: hadron.pointee.quarks.2.aexel.pointee.s.y)
//			let center = (q1 + q2 + q3)/3
//			c.move(to: center+(q1-center)*1.3)
//			c.addLine(to: center+(q2-center)*1.3)
//			c.addLine(to: center+(q3-center)*1.3)
//			c.closePath()
//			c.setFillColor(UIColor(rgb: hadron.pointee.anti == 0 ? 0x0000FF : 0xFF0000).tint(0.5).alpha(0.5).cgColor);
//			c.setStrokeColor(UIColor(rgb: hadron.pointee.anti == 0 ? 0x0000FF : 0xFF0000).tint(0.5).cgColor);
//			c.drawPath(using: .fillStroke)
//		}
		
		c.setStrokeColor(OOColor.lavender.uiColor.cgColor)

		for i in 0..<Int(universe.pointee.bondCount) {
			let bond = universe.pointee.bonds[i]
			guard bond.hot == 1 else {continue}
			c.move(to: CGPoint(x: bond.a.pointee.s.x, y: bond.a.pointee.s.y))
			c.addLine(to: CGPoint(x: bond.b.pointee.s.x, y: bond.b.pointee.s.y))
		}
		c.drawPath(using: .stroke)
		
//		let relaxed: Double = universe.pointee.relaxed;
		let relaxed: Double = 12;
		
		c.setLineWidth(0.5)
		if universe.pointee.gol == 0 {
			c.setStrokeColor(UIColor(rgb: 0xFFFFFF).cgColor)
			c.setFillColor(UIColor(rgb: 0xEEEEEE).alpha(0.5).cgColor);
			
			for i in 0..<Int(universe.pointee.aexelCount) {
				let aexel = universe.pointee.aexels![i]!
                guard aexel.pointee.stateC == 0 else { continue }
				c.addEllipse(in: CGRect(x: aexel.pointee.s.x-relaxed/2, y: aexel.pointee.s.y-relaxed/2, width: relaxed, height: relaxed))
			}
			c.drawPath(using: .fillStroke)
            
            let color1: UIColor = UIColor(rgb: 0x5CFF74).tint(0.2)
            c.setStrokeColor(color1.shade(0.7).cgColor)
            c.setFillColor(color1.cgColor);

            for i in 0..<Int(universe.pointee.aexelCount) {
                let aexel = universe.pointee.aexels![i]!
                guard aexel.pointee.stateC == 1 else { continue }
                c.addEllipse(in: CGRect(x: aexel.pointee.s.x-relaxed/2, y: aexel.pointee.s.y-relaxed/2, width: relaxed, height: relaxed))
            }
            c.drawPath(using: .fillStroke)


		} else {
			let color1: UIColor = UIColor(rgb: 0x5CFF74).tint(0.2)
			c.setStrokeColor(color1.shade(0.7).cgColor)
			c.setFillColor(color1.cgColor);
			
			for i in 0..<Int(universe.pointee.aexelCount) {
				let aexel = universe.pointee.aexels![i]!
				guard aexel.pointee.stateA == 1 else { continue }
				c.addEllipse(in: CGRect(x: aexel.pointee.s.x-relaxed/2, y: aexel.pointee.s.y-relaxed/2, width: relaxed, height: relaxed))
			}
			c.drawPath(using: .fillStroke)
		}

//		c.setStrokeColor(UIColor.orange.tint(0.5).cgColor)
//		for i in 0..<universe.pointee.sectorWidth {
//			c.move(to: CGPoint(x: Double(i)*universe.pointee.snapped*2, y: 0))
//			c.addLine(to: CGPoint(x: Double(i)*universe.pointee.snapped*2, y: Double(height)))
//		}
//		for i in 0..<universe.pointee.sectorWidth {
//			c.move(to: CGPoint(x: 0, y: Double(i)*universe.pointee.snapped*2))
//			c.addLine(to: CGPoint(x: Double(height), y: Double(i)*universe.pointee.snapped*2))
//		}
//		c.drawPath(using: .stroke)

		// Momentum Vectors
//		c.setStrokeColor(UIColor.white.cgColor);
//		for i in 0..<Int(universe.pointee.photonCount) {
//			let photon = universe.pointee.photons![i]!
//			c.move(to: CGPoint(x: photon.pointee.aexel.pointee.s.x, y: photon.pointee.aexel.pointee.s.y))
//			c.addLine(to: CGPoint(x: photon.pointee.aexel.pointee.s.x+photon.pointee.v.x*7, y: photon.pointee.aexel.pointee.s.y+photon.pointee.v.y*7))
//		}

//		for i in 0..<Int(universe.pointee.hadronCount) {
//			let hadron = universe.pointee.hadrons![i]!
//			for quark in Mirror(reflecting: hadron.pointee.quarks).children.map({$0.value}) as! [Quark] {
//				c.move(to: CGPoint(x: quark.aexel.pointee.s.x, y: quark.aexel.pointee.s.y))
//				c.addLine(to: CGPoint(x: quark.aexel.pointee.s.x+quark.hadron.pointee.v.x*7*10/3, y: quark.aexel.pointee.s.y+quark.hadron.pointee.v.y*7*10/3))
//			}
//		}
//		c.drawPath(using: .stroke)

		// Particles
//		let radius: Double = 3
//		c.setFillColor(UIColor(rgb: 0x00FF00).cgColor);
//		for i in 0..<Int(universe.pointee.photonCount) {
//			let photon = universe.pointee.photons![i]!
//			c.addEllipse(in: CGRect(x: photon.pointee.aexel.pointee.s.x-radius, y: photon.pointee.aexel.pointee.s.y-radius, width: 2*radius, height: 2*radius))
//		}
//		c.drawPath(using: .fill)

//		for i in 0..<Int(universe.pointee.hadronCount) {
//			let hadron = universe.pointee.hadrons![i]!
//			c.setFillColor(UIColor(rgb: hadron.pointee.anti == 0 ? 0x0000FF : 0xFF0000).cgColor);
//			for quark in Mirror(reflecting: hadron.pointee.quarks).children.map({$0.value}) as! [Quark] {
//				c.addEllipse(in: CGRect(x: quark.aexel.pointee.s.x-radius, y: quark.aexel.pointee.s.y-radius, width: 2*radius, height: 2*radius))
//			}
//			c.drawPath(using: .fill)
////			if hadron.pointee.anti == 0 && hadron.pointee.center != nil {
////				c.setFillColor(UIColor(rgb: 0xFF00FF).tint(0.2).cgColor);
////				c.addEllipse(in: CGRect(x: hadron.pointee.center.pointee.s.x-radius, y: hadron.pointee.center.pointee.s.y-radius, width: 2*radius, height: 2*radius))
////				c.drawPath(using: .fill)
////			}
//		}
		
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
	
	func tic() {
		queue.sync {
			AXUniverseTic(self.universe)
			self.renderMode = .started
			self.renderImage()
//			self.sampleFrameRate()
			DispatchQueue.main.async {
				self.setNeedsDisplay()
			}
		}
	}
	
// Events ==========================================================================================
	@objc func onTap(_ gesture: UITapGestureRecognizer) {
		let x = gesture.location(in: self)
        let v = Vector(x: x.x, y: x.y)
        let nearest: UnsafeMutablePointer<ICAexel>? = AXUniverseAexelNear(universe, v)
        if let nearest, AXVectorLength(AXVectorSub(v, nearest.pointee.s)) < 10*s {
            nearest.pointee.stateC = (nearest.pointee.stateC + 1) % 2
        } else {
            AXUniverseAddAexel(universe, v.x, v.y)
        }
	}

    @objc func onDoubleTap(_ gesture: UITapGestureRecognizer) {
        let x = gesture.location(in: self)
        let v = Vector(x: x.x, y: x.y)
        let nearest: UnsafeMutablePointer<ICAexel>? = AXUniverseAexelNear(universe, v)
        if let nearest, AXVectorLength(AXVectorSub(v, nearest.pointee.s)) < 10*s {
            AXUniverseRemoveAexel(universe, nearest)
        }
    }

    var holding: UnsafeMutablePointer<ICAexel>? = nil
    @objc func onPan(_ gesture: UIPanGestureRecognizer) {
        let x = gesture.location(in: self)
        let v = Vector(x: x.x, y: x.y)
        switch gesture.state {
            case .began:
                guard let nearest: UnsafeMutablePointer<ICAexel> = AXUniverseAexelNear(universe, v) else { break }
                guard AXVectorLength(AXVectorSub(v, nearest.pointee.s)) < 30*s else { break }
                holding = nearest
                holding?.pointee.stateC = 1
            case .ended:
                holding?.pointee.stateC = 0
                holding = nil
            case .changed:
                guard let holding else { break }
                holding.pointee.s = v
            default: break
        }
    }
	
// UIView ==========================================================================================
	override func draw(_ rect: CGRect) {
		guard let image = image else {return}
		image.draw(at: CGPoint.zero)
		renderMode = .displayed
	}
}
