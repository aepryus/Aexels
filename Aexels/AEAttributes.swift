//
//  AEAttributes.swift
//  Aexels
//
//  Created by Joe Charlier on 1/2/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import UIKit

class AEAttributes {
	var attributes = [String:Any]()
	var font: UIFont {
		set {
			attributes[NSFontAttributeName] = newValue
		}
		get {
			return attributes[NSFontAttributeName] as! UIFont
		}
	}
	var color: UIColor {
		set {
			attributes[NSForegroundColorAttributeName] = newValue
		}
		get {
			return attributes[NSForegroundColorAttributeName] as! UIColor
		}
	}
	var alignment: NSTextAlignment {
		set {
			let style: NSMutableParagraphStyle = attributes[NSParagraphStyleAttributeName] as! NSMutableParagraphStyle
			style.alignment = newValue
		}
		get {
			return (attributes[NSParagraphStyleAttributeName] as! NSMutableParagraphStyle).alignment
		}
	}
	
	init () {
		self.font = UIFont.aexelFont(size: 12)
		self.color = UIColor.white
		
		let style = NSMutableParagraphStyle()
		style.lineBreakMode = .byWordWrapping
		attributes[NSParagraphStyleAttributeName] = style
	}
}
