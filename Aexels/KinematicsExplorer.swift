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
	
	init () {
		super.init(name: "Kinematics", key: "Kinematics", canExplore: true)
	}
	
// Explorer ========================================================================================
	override func loadView (_ view: UIView) {
		let rect = UIScreen.main.bounds

		let h = rect.size.height - 110 - 20
		let w = rect.size.width - h - 10

		message.frame = CGRect(x: 5, y: 20, width: w, height: rect.size.height-20)
		message.load(key: "KinematicsLab")
		limboViews.append(message)
		
		universe.frame = CGRect(x: 5+w, y: 20, width: h, height: h)
		limboViews.append(universe)
		
		controls.frame = CGRect(x: 5+w, y: 20+h, width: h-176, height: rect.size.height-20-h)
		limboViews.append(controls)
		
		super.loadView(view)
	}
}
