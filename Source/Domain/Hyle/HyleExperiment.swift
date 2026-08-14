//
//  HyleExperiment.swift
//  Aexels
//
//  Stored initial conditions for the bridge sim: the bridge model's
//  state (v_A, v_B, r/L).  The four canonical cases are the demo
//  configurations of Sims/Bridge.
//

import Foundation

class HyleExperiment: Experiment {
    var name: String = ""
    var notes: String = ""

    var betaA: Double = 0
    var thetaA: Double = 0
    var betaB: Double = 0
    var thetaB: Double = 0
    var lOverR: Double = 16

    init(name: String, betaA: Double, thetaA: Double, betaB: Double, thetaB: Double, lOverR: Double = 16) {
        self.name = name
        self.betaA = betaA
        self.thetaA = thetaA
        self.betaB = betaB
        self.thetaB = thetaB
        self.lOverR = lOverR
    }

// Experiments =====================================================================================
    static var staticPair: HyleExperiment {
        HyleExperiment(name: "Static Pair", betaA: 0, thetaA: 0, betaB: 0, thetaB: 0)
    }
    static var comovingParallel: HyleExperiment {
        HyleExperiment(name: "Co-moving Parallel", betaA: 0.6, thetaA: 0, betaB: 0.6, thetaB: 0)
    }
    static var comovingPerpendicular: HyleExperiment {
        HyleExperiment(name: "Co-moving Perpendicular", betaA: 0.6, thetaA: 90, betaB: 0.6, thetaB: 90)
    }
    static var headOn: HyleExperiment {
        HyleExperiment(name: "Head-on Approach", betaA: 0.3, thetaA: 0, betaB: 0.3, thetaB: 180)
    }

    static var experiments: [Experiment] {
        [staticPair, comovingParallel, comovingPerpendicular, headOn]
    }
}
