//
//  CellularAutomataExplorer.swift
//  Aexels
//
//  Created by Joe Charlier on 1/5/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import UIKit

class CellularAutomataExplorer: Explorer {
	var aether = LimboView()
	var controls = LimboView()
	var dilator = LimboView()
	var message = MessageView()
	var large = LimboView()
	var medium = LimboView()
	var small = LimboView()
	
	init () {
		super.init(name: "Cellular Automata", key: "CellularAutomata", canExplore: true)
	}

	// Explorer ========================================================================================
	override func loadView (_ view: UIView) {
		
		let x: CGFloat = 432
		let y: CGFloat = 400
		let ch: CGFloat = 72

		aether.frame = CGRect(x: 5, y: 20, width: 1024-(x+30)-10, height: y)
		limboViews.append(aether)
		
		controls.frame = CGRect(x: 5, y: 20+y, width: 200, height: ch)
		limboViews.append(controls)
		
		dilator.frame = CGRect(x: 205, y: 20+y, width: 1024-(x+30)-200-10, height: ch)
		limboViews.append(dilator)
		
		message.frame = CGRect(x: 5, y: 20+y+ch, width: 1024-(x+30)-10, height: 768-20-y-ch)
		message.load(key: "GameOfLife")
		limboViews.append(message)
		
		large.frame = CGRect(x: 1024-462-5, y: 20, width: x+30, height: x+30)
		limboViews.append(large)
		
		medium.frame = CGRect(x: 1024-462-5, y: 20+462, width: 286, height: 286)
		limboViews.append(medium)
		
		small.frame = CGRect(x: 1024-462-5+286, y: 20+462, width: 176, height: 176)
		limboViews.append(small)
		
		super.loadView(view)
	}
}
