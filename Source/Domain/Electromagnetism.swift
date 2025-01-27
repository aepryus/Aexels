//
//  Electromagnetism.swift
//  Aexels
//
//  Created by Joe Charlier on 1/27/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

import Acheron
import Foundation

class Electromagnetism: Domain {
    enum RenderMode: CaseIterable { case hidden, minimal, full }
    
    @objc dynamic var speedOfLight: Int = 1
    @objc dynamic var aetherVelocity: Int = 0
    @objc dynamic var pingsPerVolley: Int = 480
    @objc dynamic var timeStepsPerVolley: Int = 60
    @objc dynamic var autoVolleyOn: Bool = true
    @objc dynamic var cameraWallsOn: Bool = true
    @objc dynamic var hyleExchangeOn: Bool = true
    @objc dynamic var aetherFrameOn: Bool = true
    @objc dynamic var pingRenderModeToken: String = ""
    @objc dynamic var pongRenderModeToken: String = ""
    @objc dynamic var photonRenderModeToken: String = ""
    @objc dynamic var teslons: [Teslon] = []

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

// Domain ==========================================================================================
    override var properties: [String] { super.properties + [
        "speedOfLight", "aetherVelocity", "pingsPerVolley", "timeStepsPerVolley", "autoVolleyOn",
        "cameraWallsOn", "hyleExchangeOn", "aetherFrameOn", "pingRenderModeToken",
        "pongRenderModeToken", "photonRenderModeToken", "teslons"
    ] }
}
