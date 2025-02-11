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

//class Experiment: Anchor {
//    enum Explorer: CaseIterable { case unknown, aether, cellular, kinematics, distance, gravity, dilation, contraction, electromagnetism }
//
//    var explorer: Explorer {
//        set { explorerToken = newValue.toString() }
//        get { Explorer.from(string: explorerToken) ?? .unknown }
//    }
//
//    @objc dynamic var explorerToken: String = ""
//    @objc dynamic var name: String = ""
//    @objc dynamic var notes: String = ""
//
//// Domain ==========================================================================================
//    override var properties: [String] { super.properties + ["explorerToken", "name", "notes"] }
//}
