//
//  KinematicsExplorer.swift
//  Aexels
//
//  Created by Joe Charlier on 1/5/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import UIKit

class KinematicsExplorer: Explorer {
	let message = MessageView()
	let universe = LimboView()
	let controls = LimboView()
	let close = LimboView()
	
	init () {
		super.init(name: "Kinematics", key: "Kinematics", canExplore: true)
	}
	
	func openExplorer () {
		UIView.animate(withDuration: 0.2) { 
			self.message.alpha = 1
			self.universe.alpha = 1
			self.controls.alpha = 1
			self.close.alpha = 1
		}
	}
	func closeExplorer () {
		UIView.animate(withDuration: 0.2) {
			self.message.alpha = 0
			self.universe.alpha = 0
			self.controls.alpha = 0
			self.close.alpha = 0
		}
	}
	
// Explorer ========================================================================================
	override func loadView (_ view: UIView) {
		let rect = UIScreen.main.bounds

		let h = rect.size.height - 110 - 20
		let w = rect.size.width - h - 10

		message.frame = CGRect(x: 5, y: 20, width: w, height: rect.size.height-20)
		message.alpha = 0
		message.load(key: "KinematicsLab")
		view.addSubview(message)
		
		universe.frame = CGRect(x: 5+w, y: 20, width: h, height: h)
		universe.alpha = 0
		view.addSubview(universe)
		
		controls.frame = CGRect(x: 5+w, y: 20+h, width: h-176, height: rect.size.height-20-h)
		controls.alpha = 0
		view.addSubview(controls)
		
		close.frame = CGRect(x: 1024-462-5+286, y: 20+462+176, width: 176, height: 110)
		close.alpha = 0
		view.addSubview(close)
		
		let button = UIButton(type: .custom)
		button.setTitle("Close", for: .normal)
		button.titleLabel!.font = UIFont.aexelFont(size: 24)
		button.addClosure({
			self.closeExplorer()
			Aexels.nexus.brightenNexus()
		}, controlEvents: .touchUpInside)
		close.content = button
		
		openExplorer()
	}
}
