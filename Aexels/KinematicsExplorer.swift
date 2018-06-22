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
	let controls = Limbo()
	
	let newtonianView: NewtownianView
	let kinematicsView: KinematicsView
	
	var universePicker: SliderView!
	let playButton: PlayButton
	let aetherVector = VectorView()
	let loopVector = VectorView()
	let netButton = NetButton()
	let presetButton = UIButton()
	let swapper = Limbo()
	let close = Limbo()
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
					me.presetButton.alpha = 1
				} else {
					me.aetherLabel.alpha = 0
					me.aetherVector.alpha = 0
					me.netButton.alpha = 0
					me.presetButton.alpha = 0
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
		limbos.append(controls)
		
		controls.addSubview(universePicker)
		universePicker.pages = ["Universe", "Universe X"]
		universePicker.snapToPageNo(1)
		
		playButton.onPlay = {
			self.kinematicsView.play()
		}
		playButton.onStop = {
			self.kinematicsView.stop()
		}
		controls.addSubview(playButton)
		
		controls.addSubview(aetherVector)
		aetherVector.max = 5
		aetherVector.onTap = { [weak self] (vector: V2) in
			print("\(vector)")
			guard let me = self else {return}
			me.kinematicsView.Va = vector
		}
		
		controls.addSubview(loopVector)
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
		controls.addSubview(aetherLabel)
		
		loopLabel.text = "Loop"
		loopLabel.font = UIFont.aexel(size: 16)
		loopLabel.textColor = UIColor.white
		loopLabel.textAlignment = .center
		controls.addSubview(loopLabel)
		
		presetButton.setTitle("Experiment\nA", for: .normal)
		presetButton.titleLabel?.font = UIFont.aexel(size: 13)
		presetButton.titleLabel?.numberOfLines = 2
		presetButton.titleLabel?.textAlignment = .center
		presetButton.layer.borderWidth = 1
		presetButton.layer.borderColor = UIColor.white.cgColor
		presetButton.layer.cornerRadius = 5
		presetButton.addAction(for: .touchUpInside) {[weak self] in
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
		controls.addSubview(presetButton)

		netButton.addAction(for: .touchUpInside) { [weak self] in
			guard let me = self else {return}
			me.kinematicsView.aetherVisible = !me.kinematicsView.aetherVisible
			me.netButton.on = me.kinematicsView.aetherVisible
			me.netButton.setNeedsDisplay()
		}
		controls.addSubview(netButton)
		
		// Message
		message = MessageLimbo()
		message.key = "KinematicsLab"
		
		if D.current().iPhone {message.alpha = 0}
		else {limbos.append(message)}

		// Close
		close.alpha = 0
		let button1 = AXButton()
		button1.setTitle("Close", for: .normal)
		button1.addAction(for: .touchUpInside) {
			self.closeExplorer()
			Aexels.nexus.brightenNexus()
		}
		close.content = button1
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
		
		first = [universe, controls]
		second = [message]
	}
	override func layout375x667() {
		let size = UIScreen.main.bounds.size
		
		let h = size.height - 110 - 20
		let w = size.width - 10
		let ch = size.height - 20 - h - 15*2 + 1
		let vw: CGFloat = 72

		universe.frame = CGRect(x: 5, y: 20, width: w, height: w)

		controls.frame = CGRect(x: 5, y: universe.bottom, width: universe.width, height: 667-universe.bottom - 5)
		controls.cutouts[Position.bottomRight] = Cutout(width: 139, height: 60)
		controls.cutouts[Position.bottomLeft] = Cutout(width: 56, height: 56)
		controls.renderPaths()

		playButton.topLeft(offset: UIOffset(horizontal: 32, vertical: 32), size: CGSize(width: 48, height: 30))
		loopVector.topRight(offset: UIOffset(horizontal: -20, vertical: 32), size: CGSize(width: vw, height: vw))
		aetherVector.topRight(offset: UIOffset(horizontal: -20-vw-12, vertical: loopVector.top), size: CGSize(width: vw, height: vw))
		loopLabel.topLeft(offset: UIOffset(horizontal: loopVector.left, vertical: loopVector.top-20), size: CGSize(width: vw, height: 16))
		aetherLabel.topLeft(offset: UIOffset(horizontal: aetherVector.left, vertical: aetherVector.top-20), size: CGSize(width: vw, height: 16))
		presetButton.topLeft(offset: UIOffset(horizontal: aetherVector.left+(2*aetherVector.width+12-96)/2, vertical: aetherVector.bottom+8), size: CGSize(width: 96, height: 36))

		netButton.topLeft(offset: UIOffset(horizontal: playButton.left, vertical: playButton.bottom+12), size: CGSize(width: 48, height: 48))
		universePicker.topLeft(offset: UIOffset(horizontal: 81, vertical: 191), size: CGSize(width: 120, height: ch-12))

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

		controls.frame = CGRect(x: p, y: universe.bottom, width: uw, height: ch)
		universePicker.left(offset: UIOffset(horizontal: 15, vertical: 0), size: CGSize(width: 120, height: 67))
		playButton.left(offset: UIOffset(horizontal: universePicker.right+30, vertical: 0), size: CGSize(width: 50, height: 30))
		netButton.left(offset: UIOffset(horizontal: playButton.right+30, vertical: 0), size: CGSize(width: 48, height: 48))
		aetherVector.left(offset: UIOffset(horizontal: netButton.right+60, vertical: 10), size: CGSize(width: 63, height: 63))
		aetherLabel.left(offset: UIOffset(horizontal: aetherVector.left, vertical: -32), size: CGSize(width: aetherVector.width, height: 16))
		loopVector.left(offset: UIOffset(horizontal: aetherVector.right+20, vertical: 10), size: CGSize(width: 63, height: 63))
		loopLabel.left(offset: UIOffset(horizontal: loopVector.left, vertical: -32), size: CGSize(width: loopVector.width, height: 16))
		presetButton.left(offset: UIOffset(horizontal: loopVector.right+20, vertical: 0), size: CGSize(width: 96, height: 36))

		close.frame = CGRect(x: size.width-p-176, y: size.height-110, width: 176, height: 110)
	}
}
