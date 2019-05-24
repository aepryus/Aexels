//
//  AexelsDelegate.swift
//  Aexels
//
//  Created by Joe Charlier on 1/2/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import Crashlytics
import Fabric
import OoviumLib
import UIKit

@UIApplicationMain
class AexelsDelegate: UIResponder, UIApplicationDelegate {
	
// UIApplicationDelegate ===========================================================================
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		print("==================== [ Aexels ] =============================================")
		
		Fabric.with([Crashlytics.self])
		Aexels.start()
		
		return true
	}
	func applicationDidEnterBackground(_ application: UIApplication) {
		if !Oovium.aetherView.aether.readOnly {Oovium.aetherView.saveAether()}
	}
}
