//
//  NexusCell.swift
//  Aexels
//
//  Created by Joe Charlier on 2/5/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

import Acheron
import UIKit

class NexusCell: Cyto.Cell {
    let name: String?
    let about: String?
    let image: UIImage?
    
    let nameLabel: UILabel = UILabel()
    let aboutLabel: UILabel = UILabel()
    let imageView: UIImageView = UIImageView()
    
    init(name: String? = nil, about: String? = nil, image: UIImage? = nil, c: Int = 0, r: Int = 0, w: Int = 1, h: Int = 1) {
        self.name = name
        self.about = about
        self.image = image
        super.init(c: c, r: r, w: w, h: h)
        layer.cornerRadius = 8*s
        layer.borderWidth = 3
        layer.borderColor = UIColor.white.shade(0.6).cgColor
        layer.backgroundColor = UIColor.white.shade(0.4).cgColor
        
        if let name {
            nameLabel.text = name
            nameLabel.pen = Pen(font: .axBold(size: 16*s), color: .white, alignment: .center)
            nameLabel.numberOfLines = 2
            addSubview(nameLabel)
        }
        if let about {
            aboutLabel.text = about
            addSubview(aboutLabel)
        }
        if let image {
            imageView.image = image
            addSubview(imageView)
        }
    }
    
// UIView ==========================================================================================
    override func layoutSubviews() {
        if name != nil && about == nil && image == nil {
            nameLabel.sizeToFit()
            nameLabel.center(height: nameLabel.height+4*s)
        }
        if name == nil && about == nil && image != nil {
            imageView.center(width: 189*s/2, height: 150*s/2)
        }
    }
}
