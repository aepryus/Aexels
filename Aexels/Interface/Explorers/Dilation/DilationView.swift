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
    private var universe: UnsafeMutablePointer<TCUniverse>
    private var source: UnsafeMutablePointer<TCTeslon>
    private var camera: UnsafeMutablePointer<TCCamera>
    
    private var queue: DispatchQueue = DispatchQueue(label: "dilationView")
    var renderMode: RenderMode = .started
    private var image: UIImage?
    private var back: UIImage?
    private var vw: Int = 0

    init() {
        let topY: CGFloat = Screen.safeTop + (Screen.mac ? 5*Screen.s : 0)
        let botY: CGFloat = Screen.safeBottom + (Screen.mac ? 5*Screen.s : 0)
        let height = Screen.height - topY - botY
        let s = height / 748
        
        let uw: CGFloat = height - 110*s - 46*s

        universe = TCUniverseCreate(uw, uw, 1, 0.5)
        
        source = TCUniverseCreateTeslon(universe, uw/2, uw/2, 0.5, .pi/2)
        TCUniverseCreateTeslon(universe, uw/2, uw/4, 0.5, .pi/2)
        TCUniversePulse(universe, source, 99)
        camera = TCUniverseCreateCamera(universe, uw/2, uw/2, 0.5, .pi/2)
        
        super.init(frame: CGRect.zero)
        backgroundColor = UIColor.clear
    }
    required init?(coder aDecoder: NSCoder) { fatalError() }
    deinit {
        TCUniverseRelease(universe)
    }
    
    func play() {
        Aexels.sync.link.preferredFramesPerSecond = 60
        Aexels.sync.start()
    }
    func stop() {
        Aexels.sync.stop()
    }
    private func reset(next: UnsafeMutablePointer<TCUniverse>) {
        TCUniverseRelease(universe)
        universe = next
        self.renderMode = .started
        self.renderImage()
        setNeedsDisplay()
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
        
        let d: CGFloat = 10.0*s
        let sn: CGFloat = d*CGFloat(sin(Double.pi/6))
        let mod: CGFloat = 2*(d+sn)

        
        UIGraphicsBeginImageContext(bounds.size)
        let c = UIGraphicsGetCurrentContext()!

//        if let image { image.draw(at: CGPoint.zero) }
        if let back { back.draw(at: CGPoint(x: dx.truncatingRemainder(dividingBy: mod), y: dy.truncatingRemainder(dividingBy: mod))) }

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
            var path = CGMutablePath(ellipseIn: CGRect(x: dx+maxton.pointee.p.x-r, y: dy+maxton.pointee.p.y-r, width: 2*r, height: 2*r), transform: nil)
            c.addPath(path)
            c.setStrokeColor(UIColor.green.tint(0.7).tone(0.5).cgColor)
//            c.setStrokeColor(UIColor.purple.tone(0.5).tint(0.5).cgColor)
            c.drawPath(using: .stroke)
            path = CGMutablePath()
            path.move(to: CGPoint(x: dx+maxton.pointee.p.x, y: dy+maxton.pointee.p.y))
            path.addLine(to: CGPoint(x: dx+maxton.pointee.p.x+5*sin(maxton.pointee.q), y: dy+maxton.pointee.p.y-5*cos(maxton.pointee.q)))
            c.addPath(path)
//            c.setStrokeColor(UIColor.green.tint(0.7).cgColor)
            c.drawPath(using: .stroke)
        }

//        c.setStrokeColor(OOColor.lavender.uiColor.cgColor)

//        for i in 0..<Int(universe.pointee.bondCount) {
//            let bond = universe.pointee.bonds[i]
//            guard bond.hot == 1 else {continue}
//            c.move(to: CGPoint(x: bond.a.pointee.s.x, y: bond.a.pointee.s.y))
//            c.addLine(to: CGPoint(x: bond.b.pointee.s.x, y: bond.b.pointee.s.y))
//        }
//        c.drawPath(using: .stroke)
        
//        let relaxed: Double = universe.pointee.relaxed;
        
        c.setLineWidth(0.5)
//        if universe.pointee.gol == 0 {
//            c.setStrokeColor(UIColor(rgb: 0xFFFFFF).cgColor)
//            c.setFillColor(UIColor(rgb: 0xEEEEEE).alpha(0.5).cgColor);
//
//            for i in 0..<Int(universe.pointee.aexelCount) {
//                let aexel = universe.pointee.aexels![i]!
//                guard aexel.pointee.stateC == 0 else { continue }
//                c.addEllipse(in: CGRect(x: aexel.pointee.s.x-relaxed/2, y: aexel.pointee.s.y-relaxed/2, width: relaxed, height: relaxed))
//            }
//            c.drawPath(using: .fillStroke)
//
//            let color1: UIColor = UIColor(rgb: 0x5CFF74).tint(0.2)
//            c.setStrokeColor(color1.shade(0.7).cgColor)
//            c.setFillColor(color1.cgColor);
//
//            for i in 0..<Int(universe.pointee.aexelCount) {
//                let aexel = universe.pointee.aexels![i]!
//                guard aexel.pointee.stateC == 1 else { continue }
//                c.addEllipse(in: CGRect(x: aexel.pointee.s.x-relaxed/2, y: aexel.pointee.s.y-relaxed/2, width: relaxed, height: relaxed))
//            }
//            c.drawPath(using: .fillStroke)
//
//
//        } else {
//            let color1: UIColor = UIColor(rgb: 0x5CFF74).tint(0.2)
//            c.setStrokeColor(color1.shade(0.7).cgColor)
//            c.setFillColor(color1.cgColor);
//
//            for i in 0..<Int(universe.pointee.aexelCount) {
//                let aexel = universe.pointee.aexels![i]!
//                guard aexel.pointee.stateA == 1 else { continue }
//                c.addEllipse(in: CGRect(x: aexel.pointee.s.x-relaxed/2, y: aexel.pointee.s.y-relaxed/2, width: relaxed, height: relaxed))
//            }
//            c.drawPath(using: .fillStroke)
//        }

//        c.setStrokeColor(UIColor.orange.tint(0.5).cgColor)
//        for i in 0..<universe.pointee.sectorWidth {
//            c.move(to: CGPoint(x: Double(i)*universe.pointee.snapped*2, y: 0))
//            c.addLine(to: CGPoint(x: Double(i)*universe.pointee.snapped*2, y: Double(height)))
//        }
//        for i in 0..<universe.pointee.sectorWidth {
//            c.move(to: CGPoint(x: 0, y: Double(i)*universe.pointee.snapped*2))
//            c.addLine(to: CGPoint(x: Double(height), y: Double(i)*universe.pointee.snapped*2))
//        }
//        c.drawPath(using: .stroke)

        // Momentum Vectors
//        c.setStrokeColor(UIColor.white.cgColor);
//        for i in 0..<Int(universe.pointee.photonCount) {
//            let photon = universe.pointee.photons![i]!
//            c.move(to: CGPoint(x: photon.pointee.aexel.pointee.s.x, y: photon.pointee.aexel.pointee.s.y))
//            c.addLine(to: CGPoint(x: photon.pointee.aexel.pointee.s.x+photon.pointee.v.x*7, y: photon.pointee.aexel.pointee.s.y+photon.pointee.v.y*7))
//        }

//        for i in 0..<Int(universe.pointee.hadronCount) {
//            let hadron = universe.pointee.hadrons![i]!
//            for quark in Mirror(reflecting: hadron.pointee.quarks).children.map({$0.value}) as! [Quark] {
//                c.move(to: CGPoint(x: quark.aexel.pointee.s.x, y: quark.aexel.pointee.s.y))
//                c.addLine(to: CGPoint(x: quark.aexel.pointee.s.x+quark.hadron.pointee.v.x*7*10/3, y: quark.aexel.pointee.s.y+quark.hadron.pointee.v.y*7*10/3))
//            }
//        }
//        c.drawPath(using: .stroke)

        // Particles
//        let radius: Double = 3
//        c.setFillColor(UIColor(rgb: 0x00FF00).cgColor);
//        for i in 0..<Int(universe.pointee.photonCount) {
//            let photon = universe.pointee.photons![i]!
//            c.addEllipse(in: CGRect(x: photon.pointee.aexel.pointee.s.x-radius, y: photon.pointee.aexel.pointee.s.y-radius, width: 2*radius, height: 2*radius))
//        }
//        c.drawPath(using: .fill)

//        for i in 0..<Int(universe.pointee.hadronCount) {
//            let hadron = universe.pointee.hadrons![i]!
//            c.setFillColor(UIColor(rgb: hadron.pointee.anti == 0 ? 0x0000FF : 0xFF0000).cgColor);
//            for quark in Mirror(reflecting: hadron.pointee.quarks).children.map({$0.value}) as! [Quark] {
//                c.addEllipse(in: CGRect(x: quark.aexel.pointee.s.x-radius, y: quark.aexel.pointee.s.y-radius, width: 2*radius, height: 2*radius))
//            }
//            c.drawPath(using: .fill)
////            if hadron.pointee.anti == 0 && hadron.pointee.center != nil {
////                c.setFillColor(UIColor(rgb: 0xFF00FF).tint(0.2).cgColor);
////                c.addEllipse(in: CGRect(x: hadron.pointee.center.pointee.s.x-radius, y: hadron.pointee.center.pointee.s.y-radius, width: 2*radius, height: 2*radius))
////                c.drawPath(using: .fill)
////            }
//        }
        
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
    
// UIView ==========================================================================================
    override func draw(_ rect: CGRect) {
        guard let image else { return }
        image.draw(at: CGPoint.zero)
        renderMode = .displayed
    }
}
