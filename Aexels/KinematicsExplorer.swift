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

	var first = [Limbo]()
	var second = [Limbo]()
	var isFirst: Bool = true

	init (view: UIView) {
		
		newtonianView = NewtownianView({ (momentum: V2) in
		})
		kinematicsView = KinematicsView()
		
		universePicker = SliderView { (page: String) in
			if page == "Universe" {
			} else {
			}
		}
		playButton = PlayButton()
		
		super.init(view: view, name: "Kinematics", key: "Kinematics", canExplore: true)
	}

	func iPadLimbos() -> [Limbo] {
		var limbos = [Limbo]()
		
		let rect = UIScreen.main.bounds
		
		let h = rect.size.height - 110 - 20
		let w = rect.size.width - h - 10
		
		message = MessageLimbo(frame: CGRect(x: 5, y: 20, width: w, height: rect.size.height-20))
		message.load(key: "KinematicsLab")
		limbos.append(message)
		
		universe.frame = CGRect(x: 5+w, y: 20, width: h, height: h)
		let newtonianView = NewtownianView { (momentum: V2) in
		}
		universe.content = newtonianView
		limbos.append(universe)
		
		controls.frame = CGRect(x: 5+w, y: 20+h, width: h-176, height: rect.size.height-20-h)
		limbos.append(controls)

		let ch = rect.size.height - 20 - h - 15*2 + 1
		controls.addSubview(universePicker)
		universePicker.left(offset: UIOffset(horizontal: 15, vertical: 0), size: CGSize(width: 120, height: ch-12))
		universePicker.pageNo = 1
		
		return limbos
	}
	func iPhoneLimbos() -> [Limbo] {
		var limbos = [Limbo]()
		
		let rect = UIScreen.main.bounds
		
		let h = rect.size.height - 110 - 20
		let w = rect.size.width - 10

		// Universe
		universe.frame = CGRect(x: 5, y: 20, width: w, height: w)
		universe.content = kinematicsView
		limbos.append(universe)
		
		// Controls
		controls.frame = CGRect(x: 5, y: universe.bottom, width: universe.width, height: 667-universe.bottom - 5)
		controls.cutouts[Position.bottomRight] = Cutout(width: 139, height: 60)
		controls.cutouts[Position.bottomLeft] = Cutout(width: 56, height: 56)
		controls.renderPaths()
		limbos.append(controls)

		let ch = rect.size.height - 20 - h - 15*2 + 1
		controls.addSubview(universePicker)
		universePicker.left(offset: UIOffset(horizontal: 15, vertical: 0), size: CGSize(width: 120, height: ch-12))
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
		playButton.left(offset: UIOffset(horizontal: universePicker.right+14, vertical: 0), size: CGSize(width: 50, height: 30))
		
		controls.addSubview(aexelVector)
		controls.addSubview(loopVector)
		
		aexelVector.left(offset: UIOffset(horizontal: playButton.right+15, vertical: 0), size: CGSize(width: 48, height: 48))
		loopVector.left(offset: UIOffset(horizontal: aexelVector.right+15, vertical: 0), size: CGSize(width: 48, height: 48))
		
		
		// Message
		message = MessageLimbo(frame: CGRect(x: 5, y: 20, width: w, height: rect.size.height-20-5))
		message.cutouts[Position.bottomRight] = Cutout(width: 139, height: 60)
		message.cutouts[Position.bottomLeft] = Cutout(width: 56, height: 56)
		message.renderPaths()
		message.load(key: "KinematicsLab")
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
		let swapper = Limbo()
		swapper.frame = CGRect(x: 5, y: 667-56-5, width: 56, height: 56)
		let swapButton = SwapButton()
		swapButton.add(for: .touchUpInside) {
			swapButton.rotateView()
			if self.isFirst {
				self.isFirst = false
				self.dimLimbos(self.first)
				self.brightenLimbos(self.second)
				self.limbos = [swapper, close1] + self.second
			} else {
				self.isFirst = true
				self.dimLimbos(self.second)
				self.brightenLimbos(self.first)
				self.limbos = [swapper, close1] + self.first
			}
			swapper.removeFromSuperview()
			self.view.addSubview(swapper)
			close1.removeFromSuperview()
			self.view.addSubview(close1)
		}
		swapper.content = swapButton
		limbos.append(swapper)

		first = [universe, controls]
		second = [message]

		return limbos
	}
	
// Explorer ========================================================================================
	override func createLimbos() -> [Limbo] {
		if Aexels.iPad() {
			return iPadLimbos()
		} else {
			return iPhoneLimbos()
		}
	}
}
