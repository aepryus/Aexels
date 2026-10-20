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
		return true
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

/* The window belongs to a scene, not to the application. iOS 27 and macOS 27 stopped merely warning
   about apps that skip this and now trap during scene creation, so the app launched straight into a
   SIGTRAP. Becoming active and entering the background are the scene's now too. */
class AexelsSceneDelegate: UIResponder, UIWindowSceneDelegate {
	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options: UIScene.ConnectionOptions) {
		guard let windowScene = scene as? UIWindowScene else { return }
		Aexels.start(windowScene: windowScene)
	}
	func sceneDidBecomeActive(_ scene: UIScene) {
		if Aexels.explorerViewController.explorer is NexusExplorer, Screen.mac { Aexels.explorerViewController.graphView.start() }
	}
	func sceneDidEnterBackground(_ scene: UIScene) {
		Aexels.explorerViewController.graphView.stop()
		if let aetherView = Aexels.aetherView { aetherView.saveAether() }
	}
}
