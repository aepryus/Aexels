//
//  Explorer.swift
//  Aexels
//
//  Created by Joe Charlier on 1/4/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import Acheron
import OoviumLib
import UIKit

class Explorer {
	let parent: UIView
	let name: String
	let key: String
	let canExplore: Bool
	var layedOut: Bool = false

	var limbos = [UIView]()
	
	var s: CGFloat {
		return Screen.s
	}
	
	init(parent: UIView, name: String, key: String, canExplore: Bool) {
		self.parent = parent
		self.name = name
		self.key = key
		self.canExplore = canExplore
	}
	
	func closeSize() -> CGSize {
		return CGSize(width: 139, height: 60)
	}
	
	func createLimbos() {}

	func layout() {
		switch Screen.this {
			case .dim320x480:	layout320x480()
			case .dim320x568:	layout320x568()
			case .dim375x667:	layout375x667()
			case .dim375x812:	layout375x812()
			case .dim414x736:	layout414x736()
			case .dim414x896:	layout414x896()
			case .dim1024x768:	layout1024x768()
			case .dim1112x834:	layout1112x834()
			case .dim1194x834:	layout1194x834()
			case .dim1366x1024:	layout1366x1024()
			case .dimOther:		layout375x667()
		}
	}
	
	func layout320x480() {layout375x667()}

	func layout320x568() {layout375x667()}
	func layout375x667() {}
	func layout414x736() {layout375x667()}

	func layout375x812() {layout375x667()}
	func layout414x896() {layout375x812()}

	func layout1024x768() {}
	func layout1112x834() {layout1024x768()}
	func layout1366x1024() {layout1024x768()}

	func layout1194x834() {layout1024x768()}

	func dimLimbos(_ limbos: [Limbo]) {
		UIView.animate(withDuration: 0.2, animations: { 
			for limbo in limbos {
				limbo.alpha = 0
			}
		}) { (finished: Bool) in
			guard finished else {return}
			for limbo in limbos {
				limbo.removeFromSuperview()
			}
		}
	}
	func brightenLimbos(_ limbos: [Limbo]) {
		for limbo in limbos {
			parent.addSubview(limbo)
		}
		UIView.animate(withDuration: 0.2) {
			for limbo in limbos {
				limbo.alpha = 1
			}
		}
	}
	
	func openExplorer (view: UIView) {
		if !layedOut {
			createLimbos()
			layout()
			layedOut = true
		}

		for limbo in limbos {
			limbo.alpha = 0
			view.addSubview(limbo)
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
	func closeExplorer() {
		UIView.animate(withDuration: 0.2, animations: {
			for view in self.limbos {
				view.alpha = 0
			}
		}) { (finished: Bool) in
			self.onClose()
			for view in self.limbos {
				view.removeFromSuperview()
			}
		}
	}
	
// Events ==========================================================================================
	func onOpen() {}
	func onOpening() {}
	func onOpened() {}
	func onClose() {}
}
