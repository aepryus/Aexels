//
//  TitleCell.swift
//  Aexels
//
//  Created by Joe Charlier on 2/2/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

import Acheron
import UIKit

class TitleCell: ColorCell {
    let aexelsLabel: NexusLabel = NexusLabel(text: "Aexels", size: 72*Screen.s)
    let versionLabel: NexusLabel = NexusLabel(text: "v\(Aexels.version)", size:20*Screen.s)

    init() {
        super.init(c: 0, r: 0, w: 4, color: .clear)
        
//        aexelsLabel.layer.shadowRadius = 5*s
//        aexelsLabel.layer.shadowOpacity = 0.8
//        aexelsLabel.layer.shadowColor = UIColor.black.cgColor
//        aexelsLabel.layer.shadowOffset = CGSize(width: 5*s, height: 5*s)
//        aexelsLabel.color = .black.tint(0.8)
        addSubview(aexelsLabel)
        aexelsLabel.addGestureRecognizer(TouchingGesture(target: self, action: #selector(onTouch)))
        
//        versionLabel.layer.shadowRadius = 2*s
//        versionLabel.layer.shadowOpacity = 0.8
//        versionLabel.layer.shadowColor = UIColor.black.cgColor
//        versionLabel.layer.shadowOffset = CGSize(width: 2*s, height: 2*s)
        versionLabel.alpha = 0
//        versionLabel.color = .black.tint(0.8)
        addSubview(versionLabel)
    }
    
// Events ==========================================================================================
    @objc func onTouch(gesture: TouchingGesture) {
        if gesture.state == .began {
            UIView.animate(withDuration: 0.2) {
                self.versionLabel.alpha = 1
            }
        } else if gesture.state == .ended {
            UIView.animate(withDuration: 0.2) {
                self.versionLabel.alpha = 0
            }
        }
    }
    
// UIView ==========================================================================================
    override func layoutSubviews() {
        aexelsLabel.topLeft(dx: 52*s, dy: 52*s, width: 220*s, height: 54*s)
        versionLabel.topLeft(dx: aexelsLabel.left, dy: aexelsLabel.bottom, width: 220*s, height: 24*s)
    }
}
