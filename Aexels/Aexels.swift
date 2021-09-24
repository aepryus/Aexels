//
//  Aexels.swift
//  Aexels
//
//  Created by Joe Charlier on 1/2/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import Acheron
import OoviumKit
import UIKit

class Aexels {
	static var window: UIWindow = UIWindow(frame: UIScreen.main.bounds)
	static var nexus: NexusViewController!
	static var sync: AXSync = AXSync()
	static var shippedAethers: [String] = ["Day & Night", "Demons", "Game of Life", "Move", "Sweetness", "WalledCities"]
	
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
		Loom.start(basket: Pequod.basket, namespaces: ["Aexels", "OoviumKit"])
		Skin.skin = IvorySkin()
		Oovium.screenBurn = false

		nexus = NexusViewController()
		
		window.rootViewController = UIViewController()
		window.makeKeyAndVisible()
		window.rootViewController = nexus

		let oldVersion: String? = Local.get(key: "version")
		if oldVersion == nil {Local.archiveXML()}
		if  oldVersion != Aexels.version {
			Aexels.shippedAethers.forEach { Local.installAetherFromBundle(name: $0) }
			Local.set(key: "version", value: Aexels.version)
		}

		if Screen.mac, #available(iOS 13.0, *) {
			UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.forEach { (windowScene: UIWindowScene) in
				let size: CGSize = CGSize(width: 1194/Screen.scaler, height: 834/Screen.scaler)
				windowScene.sizeRestrictions?.minimumSize = size
				windowScene.sizeRestrictions?.maximumSize = size
			}
		}
	}
}
