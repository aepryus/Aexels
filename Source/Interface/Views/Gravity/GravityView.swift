//
//  GravityView.swift
//  Aexels
//
//  Created by Joe Charlier on 8/16/23.
//  Copyright © 2023 Aepryus Software. All rights reserved.
//

import Acheron
import UIKit

class GravityView: AEView {
    private var engine: GravityEngine

    private var image: UIImage?
    private var vw: Int = 0
    
    init(engine: GravityEngine) {
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
