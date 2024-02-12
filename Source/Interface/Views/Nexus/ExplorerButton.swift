//
//  ExplorerButton.swift
//  Aexels
//
//  Created by Joe Charlier on 1/5/23.
//  Copyright © 2023 Aepryus Software. All rights reserved.
//

import Acheron
import UIKit

class ExplorerButton: UIControl {
    let backView: UIView = UIView()
    let imageView: UIView
    let label: UILabel = UILabel()
    
    init(text: String, imageView: UIImageView) {
        self.imageView = imageView
        super.init(frame: .zero)

        backView.addSubview(imageView)
        backView.isUserInteractionEnabled = false
        backView.layer.borderColor = UIColor.white.shade(0.14).cgColor
        backView.layer.borderWidth = 1*s
        backView.layer.cornerRadius = 8*s
        backView.layer.shadowOffset = CGSize(width: 2*s, height: 2*s)
        backView.layer.shadowColor = UIColor.black.cgColor
        backView.layer.shadowRadius = 3*s
        backView.layer.shadowOpacity = 0.5
        backView.layer.masksToBounds = false
        addSubview(backView)
        
        imageView.layer.cornerRadius = 8*s
        imageView.layer.masksToBounds = true
        
        label.text = text
        label.pen = Pen(font: .ax(size: 9*s), color: .white, alignment: .center)
        label.adjustsFontSizeToFitWidth = true
        addSubview(label)
    }
    required init?(coder: NSCoder) { fatalError() }
    
// UIView ==========================================================================================
    override func layoutSubviews() {
        backView.top(width: width*0.9, height: 50*s)
        imageView.frame = backView.bounds
        label.bottom(width: width, height: 11*s)
    }
}
