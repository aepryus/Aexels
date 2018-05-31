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
	
	let universePicker: SliderView
	let playButton: PlayButton
	let aexelVector = VectorView()
	let loopVector = VectorView()
	let swapper = Limbo()

	var first = [Limbo]()
	var second = [Limbo]()
	var isFirst: Bool = true

	init(parent: UIView) {
		
		newtonianView = NewtownianView({ (momentum: V2) in
		})
		kinematicsView = KinematicsView()
		
		universePicker = SliderView { (page: String) in
			if page == "Universe" {
			} else {
			}
		}
		playButton = PlayButton()
		
		super.init(parent: parent, name: "Kinematics", key: "Kinematics", canExplore: true)
	}
	
// Explorer ========================================================================================
	override func createLimbos() {
		
		// Universe
		universe.content = kinematicsView
		limbos.append(universe)
		
		// Controls
		controls.frame = CGRect(x: 5, y: universe.bottom, width: universe.width, height: 667-universe.bottom - 5)
		controls.cutouts[Position.bottomRight] = Cutout(width: 139, height: 60)
		controls.cutouts[Position.bottomLeft] = Cutout(width: 56, height: 56)
		controls.renderPaths()
		limbos.append(controls)
		
		controls.addSubview(universePicker)
		universePicker.pages = ["Universe", "Universe X"]
		universePicker.snapToPageNo(1)
		
		playButton.play()
		playButton.onPlay = {
			self.kinematicsView.play()
		}
		playButton.onStop = {
			self.kinematicsView.stop()
		}
		controls.addSubview(playButton)
		
		controls.addSubview(aexelVector)
		controls.addSubview(loopVector)
		
		// Message
		message = MessageLimbo()
		message.renderPaths()
		message.key = "KinematicsLab"
		message.alpha = 0
		
		// Close
		let size = CGSize(width: 139, height: 60)
		let close1 = Limbo()
		close1.frame = CGRect(x: 375-5-size.width, y: 667-5-size.height, width: size.width, height: size.height)
		close1.alpha = 0
		let button1 = AXButton()
		button1.setTitle("Close", for: .normal)
		button1.add(for: .touchUpInside) {
			self.closeExplorer()
			Aexels.nexus.brightenNexus()
		}
		close1.content = button1
		limbos.append(close1)
		
		// Swapper =========================
		if D.current().iPhone {
			let swapButton = SwapButton()
			swapButton.add(for: .touchUpInside) { [weak self] in
				guard let me = self else {return}
				swapButton.rotateView()
				if me.isFirst {
					me.isFirst = false
					me.dimLimbos(me.first)
					me.brightenLimbos(me.second)
					me.limbos = [me.swapper, close1] + me.second
				} else {
					me.isFirst = true
					me.dimLimbos(me.second)
					me.brightenLimbos(me.first)
					me.limbos = [me.swapper, close1] + me.first
				}
				me.swapper.removeFromSuperview()
				me.parent.addSubview(me.swapper)
				close1.removeFromSuperview()
				me.parent.addSubview(close1)
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
		
		universe.frame = CGRect(x: 5, y: 20, width: w, height: w)
		
		let ch = size.height - 20 - h - 15*2 + 1

		message.frame = CGRect(x: 5, y: 20, width: w, height: size.height-20-5)
		message.cutouts[Position.bottomRight] = Cutout(width: 139, height: 60)
		message.cutouts[Position.bottomLeft] = Cutout(width: 56, height: 56)

		universePicker.left(offset: UIOffset(horizontal: 15, vertical: 0), size: CGSize(width: 120, height: ch-12))
		playButton.left(offset: UIOffset(horizontal: universePicker.right+14, vertical: 0), size: CGSize(width: 50, height: 30))
		aexelVector.left(offset: UIOffset(horizontal: playButton.right+15, vertical: 0), size: CGSize(width: 48, height: 48))
		loopVector.left(offset: UIOffset(horizontal: aexelVector.right+15, vertical: 0), size: CGSize(width: 48, height: 48))
		swapper.frame = CGRect(x: 5, y: 667-56-5, width: 56, height: 56)
	}
	override func layout1024x768() {
		let size = UIScreen.main.bounds.size
		
		let h = size.height - 110 - 20
		let w = size.width - h - 10
		
		message = MessageLimbo()
		message.frame = CGRect(x: 5, y: 20, width: w, height: size.height-20)
		message.key = "KinematicsLab"
		limbos.append(message)
		
		universe.frame = CGRect(x: 5+w, y: 20, width: h, height: h)
		let newtonianView = NewtownianView { (momentum: V2) in
		}
		universe.content = newtonianView
		limbos.append(universe)
		
		controls.frame = CGRect(x: 5+w, y: 20+h, width: h-176, height: size.height-20-h)
		limbos.append(controls)
		
		let ch = size.height - 20 - h - 15*2 + 1
		controls.addSubview(universePicker)
		universePicker.left(offset: UIOffset(horizontal: 15, vertical: 0), size: CGSize(width: 120, height: ch-12))
//		universePicker.pageNo = 1
		
	}
}
