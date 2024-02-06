//
//  ExplorerViewController.swift
//  Aexels
//
//  Created by Joe Charlier on 1/29/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

import Acheron
import UIKit

class ExplorerViewController: UIViewController {
    let imageView: UIImageView = UIImageView(image: UIImage(named: "OldBack"))
    
    var explorer: AEViewController? = nil {
        didSet {
            guard let explorer else { return }
            explorer.view.alpha = 0
            explorer.view.frame = view.bounds
            view.addSubview(explorer.view)
            UIView.animate(withDuration: 0.2) { explorer.view.alpha = 1 }
            
            guard let explorer: Explorer = explorer as? Explorer else { return }
            
            explorer.openExplorer(view: view)
        }
    }
    
// UIViewController ================================================================================
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(imageView)
        
        explorer = NexusExplorer()
    }
    override func viewWillLayoutSubviews() {
        imageView.frame = view.bounds
    }
}
