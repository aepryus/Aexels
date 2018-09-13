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
	static var timer: AXTimer = AXTimer()
	
	static func backImage() -> UIImage {
		switch Screen.this  {
			case .dim320x480:
				return UIImage(named: "Back4")!
			case .dim320x568, .dim375x667, .dim414x736:
				return UIImage(named: "Back6")!
			case .dim375x812:
				return UIImage(named: "Back5")!
			case .dim1024x768, .dim1112x834, .dim1366x1024:
				return UIImage(named: "BackiPad")!
			case .dimOther:
				return UIImage(named: "Back5")!
		}
	}
	
	static func start() {
		Math.start()
		Skin.skin = IvorySkin()

		nexus = NexusViewController()
		
		window = UIWindow()
		window.rootViewController = nexus
		window.makeKeyAndVisible()
		
		if !Local.hasAether(name: "Game of Life") {
			Local.installAetherFromBundle(name: "Game of Life")
			Local.installAetherFromBundle(name: "Demons")
		}
		
		print("\(Screen.this)")
	}
}
