//
//  SwapButton.swift
//  Aexels
//
//  Created by Joe Charlier on 12/10/22.
//  Copyright © 2022 Aepryus Software. All rights reserved.
//

import Acheron
import OoviumEngine
import UIKit

class BoolButtonOld: UIControl {
    let swapButton: SwapButton = SwapButton(expandHitBox: false)
    let label: UILabel = UILabel()
    
    init(text: String) {
        super.init(frame: CGRect(origin: .zero, size: CGSize(width: 121*Screen.s, height: 26*Screen.s)))
        
        swapButton.isUserInteractionEnabled = false
        addSubview(swapButton)
        
        let pen: Pen = Pen(font: .verdana(size: 15*s), color: .white)
        label.attributedText = pen.format(text)
        addSubview(label)
        
        addAction(for: .touchDown) {
            self.swapButton.isHighlighted = true
            let pen: Pen = Pen(font: .verdana(size: 15*Screen.s), color: Text.Color.lavender.uiColor)
            self.label.attributedText = pen.format(text)
        }
        addAction(for: [.touchUpInside, .touchCancel]) {
            self.swapButton.isHighlighted = false
            let pen: Pen = Pen(font: .verdana(size: 15*Screen.s), color: .white)
            self.label.attributedText = pen.format(text)
        }
    }
    required init?(coder: NSCoder) { fatalError() }
    
    func rotateView() {
        swapButton.rotateView()
    }
    
// UIView ==========================================================================================
    override func layoutSubviews() {
        swapButton.left(width: 26*s, height: 26*s)
        label.topLeft(dx: swapButton.right+5*s, dy: swapButton.top+2*s, width: 90*s, height: 20*s)
    }
}
