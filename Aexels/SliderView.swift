//
//  SliderView.swift
//  Aexels
//
//  Created by Joe Charlier on 3/12/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import OoviumLib
import UIKit

class SliderView: UIView, UIScrollViewDelegate {
	var _pageNo: Int = 0
	var _pages: [String] = []
	
	let onPageChange: (String)->()
	
	private let labels: UIView
	private let thumb: UIView
	private var labelViews: [UIView] = []
	
	private var dragged: Bool = false
	private var numb: Bool = true
	
	private var ph: CGFloat = 80
	
	init (_ onPageChange: @escaping (String)->()) {
		self.onPageChange = onPageChange
		
		self.thumb = UIView()
		self.thumb.backgroundColor = OOColor.lavender.uiColor.withAlphaComponent(0.5)
		self.thumb.layer.cornerRadius = 8
		self.thumb.layer.borderWidth = 1
		self.thumb.layer.borderColor = UIColor.white.cgColor
		
		self.labels = UIView()
		self.labels.isUserInteractionEnabled = false
		
		super.init(frame: CGRect.zero)

		addSubview(self.thumb)
		addSubview(self.labels)
		
		addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap)))
		thumb.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(onPan)))
	}
	required init? (coder aDecoder: NSCoder) {fatalError()}
	
	var pageNo: Int {
		set {
			if _pageNo != newValue {
				_pageNo = newValue
				onPageChange(self.pages[_pageNo])
			}
			UIView.animate(withDuration: 0.2) {
				self.thumb.frame = CGRect(x: 0, y: CGFloat(self.pageNo)*self.ph, width: self.width, height: self.ph)
			}
		}
		get {return _pageNo}
	}
	var pages: [String] {
		set {
			_pages = newValue
			ph = height / CGFloat(_pages.count)
			labelViews.removeAll()
			for page in _pages {
				let label = UILabel()
				label.text = page
				label.font = UIFont.aexel(size: 17)
				label.textColor = UIColor.white
				label.textAlignment = .center
				labelViews.append(label)
				labels.addSubview(label)
			}
		}
		get {return _pages}
	}
	
	func snapToPageNo (_ pageNo: Int) {
		_pageNo = pageNo
		thumb.frame = CGRect(x: 0, y: CGFloat(pageNo)*ph, width: width, height: ph)
	}
	
// Events ==========================================================================================
	@objc func onTap (_ gesture: UITapGestureRecognizer) {
		pageNo = min(max(Int(gesture.location(in: self).y/ph),0),pages.count-1)
	}
	static var startY: CGFloat = 0
	@objc func onPan (_ gesture: UIPanGestureRecognizer) {
		if gesture.state == .began {
			SliderView.startY = thumb.frame.origin.y
		}
		var y = SliderView.startY + gesture.translation(in: self).y
		if gesture.state == .ended {
			pageNo = min(max(Int((y+ph/2)/ph),0),pages.count-1)
		} else {
			y = min(max(y,0),height-thumb.height)
			thumb.frame = CGRect(x: 0, y: y, width: width, height: ph)
		}
	}
	
// UIView ==========================================================================================
	override func layoutSubviews() {
		ph = height / CGFloat(_pages.count)
		labels.frame = bounds
		for i in 0..<pages.count {
			labelViews[i].frame = CGRect(x: 0, y: ph*CGFloat(i), width: width, height: ph)
		}
	}
	
// UIScrollViewDelegate ============================================================================
	func scrollViewDidScroll (_ scrollView: UIScrollView) {
		guard !numb else {return}
		let y: CGFloat = scrollView.contentOffset.y / scrollView.contentSize.height * height
		thumb.frame = CGRect(x: thumb.left, y: y, width: thumb.width, height: thumb.height)
		pageNo = Int((scrollView.contentOffset.y+scrollView.height/2)/scrollView.height)
	}
	func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
		if dragged {
			dragged = false
			numb = true
		}
	}
	func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
		dragged = true
		numb = false
	}
//	func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {}
	
// UIView ==========================================================================================
	override var frame: CGRect {
		didSet {
			guard height != 0 else {return}
			ph = height / CGFloat(_pages.count)
			thumb.frame = CGRect(x: 0, y: CGFloat(pageNo)*ph, width: width, height: ph)
		}
	}
}
