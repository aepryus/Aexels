//
//  CylinderView.swift
//  Aexels
//
//  Created by Joe Charlier on 3/4/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

import Acheron
import UIKit

class CylinderView: AEView {
    private var cylinders: [UnsafeMutablePointer<BCCylinder>] = []
    
    var sliceOn: Bool = false
    
    override init() {
        super.init()
        backgroundColor = .clear
        cylinders.append(BCCylinderCreate(2, 0, 16)!)
        cylinders.append(BCCylinderCreate(4, 2, 16)!)
        cylinders.append(BCCylinderCreate(6, 4, 16)!)
        cylinders.append(BCCylinderCreate(8, 6, 16)!)
        cylinders.append(BCCylinderCreate(10, 8, 16)!)
        cylinders.append(BCCylinderCreate(12, 10, 16)!)
        cylinders.append(BCCylinderCreate(14, 12, 16)!)

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap(_:))))
    }
    deinit { cylinders.forEach { BCCylinderRelease($0) } }
    
    func getColor(_ n: Int) -> UIColor {
        switch n {
            case 0: return .blue
            case 1: return .purple
            case 2: return .orange
            case 3: return .green
            case 4: return .yellow
            case 5: return .red
            case 6: return .cyan
            case 7: return .magenta
            default: return .white
        }
    }
    
    private func addTopEllipse(c: CGContext, in rect: CGRect) {
        let adj: CGFloat = 1.31
        c.move(to: CGPoint(x: rect.minX, y: rect.midY))
        c.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY),
            control1: CGPoint(x: rect.minX, y: rect.midY - rect.height/2 * adj),
            control2: CGPoint(x: rect.maxX, y: rect.midY - rect.height/2 * adj)
        )
    }
    private func addBottomEllipse(c: CGContext, in rect: CGRect) {
        let adj: CGFloat = 1.31
        c.move(to: CGPoint(x: rect.minX, y: rect.midY))
        c.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY),
            control1: CGPoint(x: rect.minX, y: rect.midY + rect.height/2 * adj),
            control2: CGPoint(x: rect.maxX, y: rect.midY + rect.height/2 * adj)
        )
    }
    
    func drainCylinders() {
        cylinders.forEach { BCCylinderDrain($0, 80) }
        setNeedsDisplay()
    }
    func resetCylinders() {
        cylinders.forEach { BCCylinderSetLiquidHeight($0, 16) }
        setNeedsDisplay()
    }
    
// Events ==========================================================================================
    @objc private func onTap(_ gesture: UITapGestureRecognizer) {
        drainCylinders()
    }
    
// UIView ==========================================================================================
    override func draw(_ rect: CGRect) {
        guard let c = UIGraphicsGetCurrentContext() else { return }
        
        let ovalRatio: CGFloat = 0.3
        let pointsToCM: CGFloat = 30
        let worldHeight: CGFloat = 16
        
        let x1: CGFloat = width/2
        let y1: CGFloat = height/2 + pointsToCM * worldHeight/2
        
        c.setLineWidth(2.0)
        
        var n: Int = 0
        for cylinder in cylinders.reversed() {
            
            let color: UIColor = getColor(cylinders.count-1-n)
            
            let ow: CGFloat = pointsToCM * cylinder.pointee.oR * 2
            let oh: CGFloat = pointsToCM * cylinder.pointee.oR * 2 * ovalRatio
            let iw: CGFloat = pointsToCM * cylinder.pointee.iR * 2
            let ih: CGFloat = pointsToCM * cylinder.pointee.iR * 2 * ovalRatio
            let ch: CGFloat = pointsToCM * cylinder.pointee.height
            let lh: CGFloat = pointsToCM * BCCylinderLiquidHeight(cylinder)
            
            addTopEllipse(c: c, in: CGRect(x: x1-ow/2, y: y1-oh/2, width: ow, height: oh))

            if iw != 0 {
                addTopEllipse(c: c, in: CGRect(x: x1-iw/2, y: y1-ih/2, width: iw, height: ih))
            }
            
            c.setStrokeColor(UIColor.black.cgColor)
            c.strokePath()
            
            c.move(to: CGPoint(x: x1-ow/2, y: y1))
            c.addLine(to: CGPoint(x: x1-ow/2, y: y1-lh))
            c.addLine(to: CGPoint(x: x1+ow/2, y: y1-lh))
            c.addLine(to: CGPoint(x: x1+ow/2, y: y1))
            c.addLine(to: CGPoint(x: x1-ow/2, y: y1))

            if iw != 0 {
                addTopEllipse(c: c, in: CGRect(x: x1-iw/2, y: y1-ih/2-lh, width: iw, height: ih))
                addTopEllipse(c: c, in: CGRect(x: x1-iw/2, y: y1-ih/2, width: iw, height: ih))
            }

            c.setFillColor(color.alpha(0.5).cgColor)
            c.drawPath(using: .eoFill)
            
            addTopEllipse(c: c, in: CGRect(x: x1-ow/2, y: y1-oh/2-lh, width: ow, height: oh))
            addTopEllipse(c: c, in: CGRect(x: x1-iw/2, y: y1-ih/2-lh, width: iw, height: ih))

            c.setFillColor(color.tint(0.3).cgColor)
            c.setStrokeColor(color.shade(0.2).cgColor)
            c.drawPath(using: .eoFill)
            
            addTopEllipse(c: c, in: CGRect(x: x1-ow/2, y: y1-oh/2-ch, width: ow, height: oh))
            addTopEllipse(c: c, in: CGRect(x: x1-ow/2, y: y1-oh/2-lh, width: ow, height: oh))
            c.move(to: CGPoint(x: x1-ow/2, y: y1-ch))
            c.addLine(to: CGPoint(x: x1-ow/2, y: y1))
            c.move(to: CGPoint(x: x1+ow/2, y: y1-ch))
            c.addLine(to: CGPoint(x: x1+ow/2, y: y1))

            if iw != 0 {
                addTopEllipse(c: c, in: CGRect(x: x1-iw/2, y: y1-ih/2-ch, width: iw, height: ih))
                addTopEllipse(c: c, in: CGRect(x: x1-iw/2, y: y1-ih/2-lh, width: iw, height: ih))
                c.move(to: CGPoint(x: x1-iw/2, y: y1-ch))
                c.addLine(to: CGPoint(x: x1-iw/2, y: y1))
                c.move(to: CGPoint(x: x1+iw/2, y: y1-ch))
                c.addLine(to: CGPoint(x: x1+iw/2, y: y1))
            }
            
            if sliceOn {
                c.move(to: CGPoint(x: x1-iw/2, y: y1-ch))
                c.addLine(to: CGPoint(x: x1-ow/2, y: y1-ch))
                c.move(to: CGPoint(x: x1+iw/2, y: y1-ch))
                c.addLine(to: CGPoint(x: x1+ow/2, y: y1-ch))
                
                c.move(to: CGPoint(x: x1-iw/2, y: y1))
                c.addLine(to: CGPoint(x: x1-ow/2, y: y1))
                c.move(to: CGPoint(x: x1+iw/2, y: y1))
                c.addLine(to: CGPoint(x: x1+ow/2, y: y1))

                c.move(to: CGPoint(x: x1-iw/2, y: y1-lh))
                c.addLine(to: CGPoint(x: x1-ow/2, y: y1-lh))
                c.move(to: CGPoint(x: x1+iw/2, y: y1-lh))
                c.addLine(to: CGPoint(x: x1+ow/2, y: y1-lh))

            }
            
            c.setStrokeColor(UIColor.black.cgColor)
            c.strokePath()
                        
            n += 1
        }
        
        guard !sliceOn else { return }
        
        n = 0
        for cylinder in cylinders {
            
            let color: UIColor = getColor(n)
            
            let ow: CGFloat = pointsToCM * cylinder.pointee.oR * 2
            let oh: CGFloat = pointsToCM * cylinder.pointee.oR * 2 * ovalRatio
            let iw: CGFloat = pointsToCM * cylinder.pointee.iR * 2
            let ih: CGFloat = pointsToCM * cylinder.pointee.iR * 2 * ovalRatio
            let ch: CGFloat = pointsToCM * cylinder.pointee.height
            let lh: CGFloat = pointsToCM * BCCylinderLiquidHeight(cylinder)
            
            if iw != 0 {
                addBottomEllipse(c: c, in: CGRect(x: x1-iw/2, y: y1-ih/2, width: iw, height: ih))
            }
            
            c.setStrokeColor(UIColor.black.cgColor)
            c.strokePath()
                        
            c.setStrokeColor(UIColor.black.cgColor)
            c.strokePath()
            
            addBottomEllipse(c: c, in: CGRect(x: x1-ow/2, y: y1-oh/2, width: ow, height: oh))
            
            c.move(to: CGPoint(x: x1-iw/2, y: y1))
            c.addLine(to: CGPoint(x: x1-iw/2, y: y1-lh))
            c.addLine(to: CGPoint(x: x1+iw/2, y: y1-lh))
            c.addLine(to: CGPoint(x: x1+iw/2, y: y1))
            c.addLine(to: CGPoint(x: x1-iw/2, y: y1))

            if iw != 0 {
                addBottomEllipse(c: c, in: CGRect(x: x1-iw/2, y: y1-ih/2-lh, width: iw, height: ih))
            }

            c.setFillColor(color.alpha(0.5).cgColor)
            c.drawPath(using: .eoFill)
            
            addBottomEllipse(c: c, in: CGRect(x: x1-ow/2, y: y1-oh/2-lh, width: ow, height: oh))
            addBottomEllipse(c: c, in: CGRect(x: x1-iw/2, y: y1-ih/2-lh, width: iw, height: ih))

            c.setFillColor(color.tint(0.3).cgColor)
            c.setStrokeColor(color.shade(0.2).cgColor)
            c.drawPath(using: .eoFill)
            
            addBottomEllipse(c: c, in: CGRect(x: x1-ow/2, y: y1-oh/2-ch, width: ow, height: oh))
            addBottomEllipse(c: c, in: CGRect(x: x1-ow/2, y: y1-oh/2-lh, width: ow, height: oh))
            addBottomEllipse(c: c, in: CGRect(x: x1-ow/2, y: y1-oh/2, width: ow, height: oh))

            if iw != 0 {
                addBottomEllipse(c: c, in: CGRect(x: x1-iw/2, y: y1-ih/2-ch, width: iw, height: ih))
                addBottomEllipse(c: c, in: CGRect(x: x1-iw/2, y: y1-ih/2-lh, width: iw, height: ih))
            }
            
            c.setStrokeColor(UIColor.black.cgColor)
            c.strokePath()
                        
            n += 1
        }
    }
}
