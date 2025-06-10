//
//  AexelsDelegate.swift
//  Aexels
//
//  Created by Joe Charlier on 1/2/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import Acheron
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
        if Aexels.explorerViewController.explorer is NexusExplorer, Screen.mac { Aexels.explorerViewController.graphView.start() }
    }
	func applicationDidEnterBackground(_ application: UIApplication) {
        Aexels.explorerViewController.graphView.stop()
        if let aetherView = Aexels.aetherView { aetherView.saveAether() }
	}
    
// MacOS ===========================================================================================
    override func buildMenu(with builder: UIMenuBuilder) {
        super.buildMenu(with: builder)

        builder.remove(menu: .services)
        builder.remove(menu: .hide)

        let aboutAction: UIAction = UIAction(title: "About Aexels", handler: { (action: UIAction) in
            Aexels.explorerViewController.flashAbout()
        })
        builder.replace(menu: .about, with: UIMenu(title: "", image: nil, identifier: .about, options: .displayInline, children: [aboutAction]))

        builder.remove(menu: .file)
        builder.remove(menu: .edit)
        builder.remove(menu: .format)
        builder.remove(menu: .view)
        builder.remove(menu: .window)
        builder.remove(menu: .help)
    }
}
