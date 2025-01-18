//
//  DistanceView.swift
//  Aexels
//
//  Created by Joe Charlier on 1/15/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

import Acheron
import UIKit

class DistanceView: AEView {
    private var engine: DistanceEngine

    private var image: UIImage?
    private var vw: Int = 0
    
    init(engine: DistanceEngine) {
        self.engine = engine
        super.init()
        backgroundColor = UIColor.clear
        self.engine.view = self
    }

// UIView ==========================================================================================
    override func draw(_ rect: CGRect) {
        guard let image = engine.image else { return }
        image.draw(at: .zero)
    }
}
