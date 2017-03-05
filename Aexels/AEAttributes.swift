//
//  AEAttributes.swift
//  Aexels
//
//  Created by Joe Charlier on 2/12/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import UIKit

class AEAttributes {
	var attributes: [String:Any]
	
	var font: UIFont {
		set {attributes[NSFontAttributeName] = newValue}
		get {return attributes[NSFontAttributeName] as! UIFont}
	}
	var color: UIColor {
		set {attributes[NSForegroundColorAttributeName] = newValue}
		get {return attributes[NSForegroundColorAttributeName] as! UIColor}
	}
	var alignment: NSTextAlignment {
		set {
			let style: NSMutableParagraphStyle = attributes[NSParagraphStyleAttributeName] as! NSMutableParagraphStyle
			style.alignment = newValue
		}
		get {
			let style: NSMutableParagraphStyle = attributes[NSParagraphStyleAttributeName] as! NSMutableParagraphStyle
			return style.alignment
		}
	}
	
	init () {
		attributes = [String:Any]()
		
		let style = NSMutableParagraphStyle()
		style.lineBreakMode = .byWordWrapping
		attributes[NSParagraphStyleAttributeName] = style
		
		font = UIFont(name: "Trajan Pro", size: 12)!
		color = UIColor.white
	}
}
