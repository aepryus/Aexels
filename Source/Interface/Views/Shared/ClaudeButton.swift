//
//  ClaudeButton.swift
//  Aexels
//
//  Created by Joe Charlier on 1/7/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

import Acheron
import UIKit

class ClaudeButton: AEView {
    var article: Article?

    let imageButton: ImageButton = ImageButton(named: "claude")
    let label: UILabel = UILabel()
    
    static let pen: Pen = Pen(font: .optima(size: 12*Screen.s), color: .black.tint(0.4))
    
    override init() {
        super.init()
        
        addSubview(imageButton)
        imageButton.addAction { self.onCopy() }
        imageButton.addAction(for: [.touchDown, .touchDragEnter]) { [weak imageButton] in
            guard let imageButton else { return }
            imageButton.onHighlight()
        }
        imageButton.addAction(for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit]) {  [weak imageButton] in
            guard let imageButton else { return }
            imageButton.onUnHighlight()
        }
        let gesture = UIHoverGestureRecognizer(target: self, action: #selector(onHover(_:)))
        imageButton.addGestureRecognizer(gesture)
//        imageView.isUserInteractionEnabled = true
        
        label.alpha = 0
        label.text = "copy to discuss with Claude"
        label.pen = ClaudeButton.pen
        addSubview(label)
    }
    
// Events ==========================================================================================
    @objc func onHover(_ recognizer: UIHoverGestureRecognizer) {
        switch recognizer.state {
            case .began:
                UIView.animate(withDuration: 0.5) { self.label.alpha = 1 }
            case .ended:
                UIView.animate(withDuration: 0.5) { self.label.alpha = 0 }
            default:
                break
        }
    }
    func onCopy() {
        imageButton.spin()
        if let article { UIPasteboard.general.string = article.article }
        else {
            var sb: String = ""
            Article.articles.forEach {
                sb.append("===================================================================\n")
                sb.append($0.article)
            }
            UIPasteboard.general.string = sb
        }
    }

// UIView ==========================================================================================
    override func layoutSubviews() {
        imageButton.left(width: height, height: height)
        
        label.left(dx: imageButton.right+5*s, width: 150*s, height: height)
    }
}
