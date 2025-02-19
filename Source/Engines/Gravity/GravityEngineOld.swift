//
//  GravityEngine.swift
//  Aexels
//
//  Created by Joe Charlier on 9/5/23.
//  Copyright © 2023 Aepryus Software. All rights reserved.
//

import Acheron
import OoviumEngine
import UIKit

class GravityEngine: Engine {
    var universe: UnsafeMutablePointer<MCUniverse>

    private var queue: DispatchQueue = DispatchQueue(label: "aexelsView")
    
    init(size: CGSize) {
        universe = MCUniverseCreate(size.width, size.height)
        MCUniverseCreateRing(universe, 350)
        MCUniverseCreateRing(universe, 270)
        MCUniverseCreateRing(universe, 210)
        MCUniverseCreateRing(universe, 170)
        MCUniverseCreateRing(universe, 140)
        MCUniverseCreateRing(universe, 120)
        MCUniverseCreateRing(universe, 100)
        MCUniverseCreateMoon(universe, -160, -120, 20)
        super.init(size: size, background: .square)
    }
    deinit { MCUniverseRelease(universe) }
    
    private func renderRing(c: CGContext, ring: UnsafeMutablePointer<MCRing>) {
        let dx: CGFloat = size.width/2
        let dy: CGFloat = size.height/2
        let center: CGPoint = CGPoint(x: dx, y: dy)
        
        let radius: CGFloat = ring.pointee.radius

        c.addArc(center: center, radius: radius, startAngle: 2 * .pi, endAngle: 0, clockwise: true)

        c.setFillColor(UIColor.blue.tone(0.5).tint(0.5).alpha(0.3).cgColor)
        c.setStrokeColor(UIColor.black.cgColor)
        c.setLineWidth(1)
        c.drawPath(using: .fillStroke)
    }
    private func renderPlanet(c: CGContext, planet: UnsafeMutablePointer<MCPlanet>) {
        let dx: CGFloat = size.width/2
        let dy: CGFloat = size.height/2
        let center: CGPoint = CGPoint(x: dx, y: dy)
        
        let radius: CGFloat = planet.pointee.radius

        c.addArc(center: center, radius: radius, startAngle: 2 * .pi, endAngle: 0, clockwise: true)

        c.setFillColor(OOColor.cobolt.uiColor.cgColor)
        c.setStrokeColor(UIColor.black.cgColor)
        c.setLineWidth(1)
        c.drawPath(using: .fillStroke)
    }
    private func renderMoon(c: CGContext, moon: UnsafeMutablePointer<MCMoon>) {
        let dx: CGFloat = size.width/2
        let dy: CGFloat = size.height/2
        let center: CGPoint = CGPoint(x: dx + moon.pointee.pos.x, y: dy + moon.pointee.pos.y)
        
        let radius: CGFloat = moon.pointee.radius

        c.addArc(center: center, radius: radius, startAngle: 2 * .pi, endAngle: 0, clockwise: true)

        c.setFillColor(OOColor.marine.uiColor.cgColor)
        c.setStrokeColor(UIColor.black.cgColor)
        c.setLineWidth(1)
        c.drawPath(using: .fillStroke)
    }
        
// Engine ==========================================================================================
    override func onRender(c: CGContext) {
        let dx: CGFloat = size.width/2
        let dy: CGFloat = size.height/2
        
        let d: CGFloat = 10.0*Screen.s
        let sn: CGFloat = d*CGFloat(sin(Double.pi/6))
        let mod: CGFloat = 2*(d+sn)

        if let back { back.draw(at: CGPoint(x: dx.truncatingRemainder(dividingBy: mod), y: dy.truncatingRemainder(dividingBy: mod))) }

        for i in 0..<Int(universe.pointee.ringCount) { renderRing(c: c, ring: universe.pointee.rings![i]!) }
        renderPlanet(c: c, planet: universe.pointee.planet)
        for i in 0..<Int(universe.pointee.moonCount) { renderMoon(c: c, moon: universe.pointee.moons![i]!) }
    }
}
