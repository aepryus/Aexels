//
//  TimeControl.swift
//  Aexels
//
//  Created by Joe Charlier on 1/22/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

import Acheron
import UIKit

protocol TimeControlDelegate: AnyObject {
    func onPlay()
    func onStep()
    func onReset()
    func onStop()
}
extension TimeControlDelegate {
    func onPlay() {}
    func onStep() {}
    func onReset() {}
    func onStop() {}
}

class TimeControl: AEView {
    weak var delegate: TimeControlDelegate?
    
    let playButton: PlayButton = PlayButton()
    let resetButton: ResetButton = ResetButton()
    let stepButton: StepButton = StepButton()
    
    var path: CGMutablePath!
    
    override init() {
        super.init()
        backgroundColor = .clear
        renderPath()
        
        playButton.onPlay = { self.delegate?.onPlay() }
        stepButton.addAction { self.delegate?.onStep() }
        resetButton.addAction { self.delegate?.onReset() }
        playButton.onStop = { self.delegate?.onStop() }

        addSubview(playButton)
        addSubview(stepButton)
        addSubview(resetButton)
    }
    
    func renderPath() {
        let p: CGFloat = 3*s                      // padding
        let cr: CGFloat = 24*s                    // center radius
        let sr: CGFloat = 21*s                    // side radius
        let ol: CGFloat = 12*s                    // overlap
        
        let d: CGFloat = sr+cr-ol
        let aA = acos((d*d+sr*sr-cr*cr)/(2*d*sr))
        let aB = acos((d*d-sr*sr+cr*cr)/(2*d*cr))
        
        path = CGMutablePath()
        path.addArc(center: CGPoint(x: p+sr, y: p+cr), radius: sr, startAngle: aA, endAngle: -aA, clockwise: false)
        path.addArc(center: CGPoint(x: p+sr*2+cr-ol, y: p+cr), radius: cr, startAngle: aB+CGFloat.pi, endAngle: -aB, clockwise: false)
        path.addArc(center: CGPoint(x: p+sr*3+cr*2-2*ol, y: p+cr), radius: sr, startAngle: aA+CGFloat.pi, endAngle: -aA+CGFloat.pi, clockwise: false)
        path.addArc(center: CGPoint(x: p+sr*2+cr-ol, y: p+cr), radius: cr, startAngle: aB, endAngle: -(aB+CGFloat.pi), clockwise: false)
    }
    
// UIView ==========================================================================================
    override func setNeedsDisplay() {
        super.setNeedsDisplay()
        playButton.setNeedsDisplay()
        resetButton.setNeedsDisplay()
        stepButton.setNeedsDisplay()
    }
    override func layoutSubviews() {
        playButton.center(size: playButton.bounds.size)
        stepButton.center(dx: 33*s, size: stepButton.bounds.size)
        resetButton.center(dx: -33*s, size: resetButton.bounds.size)
    }
    override func draw(_ rect: CGRect) {
        let stroke = UIColor.white
//        let fill = stroke.shade(0.5)
        let c = UIGraphicsGetCurrentContext()!
        c.addPath(path)
//        c.setFillColor(fill.cgColor)
        c.setStrokeColor(stroke.cgColor)
        c.setLineWidth(2)
        c.drawPath(using: .stroke)
    }
}
