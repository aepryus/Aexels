//
//  NexusLabel.swift
//  Aexels
//
//  Created by Joe Charlier on 1/2/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import Acheron
import UIKit

class NexusLabel: AEView {
	let text: String
	let size: CGFloat
	
	init(text: String, size: CGFloat) {
		self.text = text
		self.size = size
		super.init()
		backgroundColor = UIColor.clear
	}
	
// UIView ==========================================================================================
	override func draw(_ rect: CGRect) {
		let c = UIGraphicsGetCurrentContext()!
		c.setShadow(offset: CGSize.zero, blur: 4, color: UIColor(white: 0.2, alpha: 0.8).cgColor)
		let pen = Pen(font: UIFont.ax(size: size), color: .black.tint(0.25), alignment: .right)
		(text as NSString).draw(in: rect.insetBy(dx: 4, dy: 4), withAttributes: pen.attributes)
	}
}
