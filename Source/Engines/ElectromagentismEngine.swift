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
    var velocity: Double = 0 {
        didSet {
            let v: Velocity = Velocity(speed: abs(velocity), orient: velocity > 0 ? 0 : .pi)
            NCUniverseSetSpeed(universe, velocity)
            tic()
            onVelocityChange?(v)
        }
    }

    private func renderTeslon(c: CGContext, teslon: UnsafeMutablePointer<NCTeslon>, camera: UnsafeMutablePointer<NCCamera>, scale: CGFloat = 10) {
        let dx: CGFloat = camera.pointee.width/2 - camera.pointee.pos.x
        let dy: CGFloat = camera.pointee.height/2 - camera.pointee.pos.y
        let center: CGPoint = CGPoint(x: dx + teslon.pointee.pos.x, y: dy + teslon.pointee.pos.y)
        
        let iro: CGFloat = 10*scale
        let iri: CGFloat = 7*scale
        
        let vC: CGFloat = camera.pointee.v.speed
        let vT: CGFloat = teslon.pointee.v.speed
        let gC: CGFloat = 1/sqrt(1-vC*vC)
        let gT: CGFloat = 1/sqrt(1-vT*vT)
        let iA: CGFloat = .pi * (iro*iro - iri*iri)
        let tA: CGFloat = iA * (gT - 1)
        
        let tri: CGFloat = iro
//        let tro: CGFloat = iro
        let mro: CGFloat = min(sqrt(tA / .pi), iri)
        let tAo: CGFloat = tA - .pi * mro * mro
        let tro: CGFloat = sqrt((tAo + .pi * tri * tri) / .pi)

        c.addArc(center: center, radius: tro, startAngle: 0, endAngle: 2 * .pi, clockwise: false)
        c.move(to: center+iri*CGPoint(x: 1, y: 0))
        c.addArc(center: center, radius: iri, startAngle: 2 * .pi, endAngle: 0, clockwise: true)

        for i in 1...3 {
            let q: CGFloat = .pi*2/3*CGFloat(i)
            c.move(to: center+iro*CGPoint(x: cos(q), y: sin(q)))
            c.addLine(to: center+iri*CGPoint(x: cos(q), y: sin(q)))
        }

        c.setFillColor(ElectromagnetismEngine.hyleColor.cgColor)
        c.setStrokeColor(UIColor.black.cgColor)
        c.setLineWidth(1*scale)
        c.drawPath(using: .fillStroke)
        
        c.addArc(center: center, radius: iro, startAngle: 0, endAngle: 2 * .pi, clockwise: false)
        c.setLineWidth(1)
        c.drawPath(using: .stroke)
        
        c.move(to: center+mro*CGPoint(x: 1, y: 0))
        c.addArc(center: center, radius: mro*teslon.pointee.hyle, startAngle: 2 * .pi, endAngle: 0, clockwise: true)

        c.setFillColor(ElectromagnetismEngine.hyleColor.cgColor)
        c.setStrokeColor(UIColor.black.cgColor)
        c.setLineWidth(1*scale)
        c.drawPath(using: .fillStroke)
    }
    private func renderPing(c: CGContext, ping: UnsafeMutablePointer<NCPing>, camera: UnsafeMutablePointer<NCCamera>, scale: CGFloat = 10) {
        let dx: CGFloat = camera.pointee.width/2 - camera.pointee.pos.x
        let dy: CGFloat = camera.pointee.height/2 - camera.pointee.pos.y
        let center: CGPoint = CGPoint(x: dx + ping.pointee.pos.x, y: dy + ping.pointee.pos.y)
        let r: CGFloat = 2*scale
        
        c.addArc(center: center, radius: r, startAngle: 0, endAngle: 2 * .pi, clockwise: false)
        c.move(to: center)
        c.addLine(to: center+CGPoint(x: 3*r*VelocityX(ping.pointee.v), y: 3*r*VelocityY(ping.pointee.v)))

        c.setFillColor(UIColor.black.tint(0.6).cgColor)
        c.setStrokeColor(UIColor.black.tint(0.6).cgColor)
        c.drawPath(using: .fillStroke)
        
        let frameV: CGPoint = CGPoint(x: VelocityX(ping.pointee.v) - VelocityX(camera.pointee.v), y: VelocityY(ping.pointee.v) - VelocityY(camera.pointee.v)).unit()
        c.addArc(center: center, radius: r/2, startAngle: 0, endAngle: 2 * .pi, clockwise: false)
        c.move(to: center)
        c.addLine(to: center + 2.5 * r * frameV )

        c.setFillColor(UIColor.black.tint(0.96).cgColor)
        c.setStrokeColor(UIColor.black.tint(0.96).cgColor)
        c.drawPath(using: .fillStroke)
        
        let emPoint: CGPoint = CGPoint(x: cos(ping.pointee.emOrient), y: -sin(ping.pointee.emOrient))
        c.addArc(center: center, radius: r/4, startAngle: 0, endAngle: 2 * .pi, clockwise: false)
        c.move(to: center)
        c.addLine(to: center + 1.5 * r * emPoint.unit() )
        
        let emColor: UIColor = .red.blend(with: .blue, percent: 1 - abs(emPoint.dot(frameV))).tone(0.5).tint(0.1)

        c.setFillColor(emColor.cgColor)
        c.setStrokeColor(emColor.cgColor)
        c.drawPath(using: .fillStroke)
    }
    private func renderPong(c: CGContext, pong: UnsafeMutablePointer<NCPong>, camera: UnsafeMutablePointer<NCCamera>, scale: CGFloat = 10) {
        let dx: CGFloat = camera.pointee.width/2 - camera.pointee.pos.x
        let dy: CGFloat = camera.pointee.height/2 - camera.pointee.pos.y
        let center: CGPoint = CGPoint(x: dx + pong.pointee.pos.x, y: dy + pong.pointee.pos.y)
        let r: CGFloat = 2*scale
        
        // Aether Vector
        c.move(to: center)
        c.addLine(to: center+CGPoint(x: 3*r*VelocityX(pong.pointee.v), y: 3*r*VelocityY(pong.pointee.v)))

        c.setFillColor(UIColor.black.tint(0.6).cgColor)
        c.setStrokeColor(UIColor.black.tint(0.6).cgColor)
        c.drawPath(using: .fillStroke)
        
        // Body and E/M Vector
        let frameV: CGPoint = CGPoint(x: VelocityX(pong.pointee.v) - VelocityX(camera.pointee.v), y: VelocityY(pong.pointee.v) - VelocityY(camera.pointee.v)).unit()
        
        let spread: CGFloat = .pi / 3
        
        let emOrient: CGFloat = pong.pointee.emOrient
        let start: CGFloat = emOrient - spread / 2
        let stop: CGFloat = emOrient + spread / 2
        
        let startPoint: CGPoint = center + r * CGPoint(x: cos(start), y: -sin(start))
        let stopPoint: CGPoint = center + r * CGPoint(x: cos(stop), y: -sin(stop))

        let emPoint: CGPoint = CGPoint(x: cos(pong.pointee.emOrient), y: -sin(pong.pointee.emOrient))
        c.addArc(center: center, radius: r, startAngle: 2 * .pi - start, endAngle: 2 * .pi - stop, clockwise: false)
        c.move(to: startPoint)
        c.addLine(to: center + 3 * r * emPoint.unit() )
        c.addLine(to: stopPoint)

        let emColor: UIColor = .red.blend(with: .blue, percent: 1 - abs(emPoint.dot(frameV)))

        c.setFillColor(emColor.cgColor)
        c.setStrokeColor(UIColor.black.cgColor)
        c.drawPath(using: .fillStroke)
        
        c.setFillColor(emColor.cgColor)
        c.setStrokeColor(emColor.cgColor)
        c.drawPath(using: .fillStroke)
        
        // Frame Vector
        c.move(to: center)
        c.addLine(to: center + 2 * r * frameV )
        
        c.setFillColor(UIColor.black.tint(0.96).cgColor)
        c.setStrokeColor(UIColor.black.tint(0.96).cgColor)
        c.drawPath(using: .fillStroke)
    }
    private func renderPhoton(c: CGContext, photon: UnsafeMutablePointer<NCPhoton>, camera: UnsafeMutablePointer<NCCamera>, scale: CGFloat = 10) {
        let dx: CGFloat = camera.pointee.width/2 - camera.pointee.pos.x
        let dy: CGFloat = camera.pointee.height/2 - camera.pointee.pos.y
        let center: CGPoint = CGPoint(x: dx + photon.pointee.pos.x, y: dy + photon.pointee.pos.y)
        let hr: CGFloat = 4*scale

        c.addArc(center: center, radius: hr*photon.pointee.hyle, startAngle: 2 * .pi, endAngle: 0, clockwise: true)

        c.setFillColor(ElectromagnetismEngine.hyleColor.cgColor)
        c.setStrokeColor(UIColor.black.cgColor)
        c.setLineWidth(1*scale)
        c.drawPath(using: .fillStroke)
        
        let q: CGFloat = photon.pointee.emOrient
        c.move(to: center)
        let end: CGPoint = center+hr*CGPoint(x: cos(q), y: -sin(q))
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
            camera.pointee.pos.x = size.width / 2
            camera.pointee.pos.y = size.height / 2
            camera.pointee.width = size.width
            camera.pointee.height = size.height
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

        if let back { back.draw(at: CGPoint(x: dx.truncatingRemainder(dividingBy: mod), y: dy.truncatingRemainder(dividingBy: mod))) }

        let scale: CGFloat = 2
        for i in 0..<Int(universe.pointee.pingCount) { renderPing(c: c, ping: universe.pointee.pings![i]!, camera: camera, scale: scale) }
        for i in 0..<Int(universe.pointee.pongCount) { renderPong(c: c, pong: universe.pointee.pongs![i]!, camera: camera, scale: scale) }
        for i in 0..<Int(universe.pointee.photonCount) { renderPhoton(c: c, photon: universe.pointee.photons![i]!, camera: camera, scale: scale) }
        for i in 0..<Int(universe.pointee.teslonCount) { renderTeslon(c: c, teslon: universe.pointee.teslons![i]!, camera: camera, scale: scale) }
    }
}
