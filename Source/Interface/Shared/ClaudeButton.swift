//
//  ClaudeButton.swift
//  Aexels
//
//  Created by Joe Charlier on 1/7/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

import Acheron
import UIKit

class ClaudeButtonHover: AEView {
    let label: UILabel = UILabel()
    
    static let pen: Pen = Pen(font: .optima(size: Screen.iPhone ? 16*Screen.s : 12*Screen.s), color: .black.tint(0.9))
    
    override init() {
        super.init()
        
        backgroundColor = .clear
        isUserInteractionEnabled = false
        
        label.text = "copy to discuss with Claude"
        label.pen = ClaudeButtonHover.pen
        addSubview(label)
    }
    
// UIView ==========================================================================================
    override func layoutSubviews() {
        layer.cornerRadius = height/2
        if Screen.iPhone {
            label.left(dx: 32*s, width: 200*s, height: 16*s)
        } else {
            label.left(dx: 25*s, width: 200*s, height: 16*s)
        }
    }
    override func draw(_ rect: CGRect) {
        guard !Screen.iPhone else { super.draw(rect); return }
        let p: CGFloat = 0
        
        let x1 = p
        let x2 = 12*s
        let x4 = width - 2*p
        let x3 = (x1+x4)/2
        
        let y1 = p
        let y3 = height - 2*p
        let y2 = (y1+y3)/2
        
        let c = UIGraphicsGetCurrentContext()!
        c.move(to: CGPoint(x: x1, y: y2))
        c.addArc(tangent1End: CGPoint(x: x1, y: y1), tangent2End: CGPoint(x: x3, y: y1), radius: height/2)
        c.addArc(tangent1End: CGPoint(x: x4, y: y1), tangent2End: CGPoint(x: x4, y: y2), radius: height/2)
        c.addArc(tangent1End: CGPoint(x: x4, y: y3), tangent2End: CGPoint(x: x3, y: y3), radius: height/2)
        c.addArc(tangent1End: CGPoint(x: x1, y: y3), tangent2End: CGPoint(x: x1, y: y2), radius: height/2)
        c.closePath()
        
        c.addArc(center: CGPoint(x: x2, y: y2), radius: 9*s, startAngle: 2 * .pi, endAngle: 0, clockwise: true)

        c.setFillColor(UIColor.black.tint(0.3).alpha(0.9).cgColor)
        c.drawPath(using: .fill)
    }
}

class ClaudeButton: AEView {
    var article: Article?

    let imageButton: ImageButton = ImageButton(named: "claude", overrideColor: Screen.iPhone ? .white : nil)
    let hover: ClaudeButtonHover = ClaudeButtonHover()
    
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
        
        hover.alpha = 0
        addSubview(hover)
    }
    
// Events ==========================================================================================
    @objc func onHover(_ recognizer: UIHoverGestureRecognizer) {
        switch recognizer.state {
            case .began:
                UIView.animate(withDuration: 0.5) { self.hover.alpha = 1 }
            case .ended:
                UIView.animate(withDuration: 0.5) { self.hover.alpha = 0 }
            default:
                break
        }
    }
    func onCopy() {
        if !Screen.mac {
            UIView.animate(withDuration: 2) {
                self.hover.alpha = 1
                UIView.animate(withDuration: 5) {
                    self.hover.alpha = 0
                }
            }
        }
        
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
        let d: CGFloat = Screen.iPhone ? 20*s : 14*s
        imageButton.left(dx: 5*s, width: d, height: d)
        hover.left(width: width, height: height)
    }
}
