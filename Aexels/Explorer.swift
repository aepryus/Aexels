//
//  Explorer.swift
//  Aexels
//
//  Created by Joe Charlier on 1/4/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import UIKit

class Explorer {
	let view: UIView
	let name: String
	let key: String
	let canExplore: Bool

	var limboViews = [LimboView]()
	
	init (view: UIView, name: String, key: String, canExplore: Bool) {
		self.view = view
		self.name = name
		self.key = key
		self.canExplore = canExplore
	}
	
	func closeSize() -> CGSize {
		return CGSize(width: 139, height: 60)
	}
	func createLimbos() -> [LimboView] {
		return []
	}

	func iPadLayout() {
	}
	
	func dimLimbos (_ limbos: [LimboView]) {
		UIView.animate(withDuration: 0.2, animations: { 
			for limbo in limbos {
				limbo.alpha = 0
			}
		}) { (canceled) in
			for limbo in limbos {
				limbo.removeFromSuperview()
			}
		}
	}
	func brightenLimbos (_ limbos: [LimboView]) {
		for limbo in limbos {
			view.addSubview(limbo)
		}
		UIView.animate(withDuration: 0.2) {
			for limbo in limbos {
				limbo.alpha = 1
			}
		}
	}
	
	func openExplorer (view: UIView) {
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
	func closeExplorer() {
		UIView.animate(withDuration: 0.2, animations: {
			for view in self.limboViews {
				view.alpha = 0
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
	func onClose() {}
}
