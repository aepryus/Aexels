//
//  MessageView.swift
//  Aexels
//
//  Created by Joe Charlier on 1/2/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import Acheron
import OoviumKit
import UIKit

class MessageLimbo: Limbo {
	let axMaskView = AXMaskView()
	let scrollView = UIScrollView()
	let imageView = UIImageView()
	var onTap: (()->())?

	var key: String = ""
	var text: NSAttributedString = NSAttributedString(string: "")
	
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
	required init?(coder aDecoder: NSCoder) {fatalError()}
	
	func load() {
		let template = key.localized
		var texts: [String] = []
		var images: [UIImage] = []

		var i: Int = 0
		while i < template.count {
			if let left: Int = template.loc(of: "<<", after: i), let right: Int = template.loc(of: ">>", after: left) {
				texts.append(template[i...left-1])
				images.append(UIImage(named: template[left+2...right-1])!)
				i = right+2
			} else {
				texts.append(template[i...template.count-1])
				i = template.count
			}
		}

		let p: CGFloat = 10*s
		let w = self.scrollView.bounds.size.width - p*2
		var y: CGFloat = 0
		var tHs: [CGFloat] = []
		var iHs: [CGFloat] = []

		var h: CGFloat = 0

		let pen = Pen(font: UIFont(name: "Verdana", size: 18*s)!, color: .white, alignment: .left)

		for i in 0..<texts.count {
			let height: CGFloat = texts[i].boundingRect(with: CGSize(width: w, height: 19999), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: pen.attributes, context: nil).size.height
			h += height
			tHs.append(height)
			if i < images.count {
                let w: CGFloat = min(images[i].size.width, width * 0.84)
                let r: CGFloat = w / images[i].size.width
				let height: CGFloat = images[i].size.height * r
				h += height
				iHs.append(height)
			}
		}

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: w, height: h))
        let image = renderer.image { (_: UIGraphicsImageRendererContext) in
            guard let c = UIGraphicsGetCurrentContext() else { return }
            c.saveGState()
            c.setShadow(offset: CGSize(width: 2*s, height: 2*s), blur: 2*s)
            c.setFillColor(UIColor.white.cgColor)

            for i in 0..<texts.count {
                texts[i].draw(in: CGRect(x: 0, y: y, width: w, height: tHs[i]), pen: pen)
                y += tHs[i]
                if i < images.count {
                    let w: CGFloat = min(images[i].size.width, width * 0.84)
                    let r: CGFloat = w / images[i].size.width
                    let size: CGSize = CGSize(width: images[i].size.width * r, height: images[i].size.height * r)
                    images[i].draw(in: CGRect(origin: CGPoint(x: Screen.iPhone ? 0 : 50*s, y: y), size: size))
                    y += iHs[i]
                }
            }

            c.restoreGState()
        }

		imageView.frame = CGRect(x: p, y: p, width: w, height: h)
		imageView.image = image

		scrollView.contentSize = CGSize(width: w+2*p, height: max(h+2*p,self.scrollView.bounds.size.height+1))
		scrollView.contentOffset = CGPoint.zero
	}
	
	override func applyMask(_ mask: CGPath) {
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
