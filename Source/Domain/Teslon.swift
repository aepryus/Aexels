//
//  Teslon.swift
//  Aexels
//
//  Created by Joe Charlier on 1/27/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

import Acheron
import Foundation

@Domain class Teslon: Domain {
    @Field var pX: Double = 0
    @Field var pY: Double = 0
    @Field var speed: Double = 0
    @Field var orient: Double = 0
    @Field var hyle: Double = 0
    @Field var pings: Bool = true
    @Field var contracts: Bool = true
    
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
}
