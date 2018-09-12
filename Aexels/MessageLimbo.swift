//
//  MessageView.swift
//  Aexels
//
//  Created by Joe Charlier on 1/2/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import UIKit
import OoviumLib

class MessageLimbo: Limbo {
	let axMaskView = AXMaskView()
	let scrollView = UIScrollView()
	let imageView = UIImageView()
	var onTap: (()->())?

	var key: String = ""
	var text: String = ""
	
	override init() {
		super.init()

		imageView.isUserInteractionEnabled = false
		
		scrollView.addSubview(imageView)
		
		addSubview(scrollView)

		axMaskView.frame = bounds
		axMaskView.content = scrollView
		addSubview(axMaskView)
		
		let gesture = UITapGestureRecognizer(target: self, action: #selector(tap))
		addGestureRecognizer(gesture)
	}
	required init? (coder aDecoder: NSCoder) {fatalError()}
	
	func load() {
		self.text = NSLocalizedString(key, comment: "")

		let pen = Pen(font: UIFont(name: "Verdana", size: 18*s)!)
		pen.alignment = .left

		let p: CGFloat = 10*s
		let w = self.scrollView.bounds.size.width - p*2
		
		let size = (self.text as NSString).boundingRect(with: CGSize(width: w, height: 9999), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: pen.attributes, context: nil).size
		
		let h = size.height
		
		UIGraphicsBeginImageContextWithOptions(CGSize(width: w, height: h), false, UIScreen.main.scale)
		guard let c = UIGraphicsGetCurrentContext() else {return}
		c.saveGState()
		c.setShadow(offset: CGSize(width: 2*s, height: 2*s), blur: 2*s)
		c.setFillColor(UIColor.white.cgColor)
		(text as NSString).draw(in: CGRect(x: 0, y: 0, width: w, height: h), withAttributes: pen.attributes)
		c.restoreGState()
		
		let image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		
		imageView.frame = CGRect(x: p, y: p, width: w, height: h)
		imageView.image = image

		scrollView.contentSize = CGSize(width: w+2*p, height: max(h+2*p,self.scrollView.bounds.size.height+1))
		scrollView.contentOffset = CGPoint.zero
	}
	
	override func applyMask (_ mask: CGPath) {
		axMaskView.path = mask
	}
	
// Events ==========================================================================================
	@objc func tap() {
		if onTap != nil {onTap!()}
	}
	
// UIView ==========================================================================================
	override var frame: CGRect {
		didSet {
			axMaskView.frame = bounds
			scrollView.frame = self.bounds.insetBy(dx: 10*s, dy: 10*s)
			if frame.size != CGSize.zero {load()}
		}
	}
}
