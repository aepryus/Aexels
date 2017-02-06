//
//  AexelsDelegate.swift
//  Aexels
//
//  Created by Joe Charlier on 1/2/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import Crashlytics
import Fabric
import UIKit
import OoviumLib

@UIApplicationMain
class AexelsDelegate: UIResponder, UIApplicationDelegate {

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		print("==================== [ Aexels ] =============================================")
		
		Fabric.with([Crashlytics.self])
		Aexels.start()
		
		playAegean()
		
		return true
	}

//	func applicationWillResignActive(_ application: UIApplication) {}
//	func applicationDidEnterBackground(_ application: UIApplication) {}
//	func applicationWillEnterForeground(_ application: UIApplication) {}
//	func applicationDidBecomeActive(_ application: UIApplication) {}
//	func applicationWillTerminate(_ application: UIApplication) {}
}

