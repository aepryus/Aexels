//
//  DilationView.swift
//  Aexels
//
//  Created by Joe Charlier on 12/3/22.
//  Copyright © 2022 Aepryus Software. All rights reserved.
//

import Acheron
import UIKit

class DilationView: UIView {
    private var engine: DilationEngine

    private var image: UIImage?
    private var vw: Int = 0
    
    var chaseCameraOn: Bool = false

    init(engine: DilationEngine, chaseCameraOn: Bool = false) {
        self.engine = engine
        self.chaseCameraOn = chaseCameraOn
        super.init(frame: CGRect.zero)
        backgroundColor = UIColor.clear
        self.engine.views.append(self)
    }
    required init?(coder aDecoder: NSCoder) { fatalError() }

    // UIView ==========================================================================================
    override func draw(_ rect: CGRect) {
        guard let image = engine.image else { return }
        if !chaseCameraOn { image.draw(at: CGPoint(x: (width-engine.size.width)/2, y: (height-engine.size.height)/2)) }
        else {
            let r: CGFloat = 10
            let hw: CGFloat = 51
            let dx: CGFloat = engine.source.pointee.p.x.remainder(dividingBy: width + hw)
            image.draw(at: CGPoint(x: dx - (hw-2*r)/2 + (width-engine.size.width)/2, y: (height-engine.size.height)/2))
        }
    }
}
