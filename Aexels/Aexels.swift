//
//  Aexels.swift
//  Aexels
//
//  Created by Joe Charlier on 1/2/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import UIKit

class Aexels {
	static var window: UIWindow!
	
	static func start () {
		window = UIWindow()
		window.rootViewController = NexusViewController()
		window.makeKeyAndVisible()
	}
}
