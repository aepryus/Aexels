//
//  CellularExperiment.swift
//  Aexels
//
//  Created by Joe Charlier on 2/15/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

import OoviumKit
import UIKit

class CellularExperiment: Experiment {
    
    let name: String
    let notes: String
    let facade: AetherFacade

    init(name: String, notes: String, facade: AetherFacade) {
        self.name = name
        self.notes = notes
        self.facade = facade
    }
    
// Static ==========================================================================================
    static func loadExperiments() -> [Experiment] {
        var experiments: [Experiment] = []
        let spaceFacade: SpaceFacade = Facade.create(space: Space.local) as! SpaceFacade
        let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
        spaceFacade.loadFacades { (facades: [Facade]) in
            experiments = facades.compactMap { (facade: Facade) in
                guard let facade: AetherFacade = facade as? AetherFacade else { return nil }
                return CellularExperiment(name: facade.name, notes: "", facade: facade)
            }
            semaphore.signal()
        }
        semaphore.wait()
        return experiments
    }
}
