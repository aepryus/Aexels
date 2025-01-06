//
//  Engine.swift
//  Aexels
//
//  Created by Joe Charlier on 12/13/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

import Acheron
import UIKit

class Engine {
    enum Background { case square, hex }
    var size: CGSize
    let background: Background

    var image: UIImage?
    weak var view: UIView?
    var back: UIImage?
    var n: Int = 1

    var renderMode: RenderMode = .started
    private var queue: DispatchQueue = DispatchQueue(label: "engine")
    
    init(size: CGSize, background: Background = .hex) {
        self.size = size
        self.background = background
    }

    func onTic() {}
    func onConfigure() {}
    func onRender(c: CGContext) {}
    
    func play() {
        Aexels.sync.onFire = { (link: CADisplayLink, complete: @escaping ()->()) in
            self.tic()
            self.n += 1
            complete()
        }
        Aexels.sync.link.preferredFramesPerSecond = 60
        Aexels.sync.start()
    }
    func stop() { Aexels.sync.stop() }
    
    func tic() {
        queue.sync {
            onTic()
            renderMode = .started
            renderImage()
            DispatchQueue.main.async { self.view?.setNeedsDisplay() }
        }
    }
    
    static func renderCartesian(size: CGSize) -> UIImage {
        let d: CGFloat = 12.0*Screen.s
        let sn: CGFloat = d*CGFloat(sin(Double.pi/6))
        let cs: CGFloat = d*CGFloat(cos(Double.pi/6))
        
        let w: CGFloat = size.width+100+2*(d+sn)
        let h: CGFloat = size.height+100+2*cs
        let n = Int(w/d)+1
        let m = Int(h/d)+1
        var x: CGFloat = 0
        var y: CGFloat = 0
        
        UIGraphicsBeginImageContext(size)
        let c = UIGraphicsGetCurrentContext()!
        
        let path = CGMutablePath()
        
        for _ in 0..<n {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: h))
            x += d
        }
        for _ in 0..<m {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: w, y: y))
            y += d
        }
        
        c.addPath(path)
        c.setStrokeColor(UIColor.white.shade(0.6).cgColor)
        c.drawPath(using: .stroke)
        
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return image
    }
    static func renderHex(size: CGSize) -> UIImage {
        let d: CGFloat = 10.0*Screen.s
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
        
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return image
    }
    
    func renderImage() {
        if back == nil {
            switch background {
                case .square:
                    back = Engine.renderCartesian(size: CGSize(width: size.width, height: size.height))
                case .hex:
                    back = Engine.renderHex(size: CGSize(width: size.width+100, height: size.height))
            }
        }
        
        UIGraphicsBeginImageContext(size)
        let c: CGContext = UIGraphicsGetCurrentContext()!
        
        onRender(c: c)
        
        image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        renderMode = .rendered
    }
}
