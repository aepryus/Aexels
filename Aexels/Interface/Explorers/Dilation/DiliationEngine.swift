//
//  DiliationEngine.swift
//  Aexels
//
//  Created by Joe Charlier on 12/6/22.
//  Copyright © 2022 Aepryus Software. All rights reserved.
//

import Acheron
import UIKit

class DilationEngine {
    let size: CGSize
    
    var autoOn: Bool = true
    
    var universe: UnsafeMutablePointer<TCUniverse>
    var source: UnsafeMutablePointer<TCTeslon>
    var vertical: UnsafeMutablePointer<TCTeslon>
    var horizontal: UnsafeMutablePointer<TCTeslon>?
    var camera: UnsafeMutablePointer<TCCamera>

    private let queue: DispatchQueue = DispatchQueue(label: "dilation")
    
    var views: [DilationView] = []
    
    init(size: CGSize) {
        self.size = size
        
        universe = TCUniverseCreate(size.width, size.height, 1)
        source = TCUniverseCreateTeslon(universe, size.width/2, size.height/2, velocity, .pi/2)
        vertical = TCUniverseCreateTeslon(universe, size.width/2, size.height/4, velocity, .pi/2)
        camera = TCUniverseCreateCamera(universe, size.width/2, size.height/2, velocity, .pi/2)
    }
    deinit { TCUniverseRelease(universe) }

    var speedOfLight: Double = 1 {
        didSet {
            universe.pointee.c = speedOfLight
        }
    }
    var velocity: Double = 0.5 {
        didSet {
            let v: TCVelocity = TCVelocity(s: abs(velocity), q: velocity > 0 ? Double.pi/2 : Double.pi*3/2)
            source.pointee.v = v
            vertical.pointee.v = v
            horizontal?.pointee.v = v
            camera.pointee.v = v
        }
    }
    
    func createCamera(teleport: Bool = false) -> UnsafeMutablePointer<TCCamera> {
        TCUniverseCreateCamera(universe, size.width/2, size.height/2, teleport ? 0 : velocity, .pi/2)
    }
    
    func reset() {
        TCUniverseRelease(universe)
        TCTeslonRelease(source)
        TCTeslonRelease(vertical)
        if horizontal != nil { TCTeslonRelease(horizontal) }

//        let topY: CGFloat = Screen.safeTop + (Screen.mac ? 5*Screen.s : 0)
//        let botY: CGFloat = Screen.safeBottom + (Screen.mac ? 5*Screen.s : 0)
//        let height = Screen.height - topY - botY
//        let s = height / 748
//        let uw: CGFloat = height - 110*s - 46*s

        universe = TCUniverseCreate(size.width, size.height, 1)
        source = TCUniverseCreateTeslon(universe, size.width/2, size.height/2, velocity, .pi/2)
        vertical = TCUniverseCreateTeslon(universe, size.width/2, size.height/4, velocity, .pi/2)
        camera = TCUniverseCreateCamera(universe, size.width/2, size.height/2, velocity, .pi/2)
    }
    
    func pulse() { TCUniversePulse(universe, source, 99) }
    
    func tic() {
        queue.sync {
            TCUniverseTic(self.universe)
            renderMode = .started
            renderImage()
            DispatchQueue.main.async { self.views.forEach { $0.setNeedsDisplay() } }
        }
    }
    
    var n: Int = 1
    func play() {
        Aexels.sync.onFire = { (link: CADisplayLink, complete: @escaping ()->()) in
            self.tic()
            self.n += 1
            if self.autoOn && self.n % 120 == 0 { self.pulse() }
            complete()
        }
        Aexels.sync.link.preferredFramesPerSecond = 60
        Aexels.sync.start()
    }
    func stop() { Aexels.sync.stop() }
    

// Render Image ====================================================================================
    
    var trailsOn: Bool = false

    private var s: CGFloat { Screen.s }
    var renderMode: RenderMode = .started

    var image: UIImage?
    private var back: UIImage?
    private var fore: UIImage?

    func renderBack() {
        let d: CGFloat = 10.0*s
        let sn: CGFloat = d*CGFloat(sin(Double.pi/6))
        let cs: CGFloat = d*CGFloat(cos(Double.pi/6))
        
        let w: CGFloat = size.width+100+2*(d+sn)
        let h: CGFloat = size.height+100+2*cs
        let n = (Int(w/(2*(d+sn))))+1
        let m = (Int(h/(2*cs)))+1
        var x: CGFloat = 1
        var y: CGFloat = 1

        UIGraphicsBeginImageContext(size)
        let c = UIGraphicsGetCurrentContext()!

        let path = CGMutablePath()

        for _ in 0..<n {
            for _ in 0..<m {
                path.move(to: CGPoint(x: x+sn, y: y))
                path.addLine(to: CGPoint(x: x+sn+d, y: y))
                path.addLine(to: CGPoint(x: x+2*sn+d, y: y+cs))
                path.addLine(to: CGPoint(x: x+sn+d, y: y+2*cs))
                path.addLine(to: CGPoint(x: x+sn, y: y+2*cs))
                path.addLine(to: CGPoint(x: x, y: y+cs))
                path.closeSubpath()
                
                y += 2*cs;
            }
            
            x += 3*d;
            y = 1;
        }
        x = sn+d+1;
        y = cs+1;
        for _ in 0..<n {
            for _ in 0..<m {
                path.move(to: CGPoint(x: x+sn, y: y))
                path.addLine(to: CGPoint(x: x+sn+d, y: y))
                path.addLine(to: CGPoint(x: x+2*sn+d, y: y+cs))
                path.addLine(to: CGPoint(x: x+sn+d, y: y+2*cs))
                path.addLine(to: CGPoint(x: x+sn, y: y+2*cs))
                path.addLine(to: CGPoint(x: x, y: y+cs))
                path.closeSubpath()
                
                y += 2*cs;
            }
            
            x += 3*d;
            y = cs+1;
        }

        c.addPath(path)
        c.setStrokeColor(UIColor.white.shade(0.6).cgColor)
        c.drawPath(using: .stroke)

        self.back = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    func renderImage() {
        guard renderMode == .started else { return }
        renderMode = .rendering
        
        if back == nil { renderBack() }
        
        let ll: CGFloat = 10
        let dx: CGFloat = size.width/2 - camera.pointee.p.x
        let dy: CGFloat = size.height/2 - camera.pointee.p.y
        
//        if chaseCameraOn {
//            let tolerance = width/2+10
//            if engine.source.pointee.v.q == .pi/2 {
//                if engine.source.pointee.p.x - camera.pointee.p.x > tolerance {
//                    camera.pointee.p.x += tolerance*2
//                }
//            } else {
//                if camera.pointee.p.x - engine.source.pointee.p.x > tolerance {
//                    camera.pointee.p.x -= tolerance*2
//                }
//            }
//        }
        
        let d: CGFloat = 10.0*s
        let sn: CGFloat = d*CGFloat(sin(Double.pi/6))
        let mod: CGFloat = 2*(d+sn)
        
        // Fore ====================================================================================
        UIGraphicsBeginImageContext(size)
        var c = UIGraphicsGetCurrentContext()!

        for i in 0..<Int(universe.pointee.maxtonCount) {
            let maxton = universe.pointee.maxtons![i]!
            if trailsOn {
                let path = CGMutablePath()
                let o: CGPoint = CGPoint(x: dx+maxton.pointee.o.x, y: dy+maxton.pointee.o.y)
                let p: CGPoint = CGPoint(x: dx+maxton.pointee.p.x, y: dy+maxton.pointee.p.y)
                let lenSq = (o-p).lengthSquared()
                if lenSq < ll*ll {
                    path.move(to: o)
                } else {
                    path.move(to: p+(o-p).unit()*ll)
                }
                path.addLine(to: p)
                c.addPath(path)
                c.setStrokeColor(UIColor.green.tone(0.3).tint(0.4).cgColor)
                c.drawPath(using: .stroke)
            }
            let r: Double = 1
            let path = CGMutablePath(ellipseIn: CGRect(x: dx+maxton.pointee.p.x-r, y: dy+maxton.pointee.p.y-r, width: 2*r, height: 2*r), transform: nil)
            c.addPath(path)
            c.setStrokeColor(UIColor.green.tint(0.7).tone(0.5).cgColor)
            c.drawPath(using: .stroke)
        }
        
        for i in 0..<Int(universe.pointee.photonCount) {
            let photon = universe.pointee.photons![i]!
            if trailsOn {
                let path = CGMutablePath()
                let o: CGPoint = CGPoint(x: dx+photon.pointee.o.x, y: dy+photon.pointee.o.y)
                let p: CGPoint = CGPoint(x: dx+photon.pointee.p.x, y: dy+photon.pointee.p.y)
                let lenSq = (o-p).lengthSquared()
                if lenSq < ll*ll {
                    path.move(to: o)
                } else {
                    path.move(to: p+(o-p).unit()*ll)
                }
                path.addLine(to: p)
                c.addPath(path)
                c.setStrokeColor(UIColor.red.tone(0.3).tint(0.4).cgColor)
                c.drawPath(using: .stroke)
            }
            let r: Double = 1
            let path = CGMutablePath(ellipseIn: CGRect(x: dx+photon.pointee.p.x-r, y: dy+photon.pointee.p.y-r, width: 2*r, height: 2*r), transform: nil)
            c.addPath(path)
            c.setStrokeColor(UIColor.red.tint(0.5).cgColor)
            c.drawPath(using: .stroke)
        }

        for i in 0..<Int(universe.pointee.teslonCount) {
            let teslon: UnsafeMutablePointer<TCTeslon> = universe.pointee.teslons![i]!
//            if trailsOn {
//                let path = CGMutablePath()
//                let o: CGPoint = CGPoint(x: dx+teslon.pointee.o.x, y: dy+teslon.pointee.o.y)
//                let p: CGPoint = CGPoint(x: dx+teslon.pointee.p.x, y: dy+teslon.pointee.p.y)
//                let lenSq = (o-p).lengthSquared()
//                if lenSq < ll*ll {
//                    path.move(to: o)
//                } else {
//                    path.move(to: p+(o-p).unit()*ll)
//                }
//                path.addLine(to: p)
//                c.addPath(path)
//                c.setStrokeColor(UIColor.blue.tone(0.3).tint(0.4).cgColor)
//                c.drawPath(using: .stroke)
//            }
            let r: Double = 10
            let path = CGPath(ellipseIn: CGRect(x: dx+teslon.pointee.p.x-r, y: dy+teslon.pointee.p.y-r, width: 2*r, height: 2*r), transform: nil)
            c.addPath(path)
            c.setFillColor(UIColor.blue.tone(0.3).tint(0.7).cgColor)
            c.setStrokeColor(UIColor.blue.tone(0.3).tint(0.4).cgColor)
            c.drawPath(using: .fillStroke)
        }
        
        fore = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        // Image ==================================================================================
        
        UIGraphicsBeginImageContext(size)
        c = UIGraphicsGetCurrentContext()!

        if let back { back.draw(at: CGPoint(x: dx.truncatingRemainder(dividingBy: mod), y: dy.truncatingRemainder(dividingBy: mod))) }
        if let fore { fore.draw(at: CGPoint.zero) }
        self.image = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        renderMode = .rendered
    }
}
