//
//  Aexels.swift
//  Aexels
//
//  Created by Joe Charlier on 1/2/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import OoviumLib
import UIKit

class Aexels {
	static var window: UIWindow!
	static var nexus: NexusViewController!
	
	static func start () {
		Math.start()

		nexus = NexusViewController()
		
		window = UIWindow()
		window.rootViewController = nexus
		window.makeKeyAndVisible()
	}
}
