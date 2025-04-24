//
//  Switcher.swift
//  Aexels
//
//  Created by Joe Charlier on 4/24/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

import Acheron
import UIKit

class Switcher: UIView, UIScrollViewDelegate {
    var _pageNo: Int = 0
    var pages: [UILabel] = [] {
        didSet {
            pw = width / CGFloat(max(pages.count,1))
            pagesView.subviews.forEach { $0.removeFromSuperview() }
            pages.forEach {
                $0.isUserInteractionEnabled = false
                pagesView.addSubview($0)
            }
            snapToPageNo(0)
        }
    }
    weak var scrollView: UIScrollView? = nil {
        didSet {scrollView?.delegate = self}
    }
    
    var onPageChange: (UIView)->()
    
    private let pagesView: UIView = UIView()
    private let backView: UIView = UIView()
    private let thumb: UIView
    
    private var dragging: Bool = false
    private var numb: Bool = true
    
    private var pw: CGFloat = 80*Screen.s
    
    static private let unselectedPen: Pen = {
        return Pen(font: UIFont.avenir(size: 15*Screen.s), color: UIColor.black.tint(0.6), alignment: .center)
    }()
    static private let selectedPen: Pen = {
        return Pen(font: UIFont.avenir(size: 15*Screen.s), color: UIColor.blue, alignment: .center)
    }()
    
    init (_ onPageChange: @escaping (UIView)->()) {
        self.onPageChange = onPageChange
        
        thumb = UIView()
        
        super.init(frame: CGRect(x: 0, y: 0, width: 351*Screen.s, height: 22*Screen.s))
        
        isUserInteractionEnabled = true
        
        backView.layer.backgroundColor = UIColor(rgb: 0xCECDCC).cgColor
        backView.layer.cornerRadius = 11*s
        addSubview(backView)
        
        addSubview(thumb)
        
        pagesView.isUserInteractionEnabled = false
        addSubview(pagesView)
        
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap)))
        thumb.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(onPan)))
    }
    convenience init() {
        self.init({String in})
    }
    required init? (coder aDecoder: NSCoder) {fatalError()}
    
    func generatePages(_ names: [String]) {
        var labels: [UILabel] = []
        for name in names {
            let label = UILabel()
            label.text = name
            label.pen = Switcher.unselectedPen
            labels.append(label)
        }
        pages = labels
        setNeedsLayout()
    }
    
    var pageNo: Int {
        set {
            guard pages.count > 0 else {return}
            if _pageNo != newValue {
                colorSelected(oldPage: pageNo, newPage: newValue)
                _pageNo = newValue
                onPageChange(self.pages[_pageNo])
            }
            UIView.animate(withDuration: 0.2) {
                self.thumb.frame = CGRect(x: CGFloat(self.pageNo)*self.pw, y: 0, width: self.pw, height: self.height)
            }
            if let scrollView = scrollView {scrollView.setContentOffset(CGPoint(x: CGFloat(_pageNo)*scrollView.width, y: 0), animated: true)}
        }
        get {return _pageNo}
    }
    
    private func renderThumb() {
        thumb.subviews.forEach { $0.removeFromSuperview() }
        thumb.bounds = CGRect(x: 0, y: 0, width: pw, height: height)
        let view = UIView()
        view.layer.backgroundColor = UIColor(rgb: 0xF2F2F2).cgColor
        view.layer.cornerRadius = 9.5*s
        thumb.addSubview(view)
        view.center(width: pw-3*s, height: height-3*s)
    }
    
    func snapToPageNo (_ pageNo: Int) {
        guard pageNo < pages.count else {return}
        colorSelected(oldPage: _pageNo, newPage: pageNo)
        if _pageNo != pageNo {
            _pageNo = pageNo
            onPageChange(self.pages[_pageNo])
        }
        self.thumb.frame = CGRect(x: CGFloat(self.pageNo)*self.pw, y: 0, width: self.pw, height: self.height)
        if let scrollView = scrollView {scrollView.setContentOffset(CGPoint(x: CGFloat(_pageNo)*scrollView.width, y: 0), animated: false)}
    }
    
    func colorSelected(oldPage: Int, newPage: Int) {
        guard pages.count > 0 else {return}
        if oldPage < pages.count {pages[oldPage].pen = Switcher.unselectedPen}
        pages[newPage].pen = Switcher.selectedPen
    }
    
    // Events ==========================================================================================
    @objc func onTap (_ gesture: UITapGestureRecognizer) {
        pageNo = min(max(Int(gesture.location(in: self).x/pw),0),pages.count-1)
    }
    var startX: CGFloat = 0
    @objc func onPan (_ gesture: UIPanGestureRecognizer) {
        if gesture.state == .began {
            startX = thumb.frame.origin.x
        }
        var x = startX + gesture.translation(in: self).x
        if gesture.state == .ended {
            pageNo = min(max(Int((x+pw/2)/pw),0),pages.count-1)
        } else {
            x = min(max(x,0),width-thumb.width)
            thumb.frame = CGRect(x: x, y: 0, width: pw, height: height)
        }
    }
    
    // UIView ==========================================================================================
    override func layoutSubviews() {
        backView.frame = bounds
        
        pw = width / CGFloat(max(pages.count,1))
        pagesView.frame = bounds
        
        for (i, page) in pages.enumerated() {
            page.frame = CGRect(x: CGFloat(i)*pw, y: 0, width: pw, height: height)
        }
        renderThumb()
        snapToPageNo(pageNo)
    }
    
    // UIScrollViewDelegate ============================================================================
    func scrollViewDidScroll (_ scrollView: UIScrollView) {
        guard !numb else {return}
        let x: CGFloat = max(0, min(width-pw, scrollView.contentOffset.x / scrollView.contentSize.width * width))
        thumb.frame = CGRect(x: x, y: thumb.top, width: thumb.width, height: thumb.height)
        let newPage = Int((scrollView.contentOffset.x+scrollView.width/2)/scrollView.width)
        colorSelected(oldPage: _pageNo, newPage: newPage)
        _pageNo = newPage
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if !dragging {numb = true}
    }
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        dragging = true
        numb = false
    }
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        dragging = false
    }
}
