//
//  KinematicsExplorer.swift
//  Aexels
//
//  Created by Joe Charlier on 1/5/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import OoviumLib
import UIKit

class KinematicsExplorer: Explorer {
	var message: MessageLimbo!
	let universe = Limbo()
	
	let zoneA = Limbo()
	let zoneB = Limbo()
	let zoneC = Limbo()
	let zoneD = Limbo()
	
	let newtonianView: NewtownianView
	let kinematicsView: KinematicsView
	
	var universePicker: SliderView!
	let playButton: PlayButton
	let aetherVector = VectorView()
	let loopVector = VectorView()
	let netButton = NetButton()
	let expAButton = ExpButton(name: "Exp\nA")
	let expBButton = ExpButton(name: "Exp\nB")
	let swapper = Limbo()
	let swapButton = SwapButton()
	let close = LimboButton(title: "Close")
	let aetherLabel = UILabel()
	let loopLabel = UILabel()

	var first = [Limbo]()
	var second = [Limbo]()
	var isFirst: Bool = true

	init(parent: UIView) {
		
		newtonianView = NewtownianView()
		kinematicsView = KinematicsView()
		
		playButton = PlayButton()
		
		super.init(parent: parent, name: "Kinematics", key: "Kinematics", canExplore: true)
	}
	
	
	
// Events ==========================================================================================
	override func onOpen() {
		if universePicker.pageNo == 0 {
			Aexels.timer.configure(interval: 1.0/60.0) {
				self.newtonianView.tic()
			}
		} else {
			Aexels.timer.configure(interval: 1.0/60.0) {
				self.kinematicsView.tic()
			}
		}
	}
	override func onOpened() {
		playButton.play()
	}
	override func onClose() {
		playButton.stop()
		if Screen.iPhone {
			swapButton.resetView()
			limbos = first + [swapper, close]
		}
	}

// Explorer ========================================================================================
	override func createLimbos() {
		
		kinematicsView.onTic = { [weak self] (velocity: V2) in
			guard let me = self else {return}
			me.loopVector.vector = velocity
		}
		newtonianView.onTic = { [weak self] (velocity: V2) in
			guard let me = self else {return}
			me.loopVector.vector = velocity
		}
		
		// Universe
		universePicker = SliderView { [weak self] (page: String) in
			guard let me = self else {return}
			
			let cs: Double = 30*cos(Double.pi/6)
			
			if page == "Universe" {
				me.kinematicsView.stop()
				
				Aexels.timer.configure(interval: 1.0/60.0) {
					self?.newtonianView.tic()
				}
				
				me.newtonianView.x.x = me.kinematicsView.Xl.x
				me.newtonianView.x.y = me.kinematicsView.Xl.y
				me.newtonianView.v.x = me.kinematicsView.Va.x + me.kinematicsView.Vl.x*2*cs
				me.newtonianView.v.y = -(me.kinematicsView.Va.y + me.kinematicsView.Vl.y*2*cs)
				me.loopVector.max = 10
				
				me.newtonianView.setNeedsDisplay()
				if me.playButton.playing {
					me.newtonianView.play()
				}
			} else {
				me.newtonianView.stop()
				
				Aexels.timer.configure(interval: 1.0/60.0) {
					self?.kinematicsView.tic()
				}
				
				me.kinematicsView.moveTo(v: me.newtonianView.x)
				me.kinematicsView.Vl.x = (me.newtonianView.v.x - me.kinematicsView.Va.x)/(2*cs)
				me.kinematicsView.Vl.y = (-me.newtonianView.v.y - me.kinematicsView.Va.y)/(2*cs)
				me.loopVector.max = 10/(2*cs)
				
				me.kinematicsView.setNeedsDisplay()
				if me.playButton.playing {
					me.kinematicsView.play()
				}
			}
			UIView.animate(withDuration: 0.2, animations: {
				me.universe.content?.alpha = 0
				if page == "Universe X" {
					me.aetherLabel.alpha = 1
					me.aetherVector.alpha = 1
					me.netButton.alpha = 1
					me.expAButton.alpha = 1
					me.expBButton.alpha = 1
				} else {
					me.aetherLabel.alpha = 0
					me.aetherVector.alpha = 0
					me.netButton.alpha = 0
					me.expAButton.alpha = 0
					me.expBButton.alpha = 0
				}
			}, completion: { (canceled: Bool) in
				if page == "Universe" {
					me.universe.content = me.newtonianView
				} else {
					me.universe.content = me.kinematicsView
				}
				me.universe.content?.alpha = 0
				UIView.animate(withDuration: 0.2, animations: {
					me.universe.content?.alpha = 1
				})
			})
		}
		universe.content = kinematicsView
		
		// Controls
		
		universePicker.pages = ["Universe", "Universe X"]
		universePicker.snapToPageNo(1)
		
		playButton.onPlay = {
			self.kinematicsView.play()
		}
		playButton.onStop = {
			self.kinematicsView.stop()
		}
		
		aetherVector.max = 5
		aetherVector.onTap = { [weak self] (vector: V2) in
			guard let me = self else {return}
			me.kinematicsView.Va = vector
			me.expAButton.activated = false
			me.expBButton.activated = false
		}
		
		loopVector.max = 10/(2*30*cos(Double.pi/6))
		loopVector.onTap = { [weak self] (vector: V2) in
			guard let me = self else {return}
			if me.universePicker.pageNo == 0 {
				me.newtonianView.v = V2(vector.x, -vector.y)
			} else {
				me.kinematicsView.Vl = vector
			}
			me.expAButton.activated = false
			me.expBButton.activated = false
		}
		
		aetherLabel.text = "Aether"
		aetherLabel.font = UIFont.aexel(size: 16*s)
		aetherLabel.textColor = UIColor.white
		aetherLabel.textAlignment = .center
		
		loopLabel.text = "Object"
		loopLabel.font = UIFont.aexel(size: 16*s)
		loopLabel.textColor = UIColor.white
		loopLabel.textAlignment = .center
		
		expAButton.activated = true
		expAButton.addAction(for: .touchUpInside) {[weak self] in
			guard let me = self else {return}
			
			let q = 0.3
			let sn = sin(Double.pi/6)
			let cs = cos(Double.pi/6)
			
			me.kinematicsView.Xa = V2(0, 0)
			me.kinematicsView.Va = V2(0.5, -1.5)
			me.kinematicsView.Vl = V2(-cs*q/2, -sn*q/4)
			
			me.kinematicsView.x = 3
			me.kinematicsView.y = 3
			me.kinematicsView.o = 1

			me.aetherVector.vector = me.kinematicsView.Va
			me.loopVector.vector = me.kinematicsView.Vl
			
			me.expAButton.activated = true
			me.expBButton.activated = false
		}
		
		expBButton.addAction(for: .touchUpInside) {[weak self] in
			guard let me = self else {return}
			me.kinematicsView.Xa = V2(0, 0)
			me.kinematicsView.Va = V2(0, -1)
			me.kinematicsView.Vl = V2(0, 0)
			
			if Screen.iPhone {
				me.kinematicsView.x = 1
				me.kinematicsView.y = 0
				me.kinematicsView.o = 1
			} else {
				me.kinematicsView.x = 3
				me.kinematicsView.y = 0
				me.kinematicsView.o = 0
			}
			
			me.aetherVector.vector = me.kinematicsView.Va
			me.loopVector.vector = me.kinematicsView.Vl
			
			me.expAButton.activated = false
			me.expBButton.activated = true
		}

		netButton.addAction(for: .touchUpInside) { [weak self] in
			guard let me = self else {return}
			me.kinematicsView.aetherVisible = !me.kinematicsView.aetherVisible
			me.netButton.on = me.kinematicsView.aetherVisible
			me.netButton.setNeedsDisplay()
		}
		
		// Message
		message = MessageLimbo()
		message.key = "KinematicsLab"
		
		// Close
		close.alpha = 0
		close.addAction(for: .touchUpInside) { [weak self] in
			guard let me = self else {return}
			me.isFirst = true
			me.closeExplorer()
			Aexels.nexus.brightenNexus()
		}

		// Swapper =========================
		if Screen.iPhone {
			swapButton.addAction(for: .touchUpInside) { [weak self] in
				guard let me = self else {return}
				me.swapButton.rotateView()
				if me.isFirst {
					me.isFirst = false
					me.dimLimbos(me.first)
					me.brightenLimbos(me.second)
					me.limbos = [me.swapper] + me.second + [me.close]
				} else {
					me.isFirst = true
					me.dimLimbos(me.second)
					me.brightenLimbos(me.first)
					me.limbos = [me.swapper] + me.first + [me.close]
				}
				me.swapper.removeFromSuperview()
				me.parent.addSubview(me.swapper)
				me.close.removeFromSuperview()
				me.parent.addSubview(me.close)
			}
			swapper.content = swapButton
			limbos.append(swapper)
		}
		
		zoneA.addSubview(playButton)
		zoneA.addSubview(netButton)
		
		zoneB.addSubview(universePicker)
		
		zoneC.addSubview(aetherVector)
		zoneC.addSubview(loopVector)
		zoneC.addSubview(aetherLabel)
		zoneC.addSubview(loopLabel)
		
		zoneD.addSubview(expAButton)
		zoneD.addSubview(expBButton)

		first = [message]
		second = [universe, zoneA, zoneB, zoneC, zoneD]
		
		if Screen.iPhone {
			brightenLimbos(first)
			limbos = [swapper] + first + [close]
		} else {
			limbos = [swapper, universe, zoneA, zoneB, zoneC, zoneD, message, close]
		}
	}
	override func layout375x667() {
		let size = UIScreen.main.bounds.size
		
		let h = size.height - 110*s - 20*s
		let w = size.width - 10*s
		let ch = size.height - 20*s - h - 15*2*s + 1*s
		let vw: CGFloat = 72*s


		universe.frame = CGRect(x: 5*s, y: 20*s, width: w, height: w)

		zoneA.frame = CGRect(x: 5*s, y: universe.bottom, width: 144*s, height: 667*s-universe.bottom-60*s)
		zoneB.frame = CGRect(x: 61*s, y: (667-108-5)*s, width: (375-139-56-10)*s, height: 108*s)
		zoneC.frame = CGRect(x: 5*s+144*s, y: universe.bottom, width: 375*s-5*s-zoneA.right, height: 120*s)
		zoneD.frame = CGRect(x: 5*s+144*s, y: zoneC.bottom, width: zoneC.width, height: 667*s-universe.bottom-5*s-zoneC.height-60*s)

		zoneA.cutouts[.bottomRight] = Cutout(width: zoneA.width-60*s+5*s, height: zoneB.height-60*s+5*s)
		zoneA.renderPaths()
		
		zoneB.renderPaths()

		zoneC.renderPaths()
		
		zoneD.cutouts[.bottomLeft] = Cutout(width: zoneD.width-139*s, height: zoneB.height-60*s)
		zoneD.renderPaths()
		
		playButton.top(offset: UIOffset(horizontal: 0, vertical: 32*s), size: CGSize(width: 48*s, height: 30*s))
		netButton.top(offset: UIOffset(horizontal: 0, vertical: playButton.bottom+20*s), size: CGSize(width: 48*s, height: 48*s))

		let dx: CGFloat = 32*s
		loopVector.topRight(offset: UIOffset(horizontal: -dx, vertical: 32*s), size: CGSize(width: vw, height: vw))
		aetherVector.topLeft(offset: UIOffset(horizontal: dx, vertical: 32*s), size: CGSize(width: vw, height: vw))
		loopLabel.topLeft(offset: UIOffset(horizontal: loopVector.left, vertical: loopVector.top-20*s), size: CGSize(width: vw, height: 16*s))
		aetherLabel.topLeft(offset: UIOffset(horizontal: aetherVector.left, vertical: aetherVector.top-20*s), size: CGSize(width: vw, height: 16*s))
		
		expAButton.left(offset: UIOffset(horizontal: 108*s, vertical: 0), size: CGSize(width: 40*s, height: 50*s))
		expBButton.left(offset: UIOffset(horizontal: expAButton.right+10*s, vertical: 0), size: CGSize(width: 40*s, height: 50*s))

		universePicker.center(offset: UIOffset.zero, size: CGSize(width: 120*s, height: ch-12*s))

		swapper.frame = CGRect(x: 5*s, y: (667-56-5)*s, width: 56*s, height: 56*s)

		message.frame = CGRect(x: 5*s, y: 20*s, width: w, height: size.height-20*s-5*s)
		message.cutouts[Position.bottomRight] = Cutout(width: 139*s, height: 60*s)
		message.cutouts[Position.bottomLeft] = Cutout(width: 56*s, height: 56*s)
		message.renderPaths()

		close.frame = CGRect(x: (375-5-139)*s, y: (667-5-60)*s, width: 139*s, height: 60*s)
	}
	override func layout1024x768() {
		let size = UIScreen.main.bounds.size
		
		let p: CGFloat = 5*s
		let uw: CGFloat = size.height - 110*s - 20*s
		let mw: CGFloat = size.width - uw - 2*p
		let ch: CGFloat = size.height - uw - 20*s
		
		universe.frame = CGRect(x: p, y: 20*s, width: uw, height: uw)
		
		message.frame = CGRect(x: universe.right, y: 20*s, width: mw, height: size.height-20*s)
		message.cutouts[.bottomRight] = Cutout(width: 176*s, height: 110*s)
		message.renderPaths()
		message.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 70*s, right: 0)

		zoneB.frame = CGRect(x: 5*s, y: universe.bottom, width: 160*s, height: ch)
		zoneA.frame = CGRect(x: zoneB.right, y: universe.bottom, width: 150*s, height: ch)
		zoneC.frame = CGRect(x: zoneA.right, y: universe.bottom, width: 180*s, height: ch)
		zoneD.frame = CGRect(x: zoneC.right, y: universe.bottom, width: universe.width-zoneB.width-zoneA.width-zoneC.width, height: ch)

		universePicker.center(offset: UIOffset.zero, size: CGSize(width: 120*s, height: 67*s))
		
		playButton.center(offset: UIOffset(horizontal: -35*s, vertical: 0), size: CGSize(width: 50*s, height: 30*s))
		netButton.center(offset: UIOffset(horizontal: 27*s, vertical: 0), size: CGSize(width: 48*s, height: 48*s))

		aetherVector.left(offset: UIOffset(horizontal: 21*s, vertical: 10*s), size: CGSize(width: 63*s, height: 63*s))
		aetherLabel.left(offset: UIOffset(horizontal: aetherVector.left, vertical: -32*s), size: CGSize(width: aetherVector.width, height: 16*s))
		loopVector.left(offset: UIOffset(horizontal: aetherVector.right+12, vertical: 10*s), size: CGSize(width: 63*s, height: 63*s))
		loopLabel.left(offset: UIOffset(horizontal: loopVector.left, vertical: -32*s), size: CGSize(width: loopVector.width, height: 16*s))

		expAButton.center(offset: UIOffset(horizontal: -26*s, vertical: 0), size: CGSize(width: 40*s, height: 50*s))
		expBButton.center(offset: UIOffset(horizontal: 26*s, vertical: 0), size: CGSize(width: 40*s, height: 50*s))

		close.frame = CGRect(x: size.width-p-176*s, y: size.height-110*s, width: 176*s, height: 110*s)
	}
}
