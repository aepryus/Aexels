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
    var camera: UnsafeMutablePointer<NCCamera>

    var onVelocityChange: ((Velocity)->())?

    static let hyleColor: UIColor = UIColor(patternImage: UIImage(named: "hyle")!)
    
    override init(size: CGSize) {
        universe = NCUniverseCreate(size.width, size.height)
        NCUniverseCreateTeslon(universe, 360, 240, 0.0, 0.0, 1)
        NCUniverseCreateTeslon(universe, 360, 400, 0.0, 0.0, 1)
        camera = NCUniverseCreateCamera(universe, size.width/2, size.height/2, velocity, 0)
        super.init(size: size)
    }
    deinit { NCUniverseRelease(universe) }

    var speedOfLight: Double = 1 {
        didSet { universe.pointee.c = speedOfLight }
    }
    var velocity: Double = 0.5 {
        didSet {
            let v: Velocity = Velocity(speed: abs(velocity), orient: velocity > 0 ? Double.pi/2 : Double.pi*3/2)
            NCUniverseSetSpeed(universe, velocity)
            tic()
            onVelocityChange?(v)
        }
    }

    private func renderTeslon(c: CGContext, teslon: UnsafeMutablePointer<NCTeslon>, scale: CGFloat = 10) {
        let center: CGPoint = CGPoint(x: teslon.pointee.pos.x, y: teslon.pointee.pos.y)
        let r: CGFloat = 10*scale
        let ir: CGFloat = 7*scale
        let hr: CGFloat = 4*scale

        c.addArc(center: center, radius: r, startAngle: 0, endAngle: 2 * .pi, clockwise: false)
        c.addArc(center: center, radius: ir, startAngle: 2 * .pi, endAngle: 0, clockwise: true)
        c.move(to: center+hr*CGPoint(x: 1, y: 0))
        c.addArc(center: center, radius: hr*teslon.pointee.hyle, startAngle: 2 * .pi, endAngle: 0, clockwise: true)

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
    private func renderPing(c: CGContext, ping: UnsafeMutablePointer<NCPing>, scale: CGFloat = 10) {
        let center: CGPoint = CGPoint(x: ping.pointee.pos.x, y: ping.pointee.pos.y)
        let r: CGFloat = 3*scale

        c.addArc(center: center, radius: r, startAngle: 0, endAngle: 2 * .pi, clockwise: false)

        c.setFillColor(UIColor.black.tone(0.3).tint(0.7).alpha(0.5).cgColor)
        c.setStrokeColor(UIColor.black.tone(0.3).tint(0.4).cgColor)
        c.drawPath(using: .fillStroke)
        
        let q: CGFloat = ping.pointee.emOrient
        c.move(to: center)
        let end: CGPoint = center+r*CGPoint(x: cos(q), y: sin(q))
        c.addLine(to: end)
        c.setStrokeColor(UIColor.white.cgColor)
        c.setFillColor(UIColor.white.cgColor)
        c.setLineWidth(1*scale)
        c.setLineCap(.round)
        c.move(to: end+3*CGPoint(x: 1, y: 0))
        c.addArc(center: end, radius: 2.5, startAngle: 0, endAngle: 2 * .pi, clockwise: false)
        c.drawPath(using: .fillStroke)
    }
    private func renderPong(c: CGContext, pong: UnsafeMutablePointer<NCPong>, scale: CGFloat = 10) {
        let center: CGPoint = CGPoint(x: pong.pointee.pos.x, y: pong.pointee.pos.y)
        let r: CGFloat = 3*scale

        c.addArc(center: center, radius: r, startAngle: 0, endAngle: 2 * .pi, clockwise: false)

        let emColor: UIColor = UIColor.red.blend(with: .blue, percent: 0.5).tint(0.3).tone(0.3)

        c.setFillColor(emColor.cgColor)
        c.setStrokeColor(UIColor.black.cgColor)
        c.setLineWidth(1*scale)
        c.drawPath(using: .fillStroke)
                
        let q: CGFloat = pong.pointee.emOrient
        c.move(to: center)
        let end: CGPoint = center+r*CGPoint(x: cos(q), y: sin(q))
        c.addLine(to: end)
        c.setStrokeColor(UIColor.white.cgColor)
        c.setFillColor(UIColor.white.cgColor)
        c.setLineWidth(1*scale)
        c.setLineCap(.round)
        c.move(to: end+3*CGPoint(x: 1, y: 0))
        c.addArc(center: end, radius: 2.5, startAngle: 0, endAngle: 2 * .pi, clockwise: false)
        c.drawPath(using: .fillStroke)
    }
    private func renderPhoton(c: CGContext, photon: UnsafeMutablePointer<NCPhoton>, scale: CGFloat = 10) {
        let center: CGPoint = CGPoint(x: photon.pointee.pos.x, y: photon.pointee.pos.y)
        let hr: CGFloat = 4*scale

        c.addArc(center: center, radius: hr*photon.pointee.hyle, startAngle: 2 * .pi, endAngle: 0, clockwise: true)

        c.setFillColor(ElectromagnetismEngine.hyleColor.cgColor)
        c.setStrokeColor(UIColor.black.cgColor)
        c.setLineWidth(1*scale)
        c.drawPath(using: .fillStroke)
        
        let q: CGFloat = photon.pointee.emOrient
        c.move(to: center)
        let end: CGPoint = center+hr*CGPoint(x: cos(q), y: sin(q))
        c.addLine(to: end)
        c.setStrokeColor(UIColor.white.cgColor)
        c.setFillColor(UIColor.white.cgColor)
        c.setLineWidth(1*scale)
        c.setLineCap(.round)
        c.move(to: end+3*CGPoint(x: 1, y: 0))
        c.addArc(center: end, radius: 2.5, startAngle: 0, endAngle: 2 * .pi, clockwise: false)
        c.drawPath(using: .fillStroke)
    }

// Engine ==========================================================================================
    override var size: CGSize {
        didSet {
            universe.pointee.width = size.width
            universe.pointee.height = size.height
        }
    }
    override func onTic() {
        NCUniverseTic(universe)
    }
    func onPulse() {
        NCUniversePulse(universe, 32)
    }
    override func onRender(c: CGContext) {
        let dx: CGFloat = size.width/2 - camera.pointee.pos.x
        let dy: CGFloat = size.height/2 - camera.pointee.pos.y
        
        let d: CGFloat = 10.0*Screen.s
        let sn: CGFloat = d*CGFloat(sin(Double.pi/6))
        let mod: CGFloat = 2*(d+sn)

//        if let back { back.draw(at: .zero) }
        if let back { back.draw(at: CGPoint(x: dx.truncatingRemainder(dividingBy: mod), y: dy.truncatingRemainder(dividingBy: mod))) }

        let scale: CGFloat = 2
        for i in 0..<Int(universe.pointee.pingCount) { renderPing(c: c, ping: universe.pointee.pings![i]!, scale: scale) }
        for i in 0..<Int(universe.pointee.pongCount) { renderPong(c: c, pong: universe.pointee.pongs![i]!, scale: scale) }
        for i in 0..<Int(universe.pointee.photonCount) { renderPhoton(c: c, photon: universe.pointee.photons![i]!, scale: scale) }
        for i in 0..<Int(universe.pointee.teslonCount) { renderTeslon(c: c, teslon: universe.pointee.teslons![i]!, scale: scale) }
    }
}
