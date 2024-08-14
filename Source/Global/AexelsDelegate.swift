//
//  AexelsDelegate.swift
//  Aexels
//
//  Created by Joe Charlier on 1/2/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import OoviumKit
import UIKit

@UIApplicationMain
class AexelsDelegate: UIResponder, UIApplicationDelegate {
	
// UIApplicationDelegate ===========================================================================
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		Aexels.start()
		return true
	}
    func applicationDidBecomeActive(_ application: UIApplication) {
        if Aexels.explorerViewController.explorer is NexusExplorer { Aexels.explorerViewController.graphView.start() }
    }
	func applicationDidEnterBackground(_ application: UIApplication) {
        Aexels.explorerViewController.graphView.stop()
        if let aetherView = Aexels.aetherView { aetherView.saveAether() }
	}
}
