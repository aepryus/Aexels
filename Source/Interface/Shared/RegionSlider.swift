//
//  RegionSlider.swift
//  Aexels
//
//  Horizontal page picker.  Ported from Evolizer's RegionSlider —
//  Aexels palette (white text on black, Verdana) instead of evolizer
//  green / Avenir.  Acts as a 2-or-more-position radio control with a
//  sliding thumb and tappable labels.
//

import Acheron
import UIKit

class RegionSlider: UIView {
    private var _pageNo: Int = 0
    private var _pages: [String] = []

    let onPageChange: (String)->()

    private let labels: UIView = UIView()
    private let thumb: UIView = UIView()
    private var labelViews: [UILabel] = []

    private var pw: CGFloat = 80*Screen.s

    init(_ onPageChange: @escaping (String)->()) {
        self.onPageChange = onPageChange

        super.init(frame: .zero)

        thumb.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        thumb.layer.cornerRadius = 8*Screen.s
        thumb.layer.borderWidth = 2*Screen.s
        thumb.layer.borderColor = UIColor.white.cgColor

        labels.isUserInteractionEnabled = false

        addSubview(thumb)
        addSubview(labels)

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap)))
        thumb.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(onPan)))
    }
    required init?(coder: NSCoder) { fatalError() }

    var pageNo: Int {
        set {
            if _pageNo != newValue {
                _pageNo = newValue
                onPageChange(_pages[_pageNo])
            }
            refreshLabelTints()
            UIView.animate(withDuration: 0.2) {
                self.thumb.frame = CGRect(x: CGFloat(self.pageNo)*self.pw, y: 0, width: self.pw, height: self.height)
            }
        }
        get { _pageNo }
    }
    var pages: [String] {
        set {
            _pages = newValue
            pw = _pages.isEmpty ? width : width / CGFloat(_pages.count)
            labelViews.forEach { $0.removeFromSuperview() }
            labelViews.removeAll()
            for page in _pages {
                let label: UILabel = UILabel()
                label.text = page
                label.font = .verdana(size: 15*Screen.s)
                label.textAlignment = .center
                labelViews.append(label)
                labels.addSubview(label)
            }
            refreshLabelTints()
            setNeedsLayout()
        }
        get { _pages }
    }

    private func refreshLabelTints() {
        for (i, label) in labelViews.enumerated() {
            label.textColor = i == _pageNo ? UIColor.white : UIColor.white.withAlphaComponent(0.45)
        }
    }

    func snapToPageNo(_ pageNo: Int) {
        _pageNo = pageNo
        refreshLabelTints()
        thumb.frame = CGRect(x: CGFloat(pageNo)*pw, y: 0, width: pw, height: height)
    }

// Events ==========================================================================================
    @objc func onTap(_ gesture: UITapGestureRecognizer) {
        guard !_pages.isEmpty else { return }
        pageNo = min(max(Int(gesture.location(in: self).x/pw), 0), _pages.count-1)
    }
    private static var startX: CGFloat = 0
    @objc func onPan(_ gesture: UIPanGestureRecognizer) {
        guard !_pages.isEmpty else { return }
        if gesture.state == .began { RegionSlider.startX = thumb.frame.origin.x }
        var x: CGFloat = RegionSlider.startX + gesture.translation(in: self).x
        if gesture.state == .ended {
            pageNo = min(max(Int((x+pw/2)/pw), 0), _pages.count-1)
        } else {
            x = min(max(x, 0), width-thumb.width)
            thumb.frame = CGRect(x: x, y: 0, width: pw, height: height)
        }
    }

// UIView ==========================================================================================
    override func layoutSubviews() {
        guard !_pages.isEmpty else { return }
        pw = width / CGFloat(_pages.count)
        labels.frame = bounds
        for i in 0..<_pages.count {
            labelViews[i].frame = CGRect(x: pw*CGFloat(i), y: 0, width: pw, height: height)
        }
        thumb.frame = CGRect(x: CGFloat(_pageNo)*pw, y: 0, width: pw, height: height)
    }
}
