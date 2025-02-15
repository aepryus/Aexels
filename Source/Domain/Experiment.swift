//
//  Experiment.swift
//  Aexels
//
//  Created by Joe Charlier on 1/27/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

import Acheron
import Foundation

protocol Experiment: AnyObject {
    var name: String { get }
    var notes: String { get }
}
