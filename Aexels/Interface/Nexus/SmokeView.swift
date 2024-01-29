//
//  SmokeView.swift
//  Aexels
//
//  Created by Joe Charlier on 1/24/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

import UIKit

class SmokeView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSmoke()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSmoke()
    }

    private func setupSmoke() {
        let smokeEmitter = CAEmitterLayer()
        smokeEmitter.emitterPosition = CGPoint(x: bounds.width / 2, y: height/2)
        smokeEmitter.emitterShape = .line
        smokeEmitter.emitterSize = CGSize(width: bounds.width, height: 1)

        let smokeCell = CAEmitterCell()
        smokeCell.birthRate = 45
        smokeCell.lifetime = 20.0
        smokeCell.lifetimeRange = 0
        smokeCell.velocity = 100
        smokeCell.velocityRange = 50
        smokeCell.emissionLongitude = .pi*0.8
        smokeCell.emissionRange = .pi / 4
        smokeCell.spin = 1
        smokeCell.spinRange = 2
        smokeCell.scale = 0.1
        smokeCell.scaleRange = 0.1
        smokeCell.color = UIColor.white.cgColor

        // Set the image of your smoke particle
        smokeCell.contents = UIImage(named: "smokeParticle")?.cgImage

        smokeEmitter.emitterCells = [smokeCell]
        layer.addSublayer(smokeEmitter)
    }
}
