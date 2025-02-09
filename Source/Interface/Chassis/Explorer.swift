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
    
    let swapButton: SwapButton = SwapButton()
    let swapperButton: CircleButton
    let glyphsButton: CircleButton
	
	init(key: String) {
		self.key = key
        
        swapButton.bounds = CGRect(origin: .zero, size: CGSize(width: 26*Screen.s, height: 26*Screen.s))
        swapperButton = CircleButton(view: swapButton)
        
        let imageView: UIImageView = UIImageView(image: UIImage(named: "glyphs_icon")!)
        imageView.bounds = CGRect(origin: .zero, size: CGSize(width: 30*Screen.s, height: 30*Screen.s))
        glyphsButton = CircleButton(view: imageView)
        glyphsButton.addAction {
            Aexels.explorerViewController.explorer = Aexels.nexusExplorer
        }
        
        super.init()
	}
	
    var iconToken: String { "\(key)_icon" }
    var icon: UIImage { UIImage(named: iconToken)! }
    
    var name: String { "\(key)_name".localized }
    var shortName: String { name }
    
// AEViewController ================================================================================
    override func layoutRatio056() {
        swapperButton.bottomLeft(dx: -2*s, dy: -25*s, width: 54*s, height: 54*s)
        glyphsButton.bottomRight(dx:  2*s, dy: -25*s, width: 54*s, height: 54*s)
    }
}
