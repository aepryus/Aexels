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
	
	static func iPhone4 () -> Bool {
		return UIScreen.main.bounds.size == CGSize(width: 320, height: 480)
	}
	static func iPhone5 () -> Bool {
		return UIScreen.main.bounds.size == CGSize(width: 320, height: 568)
	}
	static func iPhone6 () -> Bool {
		return UIScreen.main.bounds.size == CGSize(width: 375, height: 667)
	}
	static func iPad () -> Bool {
		return UIScreen.main.bounds.size == CGSize(width: 1024, height: 768)
	}
	
	static func backImage () -> UIImage {
		if iPhone4() {
			return UIImage(named: "Back4")!
		} else if iPhone5() {
			return UIImage(named: "Back5")!
		} else if iPhone6() {
			return UIImage(named: "Back6")!
		}

		return UIImage(named: "BackiPad")!
	}
	
	static func start () {
		Math.start()

		nexus = NexusViewController()
		
		window = UIWindow()
		window.rootViewController = nexus
		window.makeKeyAndVisible()
	}
}
