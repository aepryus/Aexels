//
//  ElectromagentismEngine.swift
//  Aexels
//
//  Created by Joe Charlier on 12/12/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

import Acheron
import UIKit

class ElectromagnetismEngine: Engine {
    
    var universe: UnsafeMutablePointer<NCUniverse>
    static let hyleColor: UIColor = UIColor(patternImage: UIImage(named: "hyle")!)
    
    override init(size: CGSize) {
        universe = NCUniverseCreate()
        NCUniverseCreateTeslon(universe, 120, 120, 0, 0)
        NCUniverseCreatePing(universe, 250, 250, 0, 0)
        NCUniverseCreatePong(universe, 350, 350, 0, 0)
        NCUniverseCreatePhoton(universe, 500, 500, 0, 0)
        super.init(size: size)
    }
    
    private func renderTeslon(c: CGContext, teslon: UnsafeMutablePointer<NCTeslon>, scale: CGFloat = 10) {
        let r: CGFloat = 10*scale
        let ir: CGFloat = 7*scale
        let center: CGPoint = CGPoint(x: teslon.pointee.pos.x, y: teslon.pointee.pos.y)

        c.addArc(center: center, radius: r, startAngle: 0, endAngle: 2 * .pi, clockwise: false)
        c.addArc(center: center, radius: ir, startAngle: 2 * .pi, endAngle: 0, clockwise: true)
        
        for i in 1...3 {
            let q: CGFloat = .pi*2/3*CGFloat(i)
            c.move(to: center+r*CGPoint(x: cos(q), y: sin(q)))
            c.addLine(to: center+ir*CGPoint(x: cos(q), y: sin(q)))
        }

        c.setFillColor(ElectromagnetismEngine.hyleColor.cgColor)
        c.setStrokeColor(UIColor.black.cgColor)
        c.setLineWidth(1*scale)
        c.drawPath(using: .fillStroke)
    }
    private func renderPing(c: CGContext, teslon: UnsafeMutablePointer<NCPing>, scale: CGFloat = 10) {
        let r: CGFloat = 3*scale
        let center: CGPoint = CGPoint(x: teslon.pointee.pos.x, y: teslon.pointee.pos.y)
        let path: CGMutablePath = CGMutablePath(ellipseIn: CGRect(origin: center+CGPoint(x: -r, y: -r), size: CGSize(width: 2*r, height: 2*r)), transform: nil)
        c.addPath(path)
        c.setFillColor(UIColor.black.tone(0.3).tint(0.7).alpha(0.5).cgColor)
        c.setStrokeColor(UIColor.black.tone(0.3).tint(0.4).cgColor)
        c.drawPath(using: .fillStroke)
    }
    private func renderPong(c: CGContext, teslon: UnsafeMutablePointer<NCPong>, scale: CGFloat = 10) {
        let r: CGFloat = 3*scale
        let center: CGPoint = CGPoint(x: teslon.pointee.pos.x, y: teslon.pointee.pos.y)
        let path: CGMutablePath = CGMutablePath(ellipseIn: CGRect(origin: center+CGPoint(x: -r, y: -r), size: CGSize(width: 2*r, height: 2*r)), transform: nil)
        c.addPath(path)
        c.setFillColor(UIColor.red.tone(0.3).tint(0.7).alpha(0.5).cgColor)
        c.setStrokeColor(UIColor.red.tone(0.3).tint(0.4).cgColor)
        c.drawPath(using: .fillStroke)
    }
    private func renderPhoton(c: CGContext, teslon: UnsafeMutablePointer<NCPhoton>, scale: CGFloat = 10) {
        let r: CGFloat = 5*scale
        let center: CGPoint = CGPoint(x: teslon.pointee.pos.x, y: teslon.pointee.pos.y)
        let path: CGMutablePath = CGMutablePath(ellipseIn: CGRect(origin: center+CGPoint(x: -r, y: -r), size: CGSize(width: 2*r, height: 2*r)), transform: nil)
        c.addPath(path)
        c.setFillColor(UIColor.green.tone(0.3).tint(0.7).alpha(0.5).cgColor)
        c.setStrokeColor(UIColor.green.tone(0.3).tint(0.4).cgColor)
        c.drawPath(using: .fillStroke)
    }

// Engine ==========================================================================================
    override func onTic() {
    }
    override func onRender(c: CGContext) {
        if let back { back.draw(at: .zero) }
        
        for i in 0..<Int(universe.pointee.teslonCount) { renderTeslon(c: c, teslon: universe.pointee.teslons![i]!) }
        for i in 0..<Int(universe.pointee.pingCount) { renderPing(c: c, teslon: universe.pointee.pings![i]!) }
        for i in 0..<Int(universe.pointee.pongCount) { renderPong(c: c, teslon: universe.pointee.pongs![i]!) }
        for i in 0..<Int(universe.pointee.photonCount) { renderPhoton(c: c, teslon: universe.pointee.photons![i]!) }
    }
}
