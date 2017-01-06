//
//  Explorer.swift
//  Aexels
//
//  Created by Joe Charlier on 1/4/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import UIKit

class Explorer {
	let name: String
	let key: String
	let canExplore: Bool
	
	init (name: String, key: String, canExplore: Bool) {
		self.name = name
		self.key = key
		self.canExplore = canExplore
	}
	
	func loadView (_ view: UIView) {}
}
