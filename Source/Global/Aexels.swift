//
//  Aexels.swift
//  Aexels
//
//  Created by Joe Charlier on 1/2/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import Acheron
import OoviumEngine
import OoviumKit
import UIKit

class Aexels {
    static var window: UIWindow = UIWindow()
	static let basket: Basket = Basket(SQLitePersist("pequod"))
	static var nexus: NexusViewController!
	static var aetherView: AetherView? = nil
	static var sync: AESync = AESync()
	static let shippedAethers: [String] = ["Day & Night", "Demons", "Game of Life", "Move", "Sweetness", "WalledCities"]
	
	static var version: String { Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0" }
	
	static func start() {
        print("==================== [ Aexels ] =============================================")
        _ = ChainResponder.hasExternalKeyboard

        Math.start()
		Loom.start(basket: Aexels.basket, namespaces: ["Aexels", "OoviumEngine"])
		Skin.skin = IvorySkin()

		nexus = NexusViewController()
		
		window.rootViewController = ExplorerViewController()
		window.makeKeyAndVisible()
//		window.rootViewController = nexus

		let oldVersion: String? = Aexels.basket.get(key: "version")
		if oldVersion == nil { Local.archiveXML() }
		if oldVersion != Aexels.version {
			Aexels.shippedAethers.forEach { Local.installAetherFromBundle(name: $0) }
			Aexels.basket.set(key: "version", value: Aexels.version)
		}
        Aexels.shippedAethers.forEach { Local.installAetherFromBundle(name: $0) }

		if Screen.mac, #available(iOS 13.0, *) {
			UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.forEach { (windowScene: UIWindowScene) in
				let size: CGSize = CGSize(width: 1194/Screen.scaler, height: 834/Screen.scaler)
				windowScene.sizeRestrictions?.minimumSize = size
				windowScene.sizeRestrictions?.maximumSize = size
			}
		}
	}
}
