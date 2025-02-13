//
//  AetherExperiment.swift
//  Aexels
//
//  Created by Joe Charlier on 2/11/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

class AetherExperiment: Experiment {
    enum Letter { case A, B, C, D, E, F, G, H, I, J }
    
    let name: String
    let notes: String
    let letter: Letter

    init(name: String, notes: String, letter: Letter) {
        self.name = name
        self.notes = notes
        self.letter = letter
    }

// Static ==========================================================================================
    static var aexels12: AetherExperiment { AetherExperiment(name: "12 Aexels", notes: "", letter: .A) }
    static var aexels60: AetherExperiment { AetherExperiment(name: "60 Aexels", notes: "", letter: .B) }
    static var aexels360: AetherExperiment { AetherExperiment(name: "360 Aexels", notes: "", letter: .C) }
    static var gameOfLife: AetherExperiment { AetherExperiment(name: "Game of Life", notes: "", letter: .D) }
    static var line: AetherExperiment { AetherExperiment(name: "Line", notes: "", letter: .E) }
    static var rectangle: AetherExperiment { AetherExperiment(name: "Rectangle", notes: "", letter: .F) }
    static var card: AetherExperiment { AetherExperiment(name: "Card", notes: "", letter: .G) }
    static var circle: AetherExperiment { AetherExperiment(name: "Circle", notes: "", letter: .H) }
    static var disk: AetherExperiment { AetherExperiment(name: "Disk", notes: "", letter: .I) }
    static var blank: AetherExperiment { AetherExperiment(name: "Blank", notes: "", letter: .J) }
    
    static var experiments: [Experiment] { [
        aexels12,
        aexels60,
        aexels360,
        gameOfLife,
        line,
        rectangle,
        card,
        circle,
        disk,
        blank
    ] }
}
