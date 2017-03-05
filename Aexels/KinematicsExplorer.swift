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
	
	init () {
		super.init(name: "Kinematics", key: "Kinematics", canExplore: Aexels.iPad())
	}
	
// Explorer ========================================================================================
	override func createLimbos () -> [LimboView] {
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
		
		return limbos
	}
}
