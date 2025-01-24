//
//  Settings.swift
//  Aexels
//
//  Created by Joe Charlier on 1/13/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

import Acheron
import Foundation

class Settings: Anchor {
    @objc dynamic var musicOn: Bool = true
    
// Domain ==========================================================================================
    override var properties: [String] { super.properties + ["musicOn"] }
}
