//
//  AetherExperiment.swift
//  Aexels
//
//  Created by Joe Charlier on 2/11/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

class AetherExperiment: Experiment {
    var name: String = ""
    var notes: String = ""

// Static ==========================================================================================
    static var aexels12: AetherExperiment {
        let experiment: AetherExperiment = AetherExperiment()
        experiment.name = "12 Aexels"
        experiment.notes = ""
        return experiment
    }
    static var aexels60: AetherExperiment {
        let experiment: AetherExperiment = AetherExperiment()
        experiment.name = "60 Aexels"
        experiment.notes = ""
        return experiment
    }
    static var aexels360: AetherExperiment {
        let experiment: AetherExperiment = AetherExperiment()
        experiment.name = "360 Aexels"
        experiment.notes = ""
        return experiment
    }
    static var gameOfLife: AetherExperiment {
        let experiment: AetherExperiment = AetherExperiment()
        experiment.name = "Game of Life"
        experiment.notes = ""
        return experiment
    }
    static var line: AetherExperiment {
        let experiment: AetherExperiment = AetherExperiment()
        experiment.name = "Line"
        experiment.notes = ""
        return experiment
    }
    static var rectangle: AetherExperiment {
        let experiment: AetherExperiment = AetherExperiment()
        experiment.name = "Rectangle"
        experiment.notes = ""
        return experiment
    }
    static var card: AetherExperiment {
        let experiment: AetherExperiment = AetherExperiment()
        experiment.name = "Card"
        experiment.notes = ""
        return experiment
    }
    static var circle: AetherExperiment {
        let experiment: AetherExperiment = AetherExperiment()
        experiment.name = "Circle"
        experiment.notes = ""
        return experiment
    }
    static var disk: AetherExperiment {
        let experiment: AetherExperiment = AetherExperiment()
        experiment.name = "Disk"
        experiment.notes = ""
        return experiment
    }
    static var blank: AetherExperiment {
        let experiment: AetherExperiment = AetherExperiment()
        experiment.name = "Blank"
        experiment.notes = ""
        return experiment
    }
    
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
