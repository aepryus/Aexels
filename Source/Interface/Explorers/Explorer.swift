//
//  Explorer.swift
//  Aexels
//
//  Created by Joe Charlier on 1/4/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import Acheron
import OoviumKit
import UIKit

class Explorer: AEViewController {
	let name: String
	let key: String
	let canExplore: Bool
	
	init(name: String, key: String, canExplore: Bool) {
		self.name = name
		self.key = key
		self.canExplore = canExplore
        super.init()
	}
	
    var shortName: String { name }
    lazy var explorerButton: ExplorerButton = ExplorerButton(text: shortName, imageView: UIImageView(image: UIImage(named: "\(key)_icon")))
    var limbos: [UIView] = []
    var layedOut: Bool = false
    
    func openExplorer (view: UIView) {
        if !layedOut {
            createLimbos()
            layout()
            layedOut = true
        }

        for limbo in limbos {
            limbo.alpha = 0
//            view.addSubview(limbo)
        }
        
        onOpen()
        UIView.animate(withDuration: 0.2, animations: {
            self.onOpening()
            for view in self.limbos {
                view.alpha = 1
            }
        }) { (finished: Bool) in
            self.onOpened()
        }
    }
    func closeExplorer() {}
    
    func createLimbos() {}
    func dimLimbos(_ limbos: [UIView]) {}
    func brightenLimbos(_ limbos: [UIView]) {}
    
	func onOpen() {}
	func onOpening() {}
	func onOpened() {}
	func onClose() {}
}
