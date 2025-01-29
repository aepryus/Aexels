//
//  Experiment.swift
//  Aexels
//
//  Created by Joe Charlier on 1/27/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

import Acheron
import Foundation

class Experiment: Anchor {
    enum Explorer: CaseIterable { case unknown, aether, cellular, kinematics, distance, gravity, dilation, contraction, electromagnetism }
    
    @objc dynamic var explorerToken: String = ""
    @objc dynamic var name: String = ""
    @objc dynamic var notes: String = ""
    @objc dynamic var electromagnetism: Electromagnetism? = nil
    
    var explorer: Explorer {
        set { explorerToken = newValue.toString() }
        get { Explorer.from(string: explorerToken) ?? .unknown }
    }
    
// Domain ==========================================================================================
    override var properties: [String] { super.properties + ["explorerToken", "name", "notes", "electromagnetism"] }
    
// Experiments =====================================================================================
    static func exploringThePing() -> Experiment {
        let experiment: Experiment = Experiment()
        experiment.explorer = .electromagnetism
        experiment.name = "Exploring the Ping"
        experiment.notes = ""
        
        let electromagnetism: Electromagnetism = Electromagnetism()
        electromagnetism.speedOfLight = 1
        electromagnetism.aetherVelocity = 70
        electromagnetism.pingsPerVolley = 24
        electromagnetism.timeStepsPerVolley = 60
        electromagnetism.autoVolleyOn = true
        electromagnetism.cameraWallsOn = false
        electromagnetism.hyleExchangeOn = false
        electromagnetism.aetherFrameOn = true
        electromagnetism.pingRenderMode = .full
        electromagnetism.pongRenderMode = .full
        electromagnetism.photonRenderMode = .full
        
        electromagnetism.generateTeslons = { (size: CGSize) in [
            Teslon(pX: size.width/2, pY: size.height/2, speed: 0.7, orient: 0),
        ]}

        experiment.electromagnetism = electromagnetism

        return experiment
    }
    static func teslonsInABox() -> Experiment {
        let experiment: Experiment = Experiment()
        experiment.explorer = .electromagnetism
        experiment.name = "Teslons in a Box"
        experiment.notes = ""
        
        let electromagnetism: Electromagnetism = Electromagnetism()
        electromagnetism.speedOfLight = 2
        electromagnetism.aetherVelocity = 0
        electromagnetism.pingsPerVolley = 480
        electromagnetism.timeStepsPerVolley = 30
        electromagnetism.autoVolleyOn = true
        electromagnetism.cameraWallsOn = true
        electromagnetism.hyleExchangeOn = false
        electromagnetism.aetherFrameOn = false
        electromagnetism.pingRenderMode = .minimal
        electromagnetism.pongRenderMode = .full
        electromagnetism.photonRenderMode = .full
        
        electromagnetism.generateTeslons = { (size: CGSize) in [
            Teslon(pX: 360, pY: 240, speed: 0.35, orient: 0.3),
            Teslon(pX: 360, pY: 400, speed:-0.35, orient: 0.3)
        ]}

        experiment.electromagnetism = electromagnetism

        return experiment
    }
    static func whatIsMagnetism() -> Experiment {
        let experiment: Experiment = Experiment()
        experiment.explorer = .electromagnetism
        experiment.name = "What is Magnetism?"
        experiment.notes = ""
        
        let electromagnetism: Electromagnetism = Electromagnetism()
        electromagnetism.speedOfLight = 3
        electromagnetism.aetherVelocity = 99
        electromagnetism.pingsPerVolley = 120
        electromagnetism.timeStepsPerVolley = 60
        electromagnetism.autoVolleyOn = true
        electromagnetism.cameraWallsOn = false
        electromagnetism.hyleExchangeOn = false
        electromagnetism.aetherFrameOn = true
        electromagnetism.pingRenderMode = .minimal
        electromagnetism.pongRenderMode = .full
        electromagnetism.photonRenderMode = .hidden
        
        electromagnetism.generateTeslons = { (size: CGSize) in [
            Teslon(pX: size.width/2, pY: size.height/2 + 120.0, speed: 0.99, orient: 0),
            Teslon(pX: size.width/2, pY: size.height/2 - 120.0, speed: 0.99, orient: 0)
        ]}

        experiment.electromagnetism = electromagnetism

        return experiment
    }
    static func whatIsPotentialEnergy() -> Experiment {
        let experiment: Experiment = Experiment()
        experiment.explorer = .electromagnetism
        experiment.name = "What is Potential Energy?"
        experiment.notes = ""
        
        let electromagnetism: Electromagnetism = Electromagnetism()
        electromagnetism.speedOfLight = 1
        electromagnetism.aetherVelocity = 0
        electromagnetism.pingsPerVolley = 480
        electromagnetism.timeStepsPerVolley = 60
        electromagnetism.autoVolleyOn = true
        electromagnetism.cameraWallsOn = false
        electromagnetism.hyleExchangeOn = false
        electromagnetism.aetherFrameOn = false
        electromagnetism.pingRenderMode = .minimal
        electromagnetism.pongRenderMode = .full
        electromagnetism.photonRenderMode = .full
        
        electromagnetism.generateTeslons = { (size: CGSize) in [
            Teslon(pX: 0, pY: size.height/2, speed: 0.2, orient: 0),
            Teslon(pX: size.width, pY: size.height/2, speed: -0.2, orient: 0)
        ]}

        experiment.electromagnetism = electromagnetism

        return experiment
    }
    static func dilationRedux() -> Experiment {
        let experiment: Experiment = Experiment()
        experiment.explorer = .electromagnetism
        experiment.name = "Dilation Redux"
        experiment.notes = ""
        
        let electromagnetism: Electromagnetism = Electromagnetism()
        electromagnetism.speedOfLight = 1
        electromagnetism.aetherVelocity = 20
        electromagnetism.pingsPerVolley = 120
        electromagnetism.timeStepsPerVolley = 120
        electromagnetism.autoVolleyOn = true
        electromagnetism.cameraWallsOn = false
        electromagnetism.hyleExchangeOn = false
        electromagnetism.aetherFrameOn = false
        electromagnetism.pingRenderMode = .minimal
        electromagnetism.pongRenderMode = .full
        electromagnetism.photonRenderMode = .full
        
        electromagnetism.generateTeslons = { (size: CGSize) in [
            Teslon(pX: size.width/2, pY: size.height/2, speed: 0.2, orient: 0),
            Teslon(pX: size.width/2, pY: size.height/4, speed: 0.2, orient: 0)
        ]}

        experiment.electromagnetism = electromagnetism

        return experiment
    }
    static func contractionRedux() -> Experiment {
        let experiment: Experiment = Experiment()
        experiment.explorer = .electromagnetism
        experiment.name = "Contraction Redux"
        experiment.notes = ""
        
        let electromagnetism: Electromagnetism = Electromagnetism()
        electromagnetism.speedOfLight = 1
        electromagnetism.aetherVelocity = 50
        electromagnetism.pingsPerVolley = 120
        electromagnetism.timeStepsPerVolley = 120
        electromagnetism.autoVolleyOn = false
        electromagnetism.cameraWallsOn = false
        electromagnetism.hyleExchangeOn = false
        electromagnetism.aetherFrameOn = false
        electromagnetism.pingRenderMode = .minimal
        electromagnetism.pongRenderMode = .full
        electromagnetism.photonRenderMode = .full
        
        electromagnetism.generateTeslons = { (size: CGSize) in [
            Teslon(pX: size.width/2, pY: size.height/2, speed: 0.5, orient: 0),
            Teslon(pX: size.width/2, pY: size.height/4, speed: 0.5, orient: 0),
            Teslon(pX: size.width/2+size.width/4/(1/sqrt(1-0.5*0.5)), pY: size.height/2, speed: 0.5, orient: 0)
        ]}

        experiment.electromagnetism = electromagnetism

        return experiment
    }
}
