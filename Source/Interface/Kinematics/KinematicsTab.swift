//
//  KinematicsTab.swift
//  Aexels
//
//  Created by Joe Charlier on 2/14/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

import Acheron
import OoviumEngine
import UIKit

class KinematicsTab: TabsCellTab {
    unowned let explorer: KinematicsExplorer
    
    let zoneA: UIView = UIView()
    let zoneB: UIView = UIView()
    let zoneC: UIView = UIView()
    
    var universePicker: SliderView!
    let aetherVector = VectorView()
    let loopVector = VectorView()
    let netButton = NetButton()
    let swapper = Limbo()
    let close = LimboButton(title: "Close")
    let closeButton: CloseButton = CloseButton()
    let aetherLabel = UILabel()
    let loopLabel = UILabel()

    init(explorer: KinematicsExplorer) {
        self.explorer = explorer
        
        super.init(name: "Controls".localized)
        
        // Universe
        universePicker = SliderView { [unowned self] (page: String) in
            let cs: Double = 30*cos(Double.pi/6)
            
            if page == "Universe" {
                self.kinematicsView.stop()
                
                Aexels.sync.onFire = { (link: CADisplayLink, complete: @escaping ()->()) in
                    self.newtonianView.tic()
                    complete()
                }

                self.newtonianView.x.x = self.kinematicsView.Xl.x
                self.newtonianView.x.y = self.kinematicsView.Xl.y
                self.newtonianView.v.x = self.kinematicsView.Va.x + self.kinematicsView.Vl.x*2*cs
                self.newtonianView.v.y = -(self.kinematicsView.Va.y + self.kinematicsView.Vl.y*2*cs)
                self.loopVector.max = 10
                
                self.newtonianView.setNeedsDisplay()
                if self.explorer.timeControl.playButton.playing {
                    self.explorer.newtonianView.play()
                }
            } else {
                self.newtonianView.stop()
                
                Aexels.sync.onFire = { [unowned self] (link: CADisplayLink, complete: @escaping ()->()) in
                    self.kinematicsView.tic()
                    complete()
                }

                self.kinematicsView.moveTo(v: self.newtonianView.x)
                self.kinematicsView.Vl.x = (self.newtonianView.v.x - self.kinematicsView.Va.x)/(2*cs)
                self.kinematicsView.Vl.y = (-self.newtonianView.v.y - self.kinematicsView.Va.y)/(2*cs)
                self.loopVector.max = 10/(2*cs)
                
                self.kinematicsView.setNeedsDisplay()
                if self.explorer.timeControl.playButton.playing {
                    self.explorer.kinematicsView.play()
                }
            }
            UIView.animate(withDuration: 0.2, animations: {
                self.universeCell.content?.alpha = 0
                if page == "Universe X" {
                    self.aetherLabel.alpha = 1
                    self.aetherVector.alpha = 1
                    self.netButton.alpha = 1
                } else {
                    self.aetherLabel.alpha = 0
                    self.aetherVector.alpha = 0
                    self.netButton.alpha = 0
                }
            }, completion: { (finished: Bool) in
                if page == "Universe" {
                    self.universeCell.content = self.newtonianView
                } else {
                    self.universeCell.content = self.kinematicsView
                }
                self.universeCell.content?.alpha = 0
                UIView.animate(withDuration: 0.2, animations: {
                    self.universeCell.content?.alpha = 1
                })
            })
        }
        
        // Controls
        
        universePicker.pages = ["Universe", "Universe X"]
        universePicker.snapToPageNo(1)
        
        aetherVector.max = 5
        aetherVector.onTap = { [unowned self] (vector: V2) in
            self.kinematicsView.Va = vector
        }
        
        loopVector.max = 10/(2*30*cos(Double.pi/6))
        loopVector.onTap = { [unowned self] (vector: V2) in
            if self.universePicker.pageNo == 0 {
                self.newtonianView.v = V2(vector.x, -vector.y)
            } else {
                self.kinematicsView.Vl = vector
            }
        }
        
        let height = Screen.height - Screen.safeTop - Screen.safeBottom
        let s = (Screen.iPad || Screen.mac) ? height / 748 : Screen.s

        aetherLabel.text = "Aether"
        aetherLabel.font = UIFont.ax(size: 16*s)
        aetherLabel.textColor = UIColor.white
        aetherLabel.textAlignment = .center
        
        loopLabel.text = "Object"
        loopLabel.font = UIFont.ax(size: 16*s)
        loopLabel.textColor = UIColor.white
        loopLabel.textAlignment = .center
        
        netButton.addAction(for: .touchUpInside) { [unowned self] in
            self.kinematicsView.aetherVisible = !self.kinematicsView.aetherVisible
            self.netButton.on = self.kinematicsView.aetherVisible
            self.netButton.setNeedsDisplay()
        }
        
        zoneA.addSubview(netButton)
        
        zoneB.addSubview(universePicker)
        
        zoneC.addSubview(aetherVector)
        zoneC.addSubview(loopVector)
        zoneC.addSubview(aetherLabel)
        zoneC.addSubview(loopLabel)
                
        addSubview(zoneA)
        addSubview(zoneB)
        addSubview(zoneC)
    }
    
    var kinematicsView: KinematicsView { explorer.kinematicsView }
    var newtonianView: NewtonianView { explorer.newtonianView }
    var universeCell: LimboCell { explorer.universeCell }
    
// UIView ==========================================================================================
    override func layoutSubviews() {
        var dy: CGFloat = 30*s
        let zw: CGFloat = 160*s
        let zh: CGFloat = 100*s
//        let zp: CGFloat = 20*s
        
        zoneB.top(dy: dy, width: zw, height: zh)
        dy += 140*s

        zoneC.top(dy: dy, width: zw, height: zh)
        dy += 90*s

        zoneA.top(dy: dy, width: zw, height: zh)
        
        universePicker.center(size: CGSize(width: 120*s, height: 67*s))
        
        netButton.center(size: CGSize(width: 48*s, height: 48*s))

        aetherVector.center(dx: -36*s, dy: 10*s, size: CGSize(width: 63*s, height: 63*s))
        aetherLabel.center(dx: -36*s, dy: -32*s, size: CGSize(width: aetherVector.width, height: 16*s))
        loopVector.center(dx: 36*s, dy: 10*s, size: CGSize(width: 63*s, height: 63*s))
        loopLabel.center(dx: 36*s, dy: -32*s, size: CGSize(width: loopVector.width, height: 16*s))
    }
}
