//
//  Slider.swift
//  Aexels
//
//  Created by Joe Charlier on 1/23/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

import Acheron
import UIKit

class Slider: UIView, UIGestureRecognizerDelegate {
    var options: [Int]
    var option: Int = 0

    var pen2: Pen = Pen(font: .avenir(size: 15*Screen.s), color: .white, alignment: .center)
    var pen3: Pen = Pen(font: .avenir(size: 11*Screen.s), color: .white, alignment: .center)
    var pen4: Pen = Pen(font: .avenir(size: 9*Screen.s), color: .white, alignment: .center)

    private var position: CGFloat = 0
    private var startX: CGFloat = 0
    private var deltaX: CGFloat = 0
    private var oldPos: CGFloat = 0

    var onChange: ((Int)->())?
    
    init(options: [Int] = []) {
        self.options = options
        super.init(frame: CGRect.zero)
        
        backgroundColor = UIColor.clear
        
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(onPan))
        gesture.delegate = self
        addGestureRecognizer(gesture)
    }
    required init?(coder aDecoder: NSCoder) {fatalError()}
    
    func setTo(_ value: Int) {
        option = value
        guard width != 0 else { return }
        
        let p: CGFloat = 3*Screen.s
        let crx: CGFloat = 16*s

        let x1: CGFloat = p
        let x5: CGFloat = width - 2*p - 2*crx
        
        let tw: CGFloat = x5 - x1
        let ow: CGFloat = tw / CGFloat(options.count)
        
        let index: Int = options.firstIndex(where: { $0 == value }) ?? 0
        
        if index == 0 { position = 0 }
        else if index == options.count - 1 { position = x5 }
        else { position = (CGFloat(index)+0.5)*ow }
        
        setNeedsDisplay()
    }
    
// Events ==========================================================================================
    @objc func onPan(gesture: UIPanGestureRecognizer) {
        if gesture.state == .began {
            startX = gesture.location(in: self).x
            oldPos = position
            return
        } else if gesture.state == .changed {
            deltaX = gesture.location(in: self).x - startX

            let p: CGFloat = 3*Screen.s
            let crx: CGFloat = 16*s

            let x1: CGFloat = p
            let x5: CGFloat = width - 2*p - 2*crx
            
            let tw: CGFloat = x5 - x1
            let ow: CGFloat = tw / CGFloat(options.count)

            
            let newPos: CGFloat = (oldPos + deltaX).clamped(to: 0...tw)
            let index: Int = Int(newPos / ow).clamped(to: 0...(options.count-1))
            position = newPos

            option = options[index]
            onChange?(option)
            setNeedsDisplay()
        }
    }
    
// UIView ==========================================================================================
    override var frame: CGRect {
        didSet { setTo(option) }
    }
    override func draw(_ rect: CGRect) {
        let p: CGFloat = 3*s;
        let crx: CGFloat = 16*s
        let cry: CGFloat = 12*s
        
        let x1: CGFloat = p
        let x5: CGFloat = width - 2*p
        let x2: CGFloat = x1 + position
        let x3: CGFloat = x2 + crx
        let x4: CGFloat = x3 + crx
        let y2: CGFloat = height / 2
        let y1: CGFloat = y2 - cry
        
        let path = CGMutablePath()
        
        if (x2 > x1) {
            path.move(to: CGPoint(x: x1, y: y2))
            path.addLine(to: CGPoint(x: x2, y: y2))
        }
        if (x4 < x5) {
            path.move(to: CGPoint(x: x4, y: y2))
            path.addLine(to: CGPoint(x: x5, y: y2))
        }
        path.addEllipse(in: CGRect(x: x2, y: y1, width: 2*crx, height: 2*cry))
        
        let c = UIGraphicsGetCurrentContext();
        c?.addPath(path)

        c?.setStrokeColor(UIColor.white.cgColor)
        c?.setLineWidth(3)
        c?.strokePath()

        if option < 100 { "\(abs(option))".draw(in: CGRect(x: x2+6*s, y: y1+2*s, width: 20*s, height: 16*s), pen: pen2) }
        else if option < 1000 { "\(abs(option))".draw(in: CGRect(x: x2+6*s, y: y1+5*s, width: 20*s, height: 16*s), pen: pen3) }
        else { "\(abs(option))".draw(in: CGRect(x: x2+4*s, y: y1+6*s, width: 24*s, height: 12*s), pen: pen4) }
    }

// UIGestureRecognizerDelegate =====================================================================
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.phase != .began { return true }
        let x = touch.location(in: self).x
        return x > position && x < position + 2*16*s
    }
}
