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
	
    var iconToken: String { "\(key)_icon" }
    var icon: UIImage { UIImage(named: iconToken)! }
    
    var shortName: String { name }
    var layedOut: Bool = false
    
    func openExplorer (view: UIView) {
        if !layedOut {
            createLimbos()
            layout()
            layedOut = true
        }

        onOpen()
        UIView.animate(withDuration: 0.2, animations: {
            self.onOpening()
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
