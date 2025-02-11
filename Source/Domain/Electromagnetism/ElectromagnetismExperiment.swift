//
//  ElectromagnetismExperiment.swift
//  Aexels
//
//  Created by Joe Charlier on 2/11/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

import Acheron
import Foundation

class ElectromagnetismExperiment: Experiment {
    var name: String = ""
    var notes: String = ""
    
    @objc dynamic var electromagnetism: Electromagnetism? = nil
    
// Experiments =====================================================================================
    static var teslonsInABox: ElectromagnetismExperiment {
        let experiment: ElectromagnetismExperiment = ElectromagnetismExperiment()
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
        
        if Screen.iPhone {
            electromagnetism.generateTeslons = { (size: CGSize) in [
                Teslon(pX: size.width/2 - 100.0, pY: 240, speed: 0.35, orient: 0.7),
                Teslon(pX: size.width/2 - 100.0, pY: 400, speed:-0.35, orient: 0.7)
            ]}
        } else {
            electromagnetism.generateTeslons = { (size: CGSize) in [
                Teslon(pX: 360, pY: 240, speed: 0.35, orient: 0.3),
                Teslon(pX: 360, pY: 400, speed:-0.35, orient: 0.3)
            ]}
        }

        experiment.electromagnetism = electromagnetism

        return experiment
    }
    static var exploringThePing: ElectromagnetismExperiment {
        let experiment: ElectromagnetismExperiment = ElectromagnetismExperiment()
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
    static var whatIsMagnetism: ElectromagnetismExperiment {
        let experiment: ElectromagnetismExperiment = ElectromagnetismExperiment()
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
    static var whatIsPotentialEnergy: ElectromagnetismExperiment {
        let experiment: ElectromagnetismExperiment = ElectromagnetismExperiment()
        experiment.name = "What is Potential Energy?"
        experiment.notes = ""
        
        let electromagnetism: Electromagnetism = Electromagnetism()
        electromagnetism.speedOfLight = 6
        electromagnetism.aetherVelocity = 0
        electromagnetism.pingsPerVolley = 480
        electromagnetism.timeStepsPerVolley = 10
        electromagnetism.autoVolleyOn = true
        electromagnetism.cameraWallsOn = false
        electromagnetism.hyleExchangeOn = true
        electromagnetism.aetherFrameOn = false
        electromagnetism.pingRenderMode = .minimal
        electromagnetism.pongRenderMode = .minimal
        electromagnetism.photonRenderMode = .full
        
        electromagnetism.generateTeslons = { (size: CGSize) in [
            Teslon(pX: 0, pY: size.height/2, speed: 0.2, orient: 0),
            Teslon(pX: size.width, pY: size.height/2, speed: -0.2, orient: 0)
        ]}

        experiment.electromagnetism = electromagnetism

        return experiment
    }
    static var dilationRedux: ElectromagnetismExperiment {
        let experiment: ElectromagnetismExperiment = ElectromagnetismExperiment()
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
    static var contractionRedux: ElectromagnetismExperiment {
        let experiment: ElectromagnetismExperiment = ElectromagnetismExperiment()
        experiment.name = "Contraction Redux"
        experiment.notes = ""
        
        let electromagnetism: Electromagnetism = Electromagnetism()
        electromagnetism.speedOfLight = 1
        electromagnetism.aetherVelocity = 0
        electromagnetism.pingsPerVolley = 1200
        electromagnetism.timeStepsPerVolley = 600
        electromagnetism.autoVolleyOn = true
        electromagnetism.cameraWallsOn = false
        electromagnetism.hyleExchangeOn = false
        electromagnetism.aetherFrameOn = false
        electromagnetism.pingRenderMode = .minimal
        electromagnetism.pongRenderMode = .minimal
        electromagnetism.photonRenderMode = .full
        
        electromagnetism.generateTeslons = { (size: CGSize) in
            let d: CGFloat = size.width/4
            return [
                Teslon(pX: size.width/2, pY: size.height/2, speed: 0, orient: 0),
                Teslon(pX: size.width/2, pY: size.height/2 - d, speed: 0, orient: 0, pings: false),
                Teslon(pX: size.width/2 + d, pY: size.height/2, speed: 0, orient: 0, pings: false)
            ]
        }

        experiment.electromagnetism = electromagnetism

        return experiment
    }
    static var understandingFrames: ElectromagnetismExperiment {
        let experiment: ElectromagnetismExperiment = ElectromagnetismExperiment()
        experiment.name = "Understanding Frames"
        experiment.notes = ""
        
        let electromagnetism: Electromagnetism = Electromagnetism()
        electromagnetism.speedOfLight = 8
        electromagnetism.aetherVelocity = 0
        electromagnetism.pingsPerVolley = 120
        electromagnetism.timeStepsPerVolley = 120
        electromagnetism.autoVolleyOn = false
        electromagnetism.cameraWallsOn = false
        electromagnetism.hyleExchangeOn = false
        electromagnetism.aetherFrameOn = true
        electromagnetism.pingRenderMode = .minimal
        electromagnetism.pongRenderMode = .minimal
        electromagnetism.photonRenderMode = .minimal
        
        electromagnetism.generateTeslons = { (size: CGSize) in [
            Teslon(pX: size.width * 3.0/4.0, pY: size.height * 1.0/4.0, speed: -0.06, orient: 0),
            Teslon(pX: size.width * 1.0/4.0, pY: size.height * 3.0/4.0, speed:  0.06, orient: 0, pings: false),
        ]}

        experiment.electromagnetism = electromagnetism

        return experiment
    }
    static var hondaAndTesla: ElectromagnetismExperiment {
        let experiment: ElectromagnetismExperiment = ElectromagnetismExperiment()
        experiment.name = "Honda and Tesla"
        experiment.notes = ""
        
        let electromagnetism: Electromagnetism = Electromagnetism()
        electromagnetism.speedOfLight = 8
        electromagnetism.aetherVelocity = 0
        electromagnetism.pingsPerVolley = 120
        electromagnetism.timeStepsPerVolley = 120
        electromagnetism.autoVolleyOn = false
        electromagnetism.cameraWallsOn = false
        electromagnetism.hyleExchangeOn = false
        electromagnetism.aetherFrameOn = false
        electromagnetism.pingRenderMode = .minimal
        electromagnetism.pongRenderMode = .minimal
        electromagnetism.photonRenderMode = .minimal
        
        electromagnetism.generateTeslons = { (size: CGSize) in
            let d: CGFloat = size.width / 5
            
            return [
                Teslon(pX: size.width/2, pY: size.height/2, speed: 0, orient: 0),
                Teslon(pX: size.width/2+d, pY: size.height/2, speed: 0.01, orient: .pi),
                Teslon(pX: size.width/2, pY: size.height/2-d, speed: 0.01, orient: .pi/2)
            ]
        }

        experiment.electromagnetism = electromagnetism

        return experiment
    }
    
    static var experiments: [Experiment] { [
        teslonsInABox,
        exploringThePing,
        whatIsMagnetism,
        whatIsPotentialEnergy,
        dilationRedux,
        contractionRedux,
        understandingFrames,
        hondaAndTesla
    ] }
}
