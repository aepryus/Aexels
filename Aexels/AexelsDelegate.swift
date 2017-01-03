//
//  AexelsDelegate.swift
//  Aexels
//
//  Created by Joe Charlier on 1/2/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import UIKit

@UIApplicationMain
class AexelsDelegate: UIResponder, UIApplicationDelegate {

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		print("==================== [ Aexels ] =============================================")
		
		Aexels.start()
		return true
	}

//	func applicationWillResignActive(_ application: UIApplication) {}
//	func applicationDidEnterBackground(_ application: UIApplication) {}
//	func applicationWillEnterForeground(_ application: UIApplication) {}
//	func applicationDidBecomeActive(_ application: UIApplication) {}
//	func applicationWillTerminate(_ application: UIApplication) {}
}

