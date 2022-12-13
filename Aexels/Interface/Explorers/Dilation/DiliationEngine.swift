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
    var tailsOn: Bool = true
    var contractOn: Bool = true
    let horizontalOn: Bool
    
    var universe: UnsafeMutablePointer<TCUniverse>
    var source: UnsafeMutablePointer<TCTeslon>
    var vertical: UnsafeMutablePointer<TCTeslon>
    var horizontal: UnsafeMutablePointer<TCTeslon>?
    var camera: UnsafeMutablePointer<TCCamera>
    
    var onVelocityChange: ((TCVelocity)->())?
    
    private let queue: DispatchQueue = DispatchQueue(label: "dilation")
    private let iterations: Int = ProcessInfo.processInfo.activeProcessorCount + 1
    
    var views: [DilationView] = []
    
    init(size: CGSize, horizontalOn: Bool = false) {
        self.size = size
        self.horizontalOn = horizontalOn
        
        universe = TCUniverseCreate(size.width, size.height, 1)
        source = TCUniverseCreateTeslon(universe, size.width/2, size.height/2, velocity, .pi/2)
        vertical = TCUniverseCreateTeslon(universe, size.width/2, size.height/4, velocity, .pi/2)
        camera = TCUniverseCreateCamera(universe, size.width/2, size.height/2, velocity, .pi/2)
        if horizontalOn { initializeHorizontal() }
    }
    deinit { TCUniverseRelease(universe) }
    
    var speedOfLight: Double = 1 {
        didSet { universe.pointee.c = speedOfLight }
    }
    var velocity: Double = 0.5 {
        didSet {
            let v: TCVelocity = TCVelocity(s: abs(velocity), q: velocity > 0 ? Double.pi/2 : Double.pi*3/2)
            source.pointee.v = v
            vertical.pointee.v = v
            horizontal?.pointee.v = v
            camera.pointee.v = v
            positionHorizontal()
            tic()
            onVelocityChange?(v)
        }
    }
    
    func initializeHorizontal() {
        horizontal = TCUniverseCreateTeslon(universe, size.width/2 + size.height/4, size.height/2, velocity, .pi/2)
        positionHorizontal()
    }
    func positionHorizontal() {
        horizontal?.pointee.p = TCV2(x: source.pointee.p.x + size.height/4/(contractOn ? TCLambda(velocity) : 1), y: source.pointee.p.y)
    }
    func swapContract() {
        contractOn = !contractOn
        positionHorizontal()
        tic()
    }
    
    func reset() {
        TCUniverseRelease(universe)
        TCTeslonRelease(source)
        TCTeslonRelease(vertical)
        if horizontalOn { TCTeslonRelease(horizontal) }
        
        universe = TCUniverseCreate(size.width, size.height, 1)
        source = TCUniverseCreateTeslon(universe, size.width/2, size.height/2, velocity, .pi/2)
        vertical = TCUniverseCreateTeslon(universe, size.width/2, size.height/4, velocity, .pi/2)
        camera = TCUniverseCreateCamera(universe, size.width/2, size.height/2, velocity, .pi/2)
        self.velocity = { self.velocity }()
        self.speedOfLight = { self.speedOfLight }()
        if horizontalOn { initializeHorizontal() }
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
    
    private func findEnds(from: Int, to: Int) {
        let ll: CGFloat = 10

        for i in from..<to {
            let maxton: UnsafeMutablePointer<TCMaxton> = universe.pointee.maxtons![i]!
                
            let a: TCV2 = TCV2Sub(maxton.pointee.o, maxton.pointee.p)
            let b: Double = TCV2Length(a)
            let c: TCV2 = TCV2Mul(a, ll/b)
            maxton.pointee.e = TCV2Add(maxton.pointee.p, c)
        }
    }
    func renderImage() {
        guard renderMode == .started else { return }
        renderMode = .rendering
        
        if back == nil { renderBack() }
        
        let dx: CGFloat = size.width/2 - camera.pointee.p.x
        let dy: CGFloat = size.height/2 - camera.pointee.p.y
        
        let d: CGFloat = 10.0*s
        let sn: CGFloat = d*CGFloat(sin(Double.pi/6))
        let mod: CGFloat = 2*(d+sn)
        
        // Fore ====================================================================================
        UIGraphicsBeginImageContext(size)
        let c: CGContext = UIGraphicsGetCurrentContext()!
        
        if let back { back.draw(at: CGPoint(x: dx.truncatingRemainder(dividingBy: mod), y: dy.truncatingRemainder(dividingBy: mod))) }

        let ll: CGFloat = 10
        
        let noOfMaxtons: Int = Int(universe.pointee.maxtonCount)
        if noOfMaxtons > 0 {
            if tailsOn {
                let stride: Int = noOfMaxtons / iterations + (noOfMaxtons % iterations == 0 ? 0 : 1)
                let iterations: Int = noOfMaxtons / stride + (noOfMaxtons % stride == 0 ? 0 : 1)
                
                let semaphore = DispatchSemaphore(value: 0)
                
                DispatchQueue.global(qos: .userInitiated).async {
                    DispatchQueue.concurrentPerform(iterations: iterations, execute: { (i: Int) in
                        self.findEnds(from: i*stride, to: i == iterations-1 ? Int(self.universe.pointee.maxtonCount) : (i+1)*stride)
                    })
                    semaphore.signal()
                }
                
                semaphore.wait()
            }
            
            for i in 0..<Int(universe.pointee.maxtonCount) {
                let maxton: UnsafeMutablePointer<TCMaxton> = universe.pointee.maxtons![i]!
                let center: CGPoint = CGPoint(x: dx+maxton.pointee.p.x, y: dy+maxton.pointee.p.y)
                if !tailsOn {
                    let path: CGMutablePath = CGMutablePath(ellipseIn: CGRect(origin: center+CGPoint(x: -1.5, y: -1.5), size: CGSize(width: 3, height: 3)), transform: nil)
                    c.addPath(path)
                    c.setStrokeColor(UIColor.green.tone(0.7).tint(0.5).cgColor)
                    c.drawPath(using: .stroke)
                } else {
                    guard maxton.pointee.p.x != maxton.pointee.o.x || maxton.pointee.p.y != maxton.pointee.o.y else { continue }
                    
                    let path: CGMutablePath = CGMutablePath()
                    
                    let e: CGPoint = CGPoint(x: dx+maxton.pointee.e.x, y: dy+maxton.pointee.e.y)
                    let p: CGPoint = CGPoint(x: dx+maxton.pointee.p.x, y: dy+maxton.pointee.p.y)
                    path.move(to: e)
                    path.addLine(to: p)

                    path.addEllipse(in: CGRect(origin: center+CGPoint(x: -1.5, y: -1.5), size: CGSize(width: 3, height: 3)))
                    c.addPath(path)
                    c.setStrokeColor(UIColor.green.tone(0.7).tint(0.5).cgColor)
                    c.drawPath(using: .stroke)
                }
            }
        }

        for i in 0..<Int(universe.pointee.photonCount) {
            let photon: UnsafeMutablePointer<TCPhoton> = universe.pointee.photons![i]!
            let center: CGPoint = CGPoint(x: dx+photon.pointee.p.x, y: dy+photon.pointee.p.y)
            if !tailsOn {
                let path: CGMutablePath = CGMutablePath(ellipseIn: CGRect(origin: center+CGPoint(x: -1.5, y: -1.5), size: CGSize(width: 3, height: 3)), transform: nil)
                c.addPath(path)
                c.setStrokeColor(UIColor.red.tint(0.5).cgColor)
                c.drawPath(using: .stroke)
            } else {
                let path: CGMutablePath = CGMutablePath()
                
                let o: CGPoint = CGPoint(x: dx+photon.pointee.o.x, y: dy+photon.pointee.o.y)
                let p: CGPoint = CGPoint(x: dx+photon.pointee.p.x, y: dy+photon.pointee.p.y)
                path.move(to: p+(o-p).unit()*ll)
                path.addLine(to: p)

                path.addEllipse(in: CGRect(origin: center+CGPoint(x: -1.5, y: -1.5), size: CGSize(width: 3, height: 3)))
                c.addPath(path)
                c.setStrokeColor(UIColor.red.tint(0.5).cgColor)
                c.drawPath(using: .stroke)
            }
        }
        
        for i in 0..<Int(universe.pointee.teslonCount) {
            let r: CGFloat = 10
            let teslon: UnsafeMutablePointer<TCTeslon> = universe.pointee.teslons![i]!
            let center: CGPoint = CGPoint(x: dx+teslon.pointee.p.x, y: dy+teslon.pointee.p.y)
            let path: CGMutablePath = CGMutablePath(ellipseIn: CGRect(origin: center+CGPoint(x: -r, y: -r), size: CGSize(width: 2*r, height: 2*r)), transform: nil)
            c.addPath(path)
            c.setFillColor(UIColor.blue.tone(0.3).tint(0.7).alpha(0.5).cgColor)
            c.setStrokeColor(UIColor.blue.tone(0.3).tint(0.4).cgColor)
            c.drawPath(using: .fillStroke)
        }
        
        image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        renderMode = .rendered
    }
}
