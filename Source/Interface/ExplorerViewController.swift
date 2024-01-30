//
//  ExplorerViewController.swift
//  Aexels
//
//  Created by Joe Charlier on 1/29/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

import UIKit

class ExplorerViewController: UIViewController {
    let imageView: UIImageView = UIImageView(image: UIImage(named: "BackiPad"))
    
    var explorer: Explorer? = nil {
        didSet {
            guard let explorer else { return }
            explorer.view.alpha = 0
            view.addSubview(explorer.view)
            UIView.animate(withDuration: 0.2) {
                explorer.view.alpha = 1
            }
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
