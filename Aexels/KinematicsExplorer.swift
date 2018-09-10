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
	let expAButton = UIButton()
	let expBButton = UIButton()
	let swapper = Limbo()
	let close = LimboButton(title: "Close")
	let aetherLabel = UILabel()
	let loopLabel = UILabel()

	var first = [Limbo]()
	var second = [Limbo]()
	var isFirst: Bool = true

	init(parent: UIView) {
		
		newtonianView = NewtownianView({ (momentum: V2) in
		})
		kinematicsView = KinematicsView()
		
		playButton = PlayButton()
		
		super.init(parent: parent, name: "Kinematics", key: "Kinematics", canExplore: true)
	}
	
// Events ==========================================================================================
	override func onOpened() {
		playButton.play()
	}
	override func onClose() {
		playButton.stop()
		if D.current().iPhone {
			limbos = first + [swapper, close]
		}
	}
	
// Explorer ========================================================================================
	override func createLimbos() {
		
		kinematicsView.onTic = { [weak self] (velocity: V2) in
			guard let me = self else {return}
			me.loopVector.vector = velocity
		}
		
		// Universe
		universePicker = SliderView { [weak self] (page: String) in
			guard let me = self else {return}
			
			let cs: Double = 30*cos(Double.pi/6)
			
			if page == "Universe" {
				me.kinematicsView.stop()
				
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
		limbos.append(universe)
		
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
			print("\(vector)")
			guard let me = self else {return}
			me.kinematicsView.Va = vector
		}
		
		loopVector.onTap = { [weak self] (vector: V2) in
			guard let me = self else {return}
			if me.universePicker.pageNo == 0 {
				me.newtonianView.v = vector
			} else {
				me.loopVector.max = 10/(2*30*cos(Double.pi/6))
				me.kinematicsView.Vl = vector
			}

		}		
		
		aetherLabel.text = "Aether"
		aetherLabel.font = UIFont.aexel(size: 16)
		aetherLabel.textColor = UIColor.white
		aetherLabel.textAlignment = .center
		
		loopLabel.text = "Loop"
		loopLabel.font = UIFont.aexel(size: 16)
		loopLabel.textColor = UIColor.white
		loopLabel.textAlignment = .center
		
		expAButton.setTitle("Exp\nA", for: .normal)
		expAButton.titleLabel?.font = UIFont.aexel(size: 13)
		expAButton.titleLabel?.numberOfLines = 2
		expAButton.titleLabel?.textAlignment = .center
		expAButton.layer.borderWidth = 1
		expAButton.layer.borderColor = UIColor.white.cgColor
		expAButton.layer.cornerRadius = 5
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
		}
		
		expBButton.setTitle("Exp\nB", for: .normal)
		expBButton.titleLabel?.font = UIFont.aexel(size: 13)
		expBButton.titleLabel?.numberOfLines = 2
		expBButton.titleLabel?.textAlignment = .center
		expBButton.layer.borderWidth = 1
		expBButton.layer.borderColor = UIColor.white.cgColor
		expBButton.layer.cornerRadius = 5
		expBButton.addAction(for: .touchUpInside) {[weak self] in
			guard let me = self else {return}
			me.kinematicsView.Xa = V2(0, 0)
			me.kinematicsView.Va = V2(0, -1)
			me.kinematicsView.Vl = V2(0, 0)
			
			if D.current().iPhone {
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
		
		if D.current().iPhone {message.alpha = 0}
		else {limbos.append(message)}

		// Close
		close.alpha = 0
		close.addAction(for: .touchUpInside) {
			self.closeExplorer()
			Aexels.nexus.brightenNexus()
		}
		limbos.append(close)

		// Swapper =========================
		if D.current().iPhone {
			let swapButton = SwapButton()
			swapButton.addAction(for: .touchUpInside) { [weak self] in
				guard let me = self else {return}
				swapButton.rotateView()
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
		limbos.append(zoneA)
		
		zoneB.addSubview(universePicker)
		limbos.append(zoneB)
		
		zoneC.addSubview(aetherVector)
		zoneC.addSubview(loopVector)
		zoneC.addSubview(aetherLabel)
		zoneC.addSubview(loopLabel)
		limbos.append(zoneC)
		
		zoneD.addSubview(expAButton)
		zoneD.addSubview(expBButton)
		limbos.append(zoneD)

		first = [universe, zoneA, zoneB, zoneC, zoneD]
		second = [message]
	}
	override func layout375x667() {
		let size = UIScreen.main.bounds.size
		
		let h = size.height - 110 - 20
		let w = size.width - 10
		let ch = size.height - 20 - h - 15*2 + 1
		let vw: CGFloat = 72


		universe.frame = CGRect(x: 5, y: 20, width: w, height: w)

		zoneA.frame = CGRect(x: 5, y: universe.bottom, width: 144, height: 667-universe.bottom-60)
		zoneB.frame = CGRect(x: 61, y: 667-108-5, width: 375-139-56-10, height: 108)
		zoneC.frame = CGRect(x: 5+144, y: universe.bottom, width: 375-5-zoneA.right, height: 120)
		zoneD.frame = CGRect(x: 5+144, y: zoneC.bottom, width: zoneC.width, height: 667-universe.bottom-5-zoneC.height-60)

		zoneA.cutouts[.bottomRight] = Cutout(width: zoneA.width-60+5, height: zoneB.height-60+5)
		zoneA.renderPaths()
		
		zoneB.renderPaths()

		zoneC.renderPaths()
		
		zoneD.cutouts[.bottomLeft] = Cutout(width: zoneD.width-139, height: zoneB.height-60)
		zoneD.renderPaths()
		
		playButton.top(offset: UIOffset(horizontal: 0, vertical: 32), size: CGSize(width: 48, height: 30))
		netButton.top(offset: UIOffset(horizontal: 0, vertical: playButton.bottom+20), size: CGSize(width: 48, height: 48))

		let dx: CGFloat = 32
		loopVector.topRight(offset: UIOffset(horizontal: -dx, vertical: 32), size: CGSize(width: vw, height: vw))
		aetherVector.topLeft(offset: UIOffset(horizontal: dx, vertical: 32), size: CGSize(width: vw, height: vw))
		loopLabel.topLeft(offset: UIOffset(horizontal: loopVector.left, vertical: loopVector.top-20), size: CGSize(width: vw, height: 16))
		aetherLabel.topLeft(offset: UIOffset(horizontal: aetherVector.left, vertical: aetherVector.top-20), size: CGSize(width: vw, height: 16))
		
		expAButton.left(offset: UIOffset(horizontal: 108, vertical: 0), size: CGSize(width: 40, height: 50))
		expBButton.left(offset: UIOffset(horizontal: expAButton.right+10, vertical: 0), size: CGSize(width: 40, height: 50))

		universePicker.center(offset: UIOffset.zero, size: CGSize(width: 120, height: ch-12))

		swapper.frame = CGRect(x: 5, y: 667-56-5, width: 56, height: 56)

		message.frame = CGRect(x: 5, y: 20, width: w, height: size.height-20-5)
		message.cutouts[Position.bottomRight] = Cutout(width: 139, height: 60)
		message.cutouts[Position.bottomLeft] = Cutout(width: 56, height: 56)
		message.renderPaths()

		close.frame = CGRect(x: 375-5-139, y: 667-5-60, width: 139, height: 60)
	}
	override func layout1024x768() {
		let size = UIScreen.main.bounds.size
		
		let p: CGFloat = 5
		let uw: CGFloat = size.height - 110 - 20
		let mw: CGFloat = size.width - uw - 2*p
		let ch: CGFloat = size.height - uw - 20
		
		universe.frame = CGRect(x: p, y: 20, width: uw, height: uw)
		
		message.frame = CGRect(x: universe.right, y: 20, width: mw, height: size.height-20)
		message.cutouts[.bottomRight] = Cutout(width: 176, height: 110)
		message.renderPaths()
		message.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 70, right: 0)

		zoneB.frame = CGRect(x: 5, y: universe.bottom, width: 160, height: ch)
		zoneA.frame = CGRect(x: zoneB.right, y: universe.bottom, width: 150, height: ch)
		zoneC.frame = CGRect(x: zoneA.right, y: universe.bottom, width: 180, height: ch)
		zoneD.frame = CGRect(x: zoneC.right, y: universe.bottom, width: universe.width-zoneB.width-zoneA.width-zoneC.width, height: ch)

		universePicker.center(offset: UIOffset.zero, size: CGSize(width: 120, height: 67))
		
		playButton.center(offset: UIOffset(horizontal: -35, vertical: 0), size: CGSize(width: 50, height: 30))
		netButton.center(offset: UIOffset(horizontal: 27, vertical: 0), size: CGSize(width: 48, height: 48))

		aetherVector.left(offset: UIOffset(horizontal: 23, vertical: 10), size: CGSize(width: 63, height: 63))
		aetherLabel.left(offset: UIOffset(horizontal: aetherVector.left, vertical: -32), size: CGSize(width: aetherVector.width, height: 16))
		loopVector.left(offset: UIOffset(horizontal: aetherVector.right+12, vertical: 10), size: CGSize(width: 63, height: 63))
		loopLabel.left(offset: UIOffset(horizontal: loopVector.left, vertical: -32), size: CGSize(width: loopVector.width, height: 16))

		expAButton.center(offset: UIOffset(horizontal: -26, vertical: 0), size: CGSize(width: 40, height: 50))
		expBButton.center(offset: UIOffset(horizontal: 26, vertical: 0), size: CGSize(width: 40, height: 50))

		close.frame = CGRect(x: size.width-p-176, y: size.height-110, width: 176, height: 110)
	}
}
