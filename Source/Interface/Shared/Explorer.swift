//
//  Explorer.swift
//  Aexels
//
//  Created by Joe Charlier on 1/4/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import Acheron
import OoviumKit
import UIKit

class Explorer: AEViewController {
	let key: String
    lazy var vision: Vision = ExplorerVision(explorer: self)
	
	init(key: String) {
		self.key = key
        super.init()
	}
	
    var iconToken: String { "\(key)_icon" }
    var icon: UIImage { UIImage(named: iconToken)! }
    
    var name: String { "\(key)_name".localized }
    var shortName: String { name }
}
