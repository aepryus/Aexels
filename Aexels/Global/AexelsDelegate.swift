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
		print("==================== [ Aexels ] =============================================")
		Aexels.start()
		return true
	}
	func applicationDidEnterBackground(_ application: UIApplication) {
        if let aetherView = Aexels.aetherView { aetherView.saveAether() }
	}
}
