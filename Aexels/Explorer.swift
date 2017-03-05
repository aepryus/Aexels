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

	private var limboViews = [LimboView]()
	
	init (name: String, key: String, canExplore: Bool) {
		self.name = name
		self.key = key
		self.canExplore = canExplore
	}
	
	func createLimbos () -> [LimboView] {
		return []
	}

	func openExplorer (view: UIView) {
		let close = LimboView()
		close.frame = CGRect(x: 1024-462-5+286, y: 20+462+176, width: 176, height: 110)
		close.alpha = 0
		
		let button = UIButton(type: .custom)
		button.setTitle("Close", for: .normal)
		button.titleLabel!.font = UIFont.aexelFont(size: 24)
		button.addClosure({
			self.closeExplorer()
			Aexels.nexus.brightenNexus()
		}, controlEvents: .touchUpInside)
		close.content = button
		
		self.limboViews.append(close)
		self.limboViews.append(contentsOf: createLimbos())

		for limboView in limboViews {
			limboView.alpha = 0
			view.addSubview(limboView)
		}

		UIView.animate(withDuration: 0.2) {
			for view in self.limboViews {
				view.alpha = 1
			}
		}
	}
	private func closeExplorer () {
		UIView.animate(withDuration: 0.2, animations: {
			UIView.animate(withDuration: 0.2) {
				for view in self.limboViews {
					view.alpha = 0
				}
			}
		}) { (canceled) in
			self.onClose()
			for view in self.limboViews {
				view.removeFromSuperview()
			}
			self.limboViews.removeAll()
		}
	}
	
// Events ==========================================================================================
	func onClose () {}
}
