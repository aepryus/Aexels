//
//  GravityEngine.swift
//  Aexels
//
//  Created by Joe Charlier on 9/5/23.
//  Copyright © 2023 Aepryus Software. All rights reserved.
//

import Acheron
import UIKit

class GravityEngine {
    var universe: UnsafeMutablePointer<MYUniverse>

    private var queue: DispatchQueue = DispatchQueue(label: "aexelsView")
    
    lazy var view: GravityView = GravityView(engine: self)
    
    init(size: CGSize) {
        universe = MYUniverseCreate(size.width, size.height, 18, 3)
        MYUniverseCreateSlice(universe, 0, 100, 0)
    }
    deinit { MYUniverseRelease(universe) }

    func tic() {
        queue.sync {
            MYUniverseTic(self.universe)
            renderMode = .started
            renderImage()
            DispatchQueue.main.async { self.view.setNeedsDisplay() }
        }
    }

    var n: Int = 1
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
    
    // Render Image ====================================================================================
    
    private var s: CGFloat { Screen.s }
    var renderMode: RenderMode = .started
    
    var image: UIImage?
    private var back: UIImage?
    private var fore: UIImage?
    
    func renderImage() {
        guard renderMode == .started else { return }
        renderMode = .rendering
        
        let size: CGSize = CGSize(width: universe.pointee.width, height: universe.pointee.height)
        
        // Fore ====================================================================================
        UIGraphicsBeginImageContext(size)
        let c: CGContext = UIGraphicsGetCurrentContext()!
        
//        c.addPath(CGPath(rect: CGRect(origin: .zero, size: size), transform: nil))
//        c.setStrokeColor(UIColor.green.tone(0.3).tint(0.4).cgColor)
//        c.setLineWidth(3)
//        c.drawPath(using: .stroke)
//
        c.setLineWidth(0.5)
        for i in 0..<Int(universe.pointee.sliceCount) {
            let slice: UnsafeMutablePointer<MYSlice> = universe.pointee.slices![i]!
            guard slice.pointee.destroyed == 0 else { continue }
            let path: CGMutablePath = CGMutablePath()
            let qx: Double = slice.pointee.evenOdd == 0 ? 0 : universe.pointee.dx/2
            for j in 0...Int(universe.pointee.width/universe.pointee.dx) {
                path.addEllipse(in: CGRect(origin: CGPoint(x: Double(j)*universe.pointee.dx+qx, y: slice.pointee.y), size: CGSize(width: 5, height: 5)))
            }
            c.addPath(path)
//            c.setFillColor(UIColor.gray.tone(0.3).tint(0.7).alpha(0.5).cgColor)
            c.setStrokeColor(UIColor.gray.tone(0.3).tint(0.4).cgColor)
            c.drawPath(using: .stroke)
        }

        image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        renderMode = .rendered
    }
}
