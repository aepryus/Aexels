//
//  Explorer.swift
//  Aexels
//
//  Created by Joe Charlier on 1/4/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import UIKit

class Explorer {
	let name: String
	let key: String
	let canExplore: Bool
	var limboViews = [LimboView]()
	let close = LimboView()
	
	init (name: String, key: String, canExplore: Bool) {
		self.name = name
		self.key = key
		self.canExplore = canExplore
	}
	
	func openExplorer () {
		UIView.animate(withDuration: 0.2) {
			for view in self.limboViews {
				view.alpha = 1
			}
		}
	}
	func closeExplorer () {
		UIView.animate(withDuration: 0.2) {
			for view in self.limboViews {
				view.alpha = 0
			}
		}
	}

	func loadView (_ view: UIView) {
		close.frame = CGRect(x: 1024-462-5+286, y: 20+462+176, width: 176, height: 110)
		close.alpha = 0
		limboViews.append(close)
		
		let button = UIButton(type: .custom)
		button.setTitle("Close", for: .normal)
		button.titleLabel!.font = UIFont.aexelFont(size: 24)
		button.addClosure({
			self.closeExplorer()
			Aexels.nexus.brightenNexus()
		}, controlEvents: .touchUpInside)
		close.content = button
		
		for limboView in limboViews {
			limboView.alpha = 0
			view.addSubview(limboView)
		}

		openExplorer()
	}
}
