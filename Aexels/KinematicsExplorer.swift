//
//  KinematicsExplorer.swift
//  Aexels
//
//  Created by Joe Charlier on 1/5/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import UIKit

class KinematicsExplorer: Explorer {
	var message: MessageView!
	let universe = LimboView()
	let controls = LimboView()
	
	let newtonianView: NewtownianView
	let kinematicsView: KinematicsView
	
	let universePicker: SliderView
	let playButton: PlayButton
	
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

	func iPadLimbos () -> [LimboView] {
		var limbos = [LimboView]()
		
		let rect = UIScreen.main.bounds
		
		let h = rect.size.height - 110 - 20
		let w = rect.size.width - h - 10
		
		message = MessageView(frame: CGRect(x: 5, y: 20, width: w, height: rect.size.height-20))
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
	func iPhoneLimbos () -> [LimboView] {
		var limbos = [LimboView]()
		
		let rect = UIScreen.main.bounds
		
		let h = rect.size.height - 110 - 20
		let w = rect.size.width - 10

		// Universe
		universe.frame = CGRect(x: 5, y: 20, width: w, height: w)
		universe.content = kinematicsView
		limbos.append(universe)
		
		// Controls
		controls.frame = CGRect(x: 5, y: universe.bottom, width: universe.width, height: 100)
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
		
//		message = MessageView(frame: CGRect(x: 5, y: 20, width: w, height: rect.size.height-20))
//		message.load(key: "KinematicsLab")
//		limbos.append(message)
		
		
		
		return limbos
	}
	
// Explorer ========================================================================================
	override func createLimbos () -> [LimboView] {
		if Aexels.iPad() {
			return iPadLimbos()
		} else {
			return iPhoneLimbos()
		}
	}
}
