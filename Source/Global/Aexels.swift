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
    static var sync: AESync = AESync()
	static let basket: Basket = Basket(SQLitePersist("pequod"))
    
    static var settings: Settings!
    
    static var explorerViewController: ExplorerViewController = ExplorerViewController()
    static let nexusExplorer: NexusExplorer = NexusExplorer()
    static let aetherExplorer: AetherExplorer = AetherExplorer()
    static let cellularExplorer: CellularExplorer = CellularExplorer()
    static let kinematicsExplorer: KinematicsExplorer = KinematicsExplorer()
    static let distanceExplorer: DistanceExplorer = DistanceExplorer()
    static let gravityExplorer: GravityExplorer = GravityExplorer()
    static let dilationExplorer: DilationExplorer = DilationExplorer()
    static let contractionExplorer: ContractionExplorer = ContractionExplorer()
    static let electromagnetismExplorer: ElectromagnetismExplorer = ElectromagnetismExplorer()

    static var aetherView: AetherView? = nil

    static let shippedAethers: [String] = ["Day & Night", "Demons", "Game of Life", "Move", "Sweetness", "WalledCities"]

	static var version: String { Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0" }
	
	static func start() {
//        NCTest()
        
        print("==================== [ Aexels ] =============================================")
        _ = ChainResponder.hasExternalKeyboard

        Math.start()
		Loom.start(basket: Aexels.basket, namespaces: ["Aexels", "OoviumEngine"])
		Skin.skin = IvorySkin()
        
        if let iden: String = Loom.get(key: "settingsIden"), let settings: Settings = Loom.selectBy(iden: iden) {
            Aexels.settings = settings
        } else {
            Loom.transact { settings = Loom.create() }
            Loom.set(key: "settingsIden", value: settings.iden)
        }

		window.rootViewController = UIViewController()
		window.makeKeyAndVisible()
		window.rootViewController = explorerViewController

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
