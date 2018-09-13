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

@UIApplicationMain
class AexelsDelegate: UIResponder, UIApplicationDelegate {
	
// UIApplicationDelegate ===========================================================================
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		print("==================== [ Aexels ] =============================================")
		
		Fabric.with([Crashlytics.self])
		Aexels.start()
		
		return true
	}
}
