//
//  Teslon.swift
//  Aexels
//
//  Created by Joe Charlier on 1/27/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

import Acheron
import Foundation

class Teslon: Domain {
    @objc dynamic var pX: Double = 0
    @objc dynamic var pY: Double = 0
    @objc dynamic var speed: Double = 0
    @objc dynamic var orient: Double = 0
    @objc dynamic var hyle: Double = 0
    @objc dynamic var pings: Bool = true
    @objc dynamic var contracts: Bool = true
    
    init(pX: Double, pY: Double, speed: Double, orient: Double, hyle: Double = 1, pings: Bool = true, contracts: Bool = false) {
        self.pX = pX
        self.pY = pY
        self.speed = speed
        self.orient = orient
        self.hyle = hyle
        self.pings = pings
        self.contracts = contracts
        
        super.init()
    }
    required init(attributes: [String : Any], parent: Domain? = nil) {
        super.init(attributes: attributes, parent: parent)
    }

// Domain ==========================================================================================
    override var properties: [String] { super.properties + ["pX", "pY", "speed", "orient", "hyle", "pings", "contracts"] }
}
