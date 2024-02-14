//
//  Interchange.swift
//  Aexels
//
//  Created by Joe Charlier on 2/14/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

import Acheron
import UIKit

class Interchange: AEView {
    var article: Article? = nil
    
    let prevLabel: UILabel = UILabel()
    let nextLabel: UILabel = UILabel()
    let childrenLabel: UILabel = UILabel()
    let explorersLabel: UILabel = UILabel()
    
    override init() {
        super.init()
        backgroundColor = .blue.tone(0.5).alpha(0.5)
    }
}
