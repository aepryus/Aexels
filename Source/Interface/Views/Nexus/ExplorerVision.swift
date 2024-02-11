//
//  ExplorerVision.swift
//  Aexels
//
//  Created by Joe Charlier on 2/9/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

import Acheron
import UIKit

class ExplorerVision: Vision {
    let explorer: AEViewController
    let imageView: UIImageView = UIImageView()
    
    init(explorer: AEViewController) {
        self.explorer = explorer
        super.init()
        
        imageView.contentMode = .scaleAspectFill
        imageView.layer.borderColor = UIColor.black.tint(0.5).cgColor
        imageView.layer.borderWidth = 2
        
        let named: String
        if let explorer = explorer as? Explorer { named = "\(explorer.key)_icon" }
        else { named = "nexus_icon" }
        
        imageView.image = UIImage(named: named)!
        imageView.layer.masksToBounds = true
        addSubview(imageView)
    }
    
// Vision ==========================================================================================
    override func onSelect() {
        Aexels.explorerViewController.explorer = explorer
    }
    
// UIView ==========================================================================================
    override func layoutSubviews() {
        imageView.center(width: width-2*s, height: height-2*s)
        imageView.layer.cornerRadius = imageView.width/2
    }
}
