//
//  KinematicsExperiment.swift
//  Aexels
//
//  Created by Joe Charlier on 2/14/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

class KinematicsExperiment: Experiment {
    enum Letter { case A, B }
    
    let name: String
    let notes: String
    let letter: Letter

    init(name: String, notes: String, letter: Letter) {
        self.name = name
        self.notes = notes
        self.letter = letter
    }

// Static ==========================================================================================
    static var teslonInABox: KinematicsExperiment { KinematicsExperiment(name: "Teslon in a Box", notes: "", letter: .A) }
    static var theBouncingLeaf: KinematicsExperiment { KinematicsExperiment(name: "The Bouncing Leaf", notes: "", letter: .B) }
    
    static var experiments: [Experiment] { [
        teslonInABox,
        theBouncingLeaf
    ] }
}
