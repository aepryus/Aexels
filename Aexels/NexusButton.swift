//
//  NexusButton.swift
//  Aexels
//
//  Created by Joe Charlier on 1/2/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import Acheron
import UIKit
import OoviumLib

class NexusButton: UIControl {
	var text: String = ""
	
	init(text: String) {
		self.text = text
		super.init(frame: CGRect.zero)
		backgroundColor = UIColor.clear
	}
	required init?(coder aDecoder: NSCoder) {fatalError()}
	
// UIView ==========================================================================================
	override var isHighlighted: Bool {
		didSet {setNeedsDisplay()}
	}
    override func draw(_ rect: CGRect) {
		let c = UIGraphicsGetCurrentContext()!
		c.setShadow(offset: CGSize.zero, blur: 4, color: UIColor(white: 0.2, alpha: 0.8).cgColor)
		let pen = Pen(font: UIFont.aexel(size: 24*s), color: (state == .normal ? UIColor.black : UIColor.white), alignment: .right)
		(text as NSString).draw(in: rect.insetBy(dx: 0, dy: (rect.height-24*s)/2), pen: pen)
    }
}
