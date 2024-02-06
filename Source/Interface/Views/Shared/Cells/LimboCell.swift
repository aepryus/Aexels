//
//  LimboCell.swift
//  Aexels
//
//  Created by Joe Charlier on 2/4/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

//import Acheron
//import UIKit
//
//class LimboCell: Cyto.Cell {
//    var p: CGFloat = 15*Screen.s
//    var radius: CGFloat = 10*Screen.s
//
////    var cutouts: [Position:Cutout] = [:]
//    var closeOn: Bool = false
//    
//    var size: CGSize? = nil
//    var _content: UIView?
//    var content: UIView? {
//        set {
//            _content?.removeFromSuperview()
//            _content = newValue
//            guard let _content = _content else {return}
//            addSubview(_content)
//            layoutContent()
//        }
//        get {return _content}
//    }
//    func set(content: UIView, size: CGSize) {
//        _content?.removeFromSuperview()
//        _content = content
//        self.size = size
//        guard let _content = _content else {return}
//        addSubview(_content)
//        layoutContent()
//    }
//
//    var limboPath = LimboPath()
//    
//    override init(c: Int = 0, r: Int = 0, w: Int = 1, h: Int = 1) {
//        super.init(c: c, r: r, w: w, h: h)
//
//        backgroundColor = UIColor.clear
//        
//        layer.shadowColor = UIColor.black.cgColor
//        layer.shadowOffset = CGSize.zero
//        layer.shadowRadius = 3*Screen.s
//        layer.shadowOpacity = 0.6
//    }
//    convenience init(p: CGFloat) {
//        self.init()
//        self.p = p
//    }
//    convenience init(points: [(CGFloat, CGFloat)]) {
//        self.init()
//    }
//    required init?(coder aDecoder: NSCoder) {fatalError()}
//    
//    private func buildPath(p: CGFloat, q: CGFloat) -> CGPath {
//        let path = CGMutablePath()
//        
//        let x1 = p
//        let x3 = width - p
//        let x2 = (x1 + x3) / 2
//        let y1 = p
//        let y3 = height - p
//        let y2 = (y1 + y3) / 2
////        let cr: CGFloat = 50*s
//        
//        // The y1+radius is hack caused by the iPhone Cellular automata screen and the fact no topLeft cutouts currently exist
//        path.move(to: CGPoint(x: x1, y: y1+radius))
//
////        if let cutout = cutouts[.topLeft] {
////            let xe = x1 + cutout.width + q
////            let xc = (x1 + xe) / 2
////            let ye = y1 + cutout.height + q
////            let yc = (y1 + ye) / 2
////            path.addArc(tangent1End: CGPoint(x: x1, y: ye), tangent2End: CGPoint(x: xc, y: ye), radius: radius)
////            path.addArc(tangent1End: CGPoint(x: xe, y: ye), tangent2End: CGPoint(x: xe, y: yc), radius: radius)
////            path.addArc(tangent1End: CGPoint(x: xe, y: y1), tangent2End: CGPoint(x: x2, y: y1), radius: radius)
////        } else {
//            path.addArc(tangent1End: CGPoint(x: x1, y: y1), tangent2End: CGPoint(x: x2, y: y1), radius: radius)
////        }
//        
////        var skipNext: Bool = false
////        if let cutout = cutouts[.topRight] {
////            let xe = x3 - cutout.width - q
////            let xc = (xe + x3) / 2
////            let ye = y1 + cutout.height + q
////            let yc = (y1 + ye) / 2
////            path.addArc(tangent1End: CGPoint(x: xe, y: y1), tangent2End: CGPoint(x: xe, y: yc), radius: radius)
////            path.addArc(tangent1End: CGPoint(x: xe, y: ye), tangent2End: CGPoint(x: xc, y: ye), radius: radius)
////            path.addArc(tangent1End: CGPoint(x: x3, y: ye), tangent2End: CGPoint(x: x3, y: y2), radius: radius)
////        } else if closeOn {
////            path.addLine(to: CGPoint(x: x3-cr, y: y1))
////            if y1+cr < y3 {
////                path.addArc(center: CGPoint(x: x3, y: y1), radius: cr, startAngle: .pi, endAngle: .pi/2, clockwise: true)
////                path.addLine(to: CGPoint(x: x3, y: y2))
////            } else {
////                let theta: CGFloat = asin((y3-y1)/cr)
////                path.addArc(center: CGPoint(x: x3, y: y1), radius: cr, startAngle: .pi, endAngle: .pi-theta, clockwise: true)
////                skipNext = true
////            }
////        } else {
//            path.addArc(tangent1End: CGPoint(x: x3, y: y1), tangent2End: CGPoint(x: x3, y: y2), radius: radius)
////        }
//        
////        if !skipNext {
////            if let cutout = cutouts[.bottomRight] {
////                let xe = x3 - cutout.width - q
////                let xcL = (xe + x1) / 2
////                let xcR = (xe + x3) / 2
////                let ye = y3 - cutout.height - q
////                let yc = (ye + y3) / 2
////                path.addArc(tangent1End: CGPoint(x: x3, y: ye), tangent2End: CGPoint(x: xcR, y: ye), radius: radius)
////                path.addArc(tangent1End: CGPoint(x: xe, y: ye), tangent2End: CGPoint(x: xe, y: yc), radius: radius)
////                path.addArc(tangent1End: CGPoint(x: xe, y: y3), tangent2End: CGPoint(x: xcL, y: y3), radius: radius)
////            } else {
//                path.addArc(tangent1End: CGPoint(x: x3, y: y3), tangent2End: CGPoint(x: x2, y: y3), radius: radius)
////            }
////        }
//        
////        if let cutout = cutouts[.bottomLeft] {
////            let xe = x1 + cutout.width + q
////            let xc = (x1 + xe) / 2
////            let ye = y3 - cutout.height - q
////            let ycT = (ye + y1) / 2
////            let ycB = (ye + y3) / 2
////            path.addArc(tangent1End: CGPoint(x: xe, y: y3), tangent2End: CGPoint(x: xe, y: ycB), radius: radius)
////            path.addArc(tangent1End: CGPoint(x: xe, y: ye), tangent2End: CGPoint(x: xc, y: ye), radius: radius)
////            path.addArc(tangent1End: CGPoint(x: x1, y: ye), tangent2End: CGPoint(x: x1, y: ycT), radius: radius)
////        } else {
//            path.addArc(tangent1End: CGPoint(x: x1, y: y3), tangent2End: CGPoint(x: x1, y: y2), radius: radius)
////        }
//        
//        path.closeSubpath()
//        
//        return path
//    }
//    
//    func renderPaths() {
//        let a: CGFloat = 6*Screen.s
//        let b: CGFloat = 2*Screen.s
//
//        limboPath.strokePath = buildPath(p: a, q: 0)
//        limboPath.maskPath = buildPath(p: a, q: a-b)
//        limboPath.shadowPath = buildPath(p: b, q: 0)
//        
//        applyMask(limboPath.maskPath)
//        self.layer.shadowPath = limboPath.shadowPath
//        setNeedsDisplay()
//    }
//    
//    func applyMask(_ mask: CGPath) {}
//    
//    func layoutContent() {
//        if let size = size { _content?.center(size: size) }
//        else { _content?.center(size: CGSize(width: width-2*p, height: height-2*p)) }
//    }
//    
//// UIView ==========================================================================================
//    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
//        guard let path = limboPath.strokePath else {return super.hitTest(point, with: event)}
//        if path.contains(point) {return super.hitTest(point, with: event)}
//        else {return nil}
//    }
//    override var frame: CGRect {
//        didSet {
//            guard frame != CGRect.zero else {return}
//            
//            renderPaths()
//            layoutContent()
//        }
//    }
//    override func draw(_ rect: CGRect) {
//        let c = UIGraphicsGetCurrentContext()!
//
//        c.addPath(limboPath.strokePath)
//        c.setStrokeColor(UIColor(white: 0.3, alpha: 1).cgColor)
//        c.setLineWidth(1.5*s)
//        c.strokePath()
//    }
//}
