//
//  Explorer.swift
//  Aexels
//
//  Created by Joe Charlier on 1/4/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import OoviumLib
import UIKit

//enum D {
//	case dim320x480, dim320x568, dim375x667, dim414x736, dim375x812, dim1024x768, dim1112x834, dim1366x1024, dimOther
//	
//	static func current() -> D {
//		let size = UIScreen.main.bounds.size
//		if size.width == 320 && size.height == 480 {return .dim320x480}
//		if size.width == 320 && size.height == 568 {return .dim320x568}
//		if size.width == 375 && size.height == 667 {return .dim375x667}
//		if size.width == 414 && size.height == 736 {return .dim414x736}
//		if size.width == 375 && size.height == 812 {return .dim375x812}
//		if size.width == 1024 && size.height == 768 {return .dim1024x768}
//		if size.width == 1112 && size.height == 834 {return .dim1112x834}
//		if size.width == 1366 && size.height == 1024 {return .dim1366x1024}
//		return .dimOther
//	}
//	static var width: CGFloat {
//		return UIScreen.main.bounds.size.width
//	}
//	static var height: CGFloat {
//		return UIScreen.main.bounds.size.height
//	}
//	static var s: CGFloat {
//		if D.current().iPhone {
//			return D.width / 375
//		} else {
//			return D.width / 1024
//		}
//	}
//	
//	var iPhone: Bool {
//		return self == .dim320x480
//			|| self == .dim320x568
//			|| self == .dim375x667
//			|| self == .dim414x736
//			|| self == .dim375x812
//	}
//	var iPad: Bool {
//		return !iPhone
//	}
//}

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
			case .dim320x568:	layout320x568()
			case .dim375x667:	layout375x667()
			case .dim414x736:	layout414x736()
			case .dim1024x768:	layout1024x768()
			case .dim1112x834:	layout1112x834()
			case .dim1366x1024:	layout1366x1024()
			default:			layout375x667()
		}
	}
	
	func layout320x568() {
		layout375x667()
	}
	func layout375x667() {}
	func layout414x736() {
		layout320x568()
	}
	func layout1024x768() {}
	func layout1112x834() {
		layout1024x768()
	}
	func layout1366x1024() {
		layout1024x768()
	}

	func dimLimbos (_ limbos: [Limbo]) {
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
	func brightenLimbos (_ limbos: [Limbo]) {
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
