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
	
// Explorer ========================================================================================
    lazy var explorerButton: ExplorerButton = ExplorerButton(explorer: self, text: name, imageView: UIImageView(image: UIImage(named: name)))
    var limbos: [UIView] = []
    
    func openExplorer(view: UIView) {}
    func closeExplorer() {}
    
    func createLimbos() {}
    func dimLimbos(_ limbos: [UIView]) {}
    func brightenLimbos(_ limbos: [UIView]) {}
    
	func onOpen() {}
	func onOpening() {}
	func onOpened() {}
	func onClose() {}
}
