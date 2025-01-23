//
//  TabsCell.swift
//  Aexels
//
//  Created by Joe Charlier on 1/22/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

import Acheron
import UIKit

class TabsCellTab: AEView {
    let name: String
    var selected: Bool = false
    
    init(name: String) {
        self.name = name
        super.init()
    }
}
class TabButton: AXButton {
    unowned let tabsCellTab: TabsCellTab
    
    let label: UILabel = UILabel()
    
    init(tabsCellTab: TabsCellTab) {
        self.tabsCellTab = tabsCellTab
        super.init()
        label.text = tabsCellTab.name
        label.pen = Pen(font: .avenir(size: 12*s), color: .white, alignment: .center)
        addSubview(label)
    }
    
// UIView ==========================================================================================
    override func layoutSubviews() {
        label.sizeToFit()
        label.center()
    }
    override func sizeToFit() {
        label.sizeToFit()
        bounds = CGRect(origin: .zero, size: CGSize(width: label.width+6*s, height: 16*s))
    }
}

class TabsCell: Cyto.Cell {
    class Path {
        var strokePath: CGPath!
        var shadowPath: CGPath!
        var maskPath: CGPath!
        var tabPath: CGPath!
        var fullPath: CGPath!
    }
    
    let path: Path = Path()
    var contentSize: CGSize?
    var tabs: [TabsCellTab] = [] {
        didSet {
            selected = tabs[0]
            renderTabs()
        }
    }
    var tabButtons: [TabButton] = []
    var selected: TabsCellTab? {
        didSet {
            oldValue?.removeFromSuperview()
            guard let selected else { return }
            addSubview(selected)
            tabs.forEach { $0.selected = false }
            selected.selected = true
            renderTabs()
            renderPaths()
            setNeedsLayout()
        }
    }
    
    let cutout: Bool
    
    let p: CGFloat
    
    init(size: CGSize? = nil, c: Int = 0, r: Int = 0, w: Int = 1, h: Int = 1, p: CGFloat = 15*Screen.s, cutout: Bool = false) {
        self.contentSize = size
        self.p = p
        self.cutout = cutout
        
        super.init(c: c, r: r, w: w, h: h)
        
        backgroundColor = .clear
    }

    private func buildShadowPath(p: CGFloat, q: CGFloat) -> CGPath {
        let path = CGMutablePath()
        
        let x1 = p
        let x3 = width - p
        let x2 = (x1 + x3) / 2
        let y1 = p
        let y3 = height - p
        let y2 = (y1 + y3) / 2
        let r: CGFloat = 10*s

        path.move(to: CGPoint(x: x1, y: y1+r))
        path.addArc(tangent1End: CGPoint(x: x1, y: y1), tangent2End: CGPoint(x: x2, y: y1), radius: r)
        if !cutout {
            path.addArc(tangent1End: CGPoint(x: x3, y: y1), tangent2End: CGPoint(x: x3, y: y2), radius: r)
        } else {
            let radius: CGFloat = 24*s
            path.addArc(center: CGPoint(x: width-20*s, y: 20*s), radius: radius, startAngle: 3/2 * .pi - atan(radius/20), endAngle: atan(radius/20), clockwise: true)
        }
        path.addArc(tangent1End: CGPoint(x: x3, y: y3), tangent2End: CGPoint(x: x2, y: y3), radius: r)
        path.addArc(tangent1End: CGPoint(x: x1, y: y3), tangent2End: CGPoint(x: x1, y: y2), radius: r)
        path.closeSubpath()
        
        return path
    }
    private func buildPath(p: CGFloat, q: CGFloat) -> CGPath {
        let path = CGMutablePath()
        
        let selectedIndex: Int = tabs.firstIndex(where: { selected === $0 })!
        
        let x1 = p
        let x3 = width - p
        let x2 = (x1 + x3) / 2
        let x4 = selectedIndex == 0 ? x1 : (tabButtons[selectedIndex-1].right+tabButtons[selectedIndex].left)/2
        let x6 = selectedIndex == tabs.count-1 ? x3 : (tabButtons[selectedIndex+1].left+tabButtons[selectedIndex].right)/2
        let x5 = (x4+x6)/2
        
        let y1 = p
        let y3 = height - p
        let y2 = (y1 + y3) / 2
        let y4 = y3 - 20*s
        
        let r: CGFloat = 10*s

        path.move(to: CGPoint(x: x1, y: y1+r))
        path.addArc(tangent1End: CGPoint(x: x1, y: y1), tangent2End: CGPoint(x: x2, y: y1), radius: r)
        if !cutout {
            path.addArc(tangent1End: CGPoint(x: x3, y: y1), tangent2End: CGPoint(x: x3, y: y2), radius: r)
        } else {
            let radius: CGFloat = 24*s
            path.addArc(center: CGPoint(x: width-20*s, y: 20*s), radius: radius, startAngle: 3/2 * .pi - atan(radius/20), endAngle: atan(radius/20), clockwise: true)
        }
        
        if x6 == x3 {
            path.addArc(tangent1End: CGPoint(x: x6, y: y3), tangent2End: CGPoint(x: x5, y: y3), radius: r)
            path.addArc(tangent1End: CGPoint(x: x4, y: y3), tangent2End: CGPoint(x: x4, y: (y3+y4)/2), radius: r)
            path.addArc(tangent1End: CGPoint(x: x4, y: y4), tangent2End: CGPoint(x: (x1+x4)/2, y: y4), radius: r)
            path.addArc(tangent1End: CGPoint(x: x1, y: y4), tangent2End: CGPoint(x: x1, y: y2), radius: r)
        } else {
            path.addArc(tangent1End: CGPoint(x: x3, y: y4), tangent2End: CGPoint(x: (x3+x6)/2, y: y4), radius: r)
            path.addArc(tangent1End: CGPoint(x: x6, y: y4), tangent2End: CGPoint(x: x6, y: (y3+y4)/2), radius: r)
            path.addArc(tangent1End: CGPoint(x: x6, y: y3), tangent2End: CGPoint(x: x5, y: y3), radius: r)
            
            if x4 == x1 {
                path.addArc(tangent1End: CGPoint(x: x1, y: y3), tangent2End: CGPoint(x: x1, y: y2), radius: r)
            } else {
                path.addArc(tangent1End: CGPoint(x: x4, y: y3), tangent2End: CGPoint(x: x4, y: (y3+y4)/2), radius: r)
                path.addArc(tangent1End: CGPoint(x: x4, y: y4), tangent2End: CGPoint(x: (x1+x4)/2, y: y4), radius: r)
                path.addArc(tangent1End: CGPoint(x: x1, y: y4), tangent2End: CGPoint(x: x1, y: y2), radius: r)
            }
        }
        
        path.closeSubpath()
        
        return path
    }
    private func renderPaths() {
        let a: CGFloat = 6*Screen.s
        let b: CGFloat = 2*Screen.s

        path.strokePath = buildPath(p: a, q: 0)
        path.maskPath = buildPath(p: a, q: a-b)
        path.shadowPath = buildPath(p: b, q: 0)
        path.tabPath = buildPath(p: a, q: 0)
        path.fullPath = buildShadowPath(p: a, q: 0)
        
//        self.layer.shadowPath = path.shadowPath
        setNeedsDisplay()
    }
    private func renderTabs() {
        tabButtons.forEach { $0.removeFromSuperview() }
        tabButtons = tabs.map { TabButton(tabsCellTab: $0) }
        tabButtons.forEach { (tabButton: TabButton) in
            if tabButton.tabsCellTab.selected { tabButton.label.textColor = .white }
            else { tabButton.label.textColor = .black.tint(0.4) }
            addSubview(tabButton)
            tabButton.addAction { [weak self] in
                guard let self else { return }
                self.selected = tabButton.tabsCellTab
            }
        }
    }
    
// UIView ==========================================================================================
    override func draw(_ rect: CGRect) {
        let c = UIGraphicsGetCurrentContext()!
        
        let fullColor: UIColor = .black.tint(0.5).alpha(0.3)
        let tabColor: UIColor = .black.alpha(0.54)
        
        c.addPath(path.fullPath)
        c.setStrokeColor(fullColor.shade(0.5).cgColor)
        c.setFillColor(fullColor.cgColor)
        c.setLineWidth(1.5*s)
        c.drawPath(using: .fillStroke)

        c.addPath(path.strokePath)
        c.setStrokeColor(UIColor.black.tint(0.3).cgColor)
        c.setFillColor(tabColor.cgColor)
        c.setLineWidth(1.5*s)
        c.drawPath(using: .fillStroke)
    }
    override func layoutSubviews() {
        tabs.forEach { $0.frame = bounds }
        
        let p: CGFloat = 20*s
        tabButtons.forEach { $0.sizeToFit() }
        var m: CGFloat = width - tabButtons.summate({ $0.width }) - p*2
        m /= CGFloat(tabButtons.count-1)
        
        var x: CGFloat = p
        tabButtons.forEach {
            $0.sizeToFit()
            if $0.tabsCellTab.selected { $0.bottomLeft(dx: x, dy: -10*s) }
            else { $0.bottomLeft(dx: x, dy: -8*s) }
            x += $0.width + m
        }
        renderPaths()
    }
}
