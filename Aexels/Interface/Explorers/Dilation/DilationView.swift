//
//  DilationView.swift
//  Aexels
//
//  Created by Joe Charlier on 12/3/22.
//  Copyright © 2022 Aepryus Software. All rights reserved.
//

import Acheron
import UIKit

class DilationView: UIView {
    var universe: UnsafeMutablePointer<TCUniverse>
    private var source: UnsafeMutablePointer<TCTeslon>
    private var targetN: UnsafeMutablePointer<TCTeslon>
    private var targetE: UnsafeMutablePointer<TCTeslon>?
    private var camera: UnsafeMutablePointer<TCCamera>
    
    private var queue: DispatchQueue = DispatchQueue(label: "dilationView")
    var renderMode: RenderMode = .started
    private var image: UIImage?
    private var back: UIImage?
    private var fore: UIImage?
    private var vw: Int = 0
    
    var trailsOn: Bool = false
    var autoOn: Bool = false
    var chaseCameraOn: Bool = false

    init(chaseCameraOn: Bool = false) {
        self.chaseCameraOn = chaseCameraOn
        universe = TCUniverseCreate(10, 10, 0, 1)
        source = TCUniverseCreateTeslon(universe, 5, 5, 0.5, .pi/2)
        targetN = TCUniverseCreateTeslon(universe, 5, 5, 0.5, .pi/2)
        camera = TCUniverseCreateCamera(universe, 5, 5, 0.5, .pi/2)
        super.init(frame: CGRect.zero)
        backgroundColor = UIColor.clear
        reset()
    }
    required init?(coder aDecoder: NSCoder) { fatalError() }
    deinit {
        TCUniverseRelease(universe)
    }
    
    var speedOfLight: Double = 1 {
        didSet {
            universe.pointee.c = speedOfLight
        }
    }
    var velocity: Double = 1 {
        didSet {
            let v: TCVelocity = TCVelocity(s: abs(velocity), q: velocity > 0 ? Double.pi/2 : Double.pi*3/2)
            source.pointee.v = v
            targetN.pointee.v = v
            camera.pointee.v = v
        }
    }

    func play() {
        Aexels.sync.link.preferredFramesPerSecond = 60
        Aexels.sync.start()
    }
    func stop() {
        Aexels.sync.stop()
    }
    func reset() {
        fore = nil
        TCUniverseRelease(universe)
        TCTeslonRelease(source)
        TCTeslonRelease(targetN)
        TCCameraRelease(camera)

        let topY: CGFloat = Screen.safeTop + (Screen.mac ? 5*Screen.s : 0)
        let botY: CGFloat = Screen.safeBottom + (Screen.mac ? 5*Screen.s : 0)
        let height = Screen.height - topY - botY
        let s = height / 748
        let uw: CGFloat = height - 110*s - 46*s
        let v: Double = 0.5

        universe = TCUniverseCreate(uw, uw, 1, v)
        
        source = TCUniverseCreateTeslon(universe, uw/2, uw/2, v, .pi/2)
        targetN = TCUniverseCreateTeslon(universe, uw/2, uw/4, v, .pi/2)
        camera = TCUniverseCreateCamera(universe, uw/2, uw/2, v, .pi/2)
        TCUniversePulse(universe, source, 99)
    }
    
    func extractUniverse(from: DilationView) {
        self.universe = from.universe
        self.source = from.source
        self.targetN = from.targetN
        
        let topY: CGFloat = Screen.safeTop + (Screen.mac ? 5*Screen.s : 0)
        let botY: CGFloat = Screen.safeBottom + (Screen.mac ? 5*Screen.s : 0)
        let height = Screen.height - topY - botY
        let s = height / 748
        let uw: CGFloat = height - 110*s - 46*s

        self.camera = TCUniverseCreateCamera(universe, 0, uw/2, 0, .pi/2)
    }
    
    func renderBack() {
        let d: CGFloat = 10.0*s
        let sn: CGFloat = d*CGFloat(sin(Double.pi/6))
        let cs: CGFloat = d*CGFloat(cos(Double.pi/6))
        
        let w: CGFloat = width+100+2*(d+sn)
        let h: CGFloat = height+100+2*cs
        let n = (Int(w/(2*(d+sn))))+1
        let m = (Int(h/(2*cs)))+1
        var x: CGFloat = 1
        var y: CGFloat = 1

        UIGraphicsBeginImageContext(CGSize(width: bounds.size.width+100, height: bounds.size.height+100))
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
        guard renderMode == .started else {return}
        renderMode = .rendering
        
        if back == nil { renderBack() }
        
        
        
        let dx: CGFloat = width/2 - camera.pointee.p.x
        let dy: CGFloat = height/2 - camera.pointee.p.y
        
        if chaseCameraOn {
            let tolerance = width/2+10
            if source.pointee.v.q == .pi/2 {
                if source.pointee.p.x - camera.pointee.p.x > tolerance {
                    camera.pointee.p.x += tolerance*2
                }
            } else {
                if camera.pointee.p.x - source.pointee.p.x > tolerance {
                    camera.pointee.p.x -= tolerance*2
                }
            }
        }
        
        let d: CGFloat = 10.0*s
        let sn: CGFloat = d*CGFloat(sin(Double.pi/6))
        let mod: CGFloat = 2*(d+sn)
        
        // Fore ====================================================================================
        UIGraphicsBeginImageContext(bounds.size)
        var c = UIGraphicsGetCurrentContext()!

        if trailsOn, let fore { fore.draw(at: CGPoint.zero, blendMode: .normal, alpha: 0.9) }

        for i in 0..<Int(universe.pointee.teslonCount) {
            let teslon = universe.pointee.teslons![i]!
            let r: Double = 10
            let path = CGPath(ellipseIn: CGRect(x: dx+teslon.pointee.p.x-r, y: dy+teslon.pointee.p.y-r, width: 2*r, height: 2*r), transform: nil)
            c.addPath(path)
            c.setFillColor(UIColor.blue.tone(0.3).tint(0.7).cgColor)
            c.setStrokeColor(UIColor.blue.tone(0.3).tint(0.4).cgColor)
            c.drawPath(using: .fillStroke)
        }
        
        for i in 0..<Int(universe.pointee.maxtonCount) {
            let maxton = universe.pointee.maxtons![i]!
            let r: Double = 1
            let path = CGMutablePath(ellipseIn: CGRect(x: dx+maxton.pointee.p.x-r, y: dy+maxton.pointee.p.y-r, width: 2*r, height: 2*r), transform: nil)
            c.addPath(path)
            c.setStrokeColor(UIColor.green.tint(0.7).tone(0.5).cgColor)
            c.drawPath(using: .stroke)
        }
        
        for i in 0..<Int(universe.pointee.photonCount) {
            let photon = universe.pointee.photons![i]!
            let r: Double = 1
            let path = CGMutablePath(ellipseIn: CGRect(x: dx+photon.pointee.p.x-r, y: dy+photon.pointee.p.y-r, width: 2*r, height: 2*r), transform: nil)
            c.addPath(path)
            c.setStrokeColor(UIColor.red.tint(0.5).cgColor)
            c.drawPath(using: .stroke)
        }

        fore = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        // Image ==================================================================================
        
        UIGraphicsBeginImageContext(bounds.size)
        c = UIGraphicsGetCurrentContext()!

        if let back { back.draw(at: CGPoint(x: dx.truncatingRemainder(dividingBy: mod), y: dy.truncatingRemainder(dividingBy: mod))) }
        if let fore { fore.draw(at: CGPoint.zero) }
        self.image = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        renderMode = .rendered
    }
    
    func pulse() {
        TCUniversePulse(universe, source, 99)
    }
    
// Sample Frame Rate ===============================================================================
    private var last: Date = Date()
    private var step: Int = 1
    var onMeasure: ((Double)->())? = { (sps: Double)  in
        print("SPS: \(sps)")
    }
    func sampleFrameRate() {
        if self.step % 60 == 0 {
            let now = Date()
            let x = now.timeIntervalSince(self.last)
            if let onMeasure = self.onMeasure {
                onMeasure(60.0/x)
            }
            self.last = now
        }
        self.step += 1
    }
    
    func tic() {
        queue.sync {
            TCUniverseTic(self.universe)
            self.renderMode = .started
            self.renderImage()
//            self.sampleFrameRate()
            DispatchQueue.main.async {
                self.setNeedsDisplay()
            }
        }
    }
    func slaveTic() {
        queue.sync {
            self.renderMode = .started
            self.renderImage()
//            self.sampleFrameRate()
            DispatchQueue.main.async {
                self.setNeedsDisplay()
            }
        }
    }
    
// UIView ==========================================================================================
    override func draw(_ rect: CGRect) {
        guard let image else { return }
        image.draw(at: CGPoint.zero)
        renderMode = .displayed
    }
}
