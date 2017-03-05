//
//  UIView+AE.swift
//  Aexels
//
//  Created by Joe Charlier on 2/18/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import UIKit

extension UIView {
	
	private var parent: CGSize {
		if let parent = superview {
			return parent.bounds.size
		} else {
			return UIScreen.main.bounds.size
		}
	}
	
	func center (offset: UIOffset, size: CGSize) {
		self.frame = CGRect(x: (parent.width-size.width)/2+offset.horizontal, y: (parent.height-size.height)/2+offset.vertical, width: size.width, height: size.height)
	}
	func right (offset: UIOffset, size: CGSize) {
		self.frame = CGRect(x: parent.width-size.width+offset.horizontal, y: (parent.height-size.height)/2+offset.vertical, width: size.width, height: size.height)
	}
	func left (offset: UIOffset, size: CGSize) {
		self.frame = CGRect(x: offset.horizontal, y: (parent.height-size.height)/2+offset.vertical, width: size.width, height: size.height)
	}
	func top (offset: UIOffset, size: CGSize) {
		self.frame = CGRect(x: (parent.width-size.width)/2+offset.horizontal, y: offset.vertical, width: size.width, height: size.height)
	}
	func bottom (offset: UIOffset, size: CGSize) {
		self.frame = CGRect(x: (parent.width-size.width)/2+offset.horizontal, y: parent.height-size.height+offset.vertical, width: size.width, height: size.height)
	}
	func topLeft (offset: UIOffset, size: CGSize) {
		self.frame = CGRect(x: offset.horizontal, y: offset.vertical, width: size.width, height: size.height)
	}
	func topRight (offset: UIOffset, size: CGSize) {
		self.frame = CGRect(x: parent.width-size.width+offset.horizontal, y: offset.vertical, width: size.width, height: size.height)
	}
	func bottomLeft (offset: UIOffset, size: CGSize) {
		self.frame = CGRect(x: offset.horizontal, y: parent.height-size.height+offset.vertical, width: size.width, height: size.height)
	}
	func bottomRight (offset: UIOffset, size: CGSize) {
		self.frame = CGRect(x: parent.width-size.width+offset.horizontal, y: parent.height-size.height+offset.vertical, width: size.width, height: size.height)
	}
	
	var top: CGFloat {
		return frame.origin.y
	}
	var bottom: CGFloat {
		return frame.origin.y + frame.size.height
	}
	var left: CGFloat {
		return frame.origin.x
	}
	var right: CGFloat {
		return frame.origin.x + frame.size.width
	}
	var width: CGFloat {
		return bounds.size.width
	}
	var height: CGFloat {
		return bounds.size.height
	}
}
