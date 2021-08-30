//
//  Aexels.swift
//  Aexels
//
//  Created by Joe Charlier on 1/2/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import Acheron
import OoviumLib
import UIKit

class Aexels {
	static var window: UIWindow!
	static var nexus: NexusViewController!
	static var sync: AXSync = AXSync()
	
	static var version: String {
		return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0"
	}
	
	static func backImage() -> UIImage {
		switch Screen.dimensions  {
			case .dim320x480:
				return UIImage(named: "Back4")!
			case .dim320x568, .dim375x667, .dim414x736, .dim375x812, .dim414x896, .dim360x780, .dim390x844, .dim428x926:
				return UIImage(named: "Back6")!
			case .dim1024x768, .dim1080x810, .dim1112x834, .dim1194x834, .dim1366x1024:
				return UIImage(named: "BackiPad")!
			case .dimOther:
				return UIImage(named: "Back5")!
		}
	}
	
	static func start() {
		Math.start()
		Loom.start(basket: Local.basket, namespaces: ["Aexels", "OoviumLib"])
		Skin.skin = IvorySkin()

		nexus = NexusViewController()
		
		window = UIWindow()
		window.makeKeyAndVisible()
		window.rootViewController = nexus
		
		let oldVersion: String? = Local.get(key: "version")
		if oldVersion == nil {Local.archiveXML()}
		if  oldVersion != Aexels.version {
			Local.installAetherFromBundle(name: "Day & Night")
			Local.installAetherFromBundle(name: "Demons")
			Local.installAetherFromBundle(name: "Game of Life")
			Local.installAetherFromBundle(name: "Move")
			Local.installAetherFromBundle(name: "Sweetness")
			Local.installAetherFromBundle(name: "WalledCities")
			Local.set(key: "version", value: Aexels.version)
		}
		
		Hovers.chainEditor = ChainEditor(schematics: [
			EvoNumSchematic(),
			ScientificSchematic(),
			EvoDevSchematic(),
			Hovers.customSchematic
		])

//		AXVectorTest();
	}
}
