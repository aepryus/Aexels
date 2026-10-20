//
//  Electromagnetism.swift
//  Aexels
//
//  Created by Joe Charlier on 1/27/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

import Acheron
import Foundation

@Domain class Electromagnetism: Domain {
    enum RenderMode: CaseIterable { case hidden, minimal, full }
    
    @Field var speedOfLight: Int = 1
    @Field var aetherVelocity: Int = 0
    @Field var pingsPerVolley: Int = 480
    @Field var timeStepsPerVolley: Int = 60
    @Field var autoVolleyOn: Bool = true
    @Field var cameraWallsOn: Bool = true
    @Field var hyleExchangeOn: Bool = true
    @Field var aetherFrameOn: Bool = true
    @Field var pingRenderModeToken: String = ""
    @Field var pongRenderModeToken: String = ""
    @Field var photonRenderModeToken: String = ""
    @Child var teslons: [Teslon] = []
    
    var generateTeslons: (CGSize)->([Teslon]) = { (size: CGSize) in [] }

    var pingRenderMode: RenderMode {
        set { pingRenderModeToken = newValue.toString() }
        get { RenderMode.from(string: pingRenderModeToken) ?? .full }
    }
    var pongRenderMode: RenderMode {
        set { pongRenderModeToken = newValue.toString() }
        get { RenderMode.from(string: pongRenderModeToken) ?? .full }
    }
    var photonRenderMode: RenderMode {
        set { photonRenderModeToken = newValue.toString() }
        get { RenderMode.from(string: photonRenderModeToken) ?? .full }
    }
    
    func regenerateTeslons(size: CGSize) {
        teslons = generateTeslons(size)
    }
}
