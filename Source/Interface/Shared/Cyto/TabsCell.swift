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

class TabsCell: LimboCell {
    var tabs: [TabsCellTab] = [] {
        didSet {
            selected = tabs[0]
            switcher.generatePages(tabs.map({ $0.name }))
        }
    }
    var switcher: Switcher!
    var tabButtons: [TabButton] = []
    var selected: TabsCellTab? {
        didSet {
            oldValue?.removeFromSuperview()
            guard let selected else { return }
            selected.frame = selectedView.bounds
            selectedView.addSubview(selected)
            tabs.forEach { $0.selected = false }
            selected.selected = true
            renderPaths()
            setNeedsLayout()
        }
    }
    
    let cutout: Bool
    
    let selectedView: UIView = UIView()
    
    init(size: CGSize? = nil, c: Int = 0, r: Int = 0, w: Int = 1, h: Int = 1, p: CGFloat = 15*Screen.s, cutout: Bool = false) {
        self.cutout = cutout
        
        super.init(content: UIView(), size: size, c: c, r: r, w: w, h: h, p: p)
        
        content?.addSubview(selectedView)
        
        backgroundColor = .clear
        
        switcher = Switcher({ (view: UIView) in
            let label = view as! UILabel
            let name = label.text!
            self.selected = self.tabs.first(where: { (tab: TabsCellTab) in
                tab.name == name
            })
        })
        
        content?.addSubview(switcher)
    }
    
// UIView ==========================================================================================
    override func layoutSubviews() {
        super.layoutSubviews()
        
        tabs.forEach { $0.frame = selectedView.bounds }
        
        let p: CGFloat = 20*s
        tabButtons.forEach { $0.sizeToFit() }
        var m: CGFloat = width - tabButtons.summate({ $0.width }) - p*2
        m /= CGFloat(tabButtons.count-1)
        
        var x: CGFloat = p
        tabButtons.forEach {
            $0.sizeToFit()
            if $0.tabsCellTab.selected { $0.bottomLeft(dx: x, dy: -9*s, height: 20*s) }
            else { $0.bottomLeft(dx: x, dy: -7*s, height: 20*s) }
            x += $0.width + m
        }
        
        
        guard let content else { return }
        
        selectedView.top(width: content.width, height: content.height-30*s)
        switcher.bottom(width: content.width-24*s, height: 24*s)
    }
}
