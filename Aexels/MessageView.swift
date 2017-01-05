//
//  MessageView.swift
//  Aexels
//
//  Created by Joe Charlier on 1/2/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import UIKit

class MessageView: LimboView {
	let axMaskView = MaskView()
	let scrollView = UIScrollView()
	let imageView = UIImageView()

	var key: String = ""
	var text: String = ""
	
	override init () {
		super.init()

		let x: CGFloat = 340
		let m: CGFloat = 52
		let w: CGFloat = 1024-x-m
		frame = CGRect(x: 1024-w-5, y: 20, width: w, height: 768-20)

		imageView.isUserInteractionEnabled = false
		
		scrollView.addSubview(imageView)
		addSubview(scrollView)
		axMaskView.frame = bounds
		axMaskView.content = scrollView
		scrollView.frame = bounds.insetBy(dx: 10, dy: 10)
		addSubview(axMaskView)
		
		let gesture = UITapGestureRecognizer(target: self, action: #selector(onTap))
		addGestureRecognizer(gesture)
		
	}
	required init? (coder aDecoder: NSCoder) {super.init(coder: aDecoder)}
	
	func load (key: String) {
		self.key = key
		self.text = NSLocalizedString(key, comment: "")

		let format = Format()
		format.font = UIFont(name: "Verdana", size: 18)!
		format.alignment = .left

		let p: CGFloat = 10
		let w = self.scrollView.bounds.size.width - p*2
		
		let size = (self.text as NSString).boundingRect(with: CGSize(width: w, height: 9999), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: format.attributes, context: nil).size
		
		let h = size.height
		
		UIGraphicsBeginImageContextWithOptions(CGSize(width: w, height: h), false, UIScreen.main.scale)
		let c = UIGraphicsGetCurrentContext()!
		c.saveGState()
		c.setShadow(offset: CGSize(width: 2, height: 2), blur: 2)
		c.setFillColor(UIColor.white.cgColor)
		(text as NSString).draw(in: CGRect(x: 0, y: 0, width: w, height: h), withAttributes: format.attributes)
		c.restoreGState()
		
		let image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		
		imageView.frame = CGRect(x: p, y: p, width: w, height: h)
		imageView.image = image

		scrollView.contentSize = CGSize(width: w+2*p, height: max(h+2*p,self.scrollView.bounds.size.height+1))
		scrollView.contentOffset = CGPoint.zero
	}
	
	override func applyMask () {
		axMaskView.path = limboPath.maskPath
	}
	
// Events ==========================================================================================
	func onTap () {
		UIView.animate(withDuration: 0.2) {
			self.alpha = 0
		}
	}
}
