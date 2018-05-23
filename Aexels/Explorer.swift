//
//  Explorer.swift
//  Aexels
//
//  Created by Joe Charlier on 1/4/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import UIKit

enum D {
	case dim320x480, dim320x568, dim375x667, dim414x736, dim375x812, dim1024x768, dim1112x834, dim1366x1024, dimOther
	
	static func current() -> D {
		let size = UIScreen.main.bounds.size
		if size.width == 320 && size.height == 480 {return .dim320x480}
		if size.width == 320 && size.height == 568 {return .dim320x568}
		if size.width == 375 && size.height == 667 {return .dim375x667}
		if size.width == 414 && size.height == 736 {return .dim414x736}
		if size.width == 375 && size.height == 812 {return .dim375x812}
		if size.width == 1024 && size.height == 768 {return .dim1024x768}
		if size.width == 1112 && size.height == 834 {return .dim1112x834}
		if size.width == 1366 && size.height == 1024 {return .dim1366x1024}
		return .dimOther
	}
	static var width: CGFloat {
		return UIScreen.main.bounds.size.width
	}
	static var height: CGFloat {
		return UIScreen.main.bounds.size.height
	}
	static var s: CGFloat {
		if D.current().iPhone {
			return D.width / 375
		} else {
			return D.width / 1024
		}
	}
	
	var iPhone: Bool {
		return self == .dim320x480
			|| self == .dim320x568
			|| self == .dim375x667
			|| self == .dim414x736
			|| self == .dim375x812
	}
	var iPad: Bool {
		return !iPhone
	}
}

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
