//
//  GravityControlsTab.swift
//  Aexels
//
//  Created by Joe Charlier on 3/31/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

import UIKit

class GravityControlsTab: TabsCellTab {
    unowned let explorer: GravityExplorer!
    
    let colorBondsBoolButton: BoolButton = BoolButton(name: "color bonds")
    let squishAexelsBoolButton: BoolButton = BoolButton(name: "squish aexels")
    let recycleAexelsBoolButton: BoolButton = BoolButton(name: "recycle aexels")

    init(explorer: GravityExplorer) {
        self.explorer = explorer
        super.init(name: "Controls".localized)
        
        colorBondsBoolButton.on = true
        addSubview(colorBondsBoolButton)
        colorBondsBoolButton.onChange =  { (on: Bool) in self.explorer.renderer.colorBondsOn = on }

        squishAexelsBoolButton.on = true
        addSubview(squishAexelsBoolButton)
        squishAexelsBoolButton.onChange =  { (on: Bool) in self.explorer.renderer.squishAexelsOn = on }

        recycleAexelsBoolButton.on = true
        addSubview(recycleAexelsBoolButton)
        recycleAexelsBoolButton.onChange =  { (on: Bool) in self.explorer.renderer.recycleAexelsOn = on }
    }
    
// UIView ==========================================================================================
    override func layoutSubviews() {
        
        var y: CGFloat = 40*s
        
        colorBondsBoolButton.topLeft(dx: 30*s, dy: y, width: 240*s, height: 24*s)
        y += 30*s
        squishAexelsBoolButton.topLeft(dx: 30*s, dy: y, width: 240*s, height: 24*s)
        y += 30*s
        recycleAexelsBoolButton.topLeft(dx: 30*s, dy: y, width: 240*s, height: 24*s)
    }
}
