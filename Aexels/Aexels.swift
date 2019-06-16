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
		switch Screen.this  {
			case .dim320x480:
				return UIImage(named: "Back4")!
			case .dim320x568, .dim375x667, .dim414x736, .dim375x812, .dim414x896:
				return UIImage(named: "Back6")!
			case .dim1024x768, .dim1112x834, .dim1194x834, .dim1366x1024:
				return UIImage(named: "BackiPad")!
			case .dimOther:
				return UIImage(named: "Back5")!
		}
	}
	
	static func start() {
		Math.start()
		Loom.start(basket: Storage.basket, namespaces: ["Aexels", "OoviumLib"])
		Skin.skin = IvorySkin()

		nexus = NexusViewController()
		
		window = UIWindow()
		window.rootViewController = nexus
		window.makeKeyAndVisible()
		
		let oldVersion: String? = Storage.get(key: "version")
		if oldVersion == nil {Local.archiveXML()}
		if  oldVersion != Aexels.version {
			Local.installAetherFromBundle(name: "Day & Night")
			Local.installAetherFromBundle(name: "Demons")
			Local.installAetherFromBundle(name: "Game of Life")
			Local.installAetherFromBundle(name: "Move")
			Local.installAetherFromBundle(name: "Sweetness")
			Local.installAetherFromBundle(name: "WalledCities")
			Storage.set(key: "version", value: Aexels.version)
		}
		
		Hovers.chainEditor = ChainEditor(schematics: [
			EvoNumSchematic(),
			ScientificSchematic(),
			EvoDevSchematic(),
			Hovers.customSchematic
		])
//		
//		
//		var bondA = AXBondCreate(Vector(x: 0, y: 0), Vector(x: 10, y: 0));
//		var bondB = AXBondCreate(Vector(x: 10, y: 1), Vector(x: 10, y: 0.1));
//		var result = AXBondCross(bondA, bondB);
//		print("result: \(result) == 0")
//
//		bondA = AXBondCreate(Vector(x: 0, y: 0), Vector(x: 10, y: 0));
//		bondB = AXBondCreate(Vector(x: 10, y: 1), Vector(x: 10, y: -0.1));
//		result = AXBondCross(bondA, bondB);
//		print("result: \(result) == 1 ")
//
//		bondA = AXBondCreate(Vector(x: 0, y: 0), Vector(x: 10, y: 0));
//		bondB = AXBondCreate(Vector(x: 10, y: 1), Vector(x: 10, y: 0));
//		result = AXBondCross(bondA, bondB);
//		print("result: \(result) == 1 ")
//
//		bondA = AXBondCreate(Vector(x: 3, y: 5), Vector(x: 6, y: 2));
//		bondB = AXBondCreate(Vector(x: 1, y: 1), Vector(x: 2, y: 2));
//		result = AXBondCross(bondA, bondB);
//		print("result: \(result) == 0")
//		
//		bondA = AXBondCreate(Vector(x: 3, y: 5), Vector(x: 6, y: 2));
//		bondB = AXBondCreate(Vector(x: 1, y: 1), Vector(x: 6, y: 6));
//		result = AXBondCross(bondA, bondB);
//		print("result: \(result) == 1")
//
//		bondA = AXBondCreate(Vector(x: 2, y: 4), Vector(x: 4, y: 2));
//		bondB = AXBondCreate(Vector(x: 1, y: 1), Vector(x: 3, y: 3));
//		result = AXBondCross(bondA, bondB);
//		print("result: \(result) == 1")
//
//		bondA = AXBondCreate(Vector(x: 2, y: 4), Vector(x: 4, y: 2));
//		bondB = AXBondCreate(Vector(x: 1, y: 1), Vector(x: 2.9999, y: 2.9999));
//		result = AXBondCross(bondA, bondB);
//		print("result: \(result) == 0")
	}
}
