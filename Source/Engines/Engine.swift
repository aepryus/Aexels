//
//  Engine.swift
//  Aexels
//
//  Created by Joe Charlier on 12/13/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

import UIKit

class Engine {
    var size: CGSize

    var image: UIImage?
    weak var view: UIView?
    var back: UIImage?
    var n: Int = 1

    var renderMode: RenderMode = .started
    private var queue: DispatchQueue = DispatchQueue(label: "engine")
    
    init(size: CGSize) {
        self.size = size
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
    
    func renderImage() {
        if back == nil { back = DilationEngine.renderBack(size: CGSize(width: size.width+100, height: size.height)) }
        
        UIGraphicsBeginImageContext(size)
        let c: CGContext = UIGraphicsGetCurrentContext()!
        
        onRender(c: c)
        
        image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        renderMode = .rendered
    }
}
