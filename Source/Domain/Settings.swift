//
//  Settings.swift
//  Aexels
//
//  Created by Joe Charlier on 1/13/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

import Acheron
import Foundation

@Domain class Settings: Anchor {
    @Field var musicOn: Bool = true
}
