//
//  KinematicsExplorer.swift
//  Aexels
//
//  Created by Joe Charlier on 1/5/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import Acheron
import OoviumEngine
import OoviumKit
import UIKit

class KinematicsExplorer: Explorer {
//	let message: MessageLimbo = MessageLimbo()
	
    let zoneA: UIView = UIView()
	let zoneB: UIView = UIView()
	let zoneC: UIView = UIView()
	let zoneD: UIView = UIView()
	
	let newtonianView: NewtownianView = NewtownianView()
	let kinematicsView: KinematicsView = KinematicsView()
    lazy var universeCell: LimboCell = LimboCell(content: kinematicsView, c: 0, r: 0, w: 4)
	
	var universePicker: SliderView!
	let playButton: PlayButton = PlayButton()
	let aetherVector = VectorView()
	let loopVector = VectorView()
	let netButton = NetButton()
	let expAButton = ExpButton(name: "Exp\nA")
	let expBButton = ExpButton(name: "Exp\nB")
	let swapper = Limbo()
	let swapButton = SwapButton()
    let close = LimboButton(title: "Close")
    let closeButton: CloseButton = CloseButton()
	let aetherLabel = UILabel()
	let loopLabel = UILabel()

	var isFirst: Bool = false
    
    let articleScroll: UIScrollView = UIScrollView()
    let articleView: ArticleView = ArticleView()
    let cyto: Cyto = Cyto(rows: 2, cols: 5)

	init() { super.init(name: "Kinematics", key: "kinematics") }

// UIVIewController ================================================================================
    override func viewDidLoad() {
        super.viewDidLoad()
        
        kinematicsView.onTic = { [unowned self] (velocity: V2) in
            self.loopVector.vector = velocity
        }
        newtonianView.onTic = { [unowned self] (velocity: V2) in
            self.loopVector.vector = velocity
        }
        
        articleView.font = UIFont(name: "Verdana", size: 18*s)!
        articleView.color = .white
        articleView.scrollView = articleScroll
        articleView.key = "kinematicsLab"
        articleScroll.addSubview(articleView)
        
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
                if self.playButton.playing {
                    self.newtonianView.play()
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
                if self.playButton.playing {
                    self.kinematicsView.play()
                }
            }
            UIView.animate(withDuration: 0.2, animations: {
                self.universeCell.content?.alpha = 0
                if page == "Universe X" {
                    self.aetherLabel.alpha = 1
                    self.aetherVector.alpha = 1
                    self.netButton.alpha = 1
                    self.expAButton.alpha = 1
                    self.expBButton.alpha = 1
                } else {
                    self.aetherLabel.alpha = 0
                    self.aetherVector.alpha = 0
                    self.netButton.alpha = 0
                    self.expAButton.alpha = 0
                    self.expBButton.alpha = 0
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
//        universe.content = kinematicsView
        
        // Controls
        
        universePicker.pages = ["Universe", "Universe X"]
        universePicker.snapToPageNo(1)
        
        playButton.onPlay = { [unowned self] in
            self.kinematicsView.play()
        }
        playButton.onStop = { [unowned self] in
            self.kinematicsView.stop()
        }
        
        aetherVector.max = 5
        aetherVector.onTap = { [unowned self] (vector: V2) in
            self.kinematicsView.Va = vector
            self.expAButton.activated = false
            self.expBButton.activated = false
        }
        
        loopVector.max = 10/(2*30*cos(Double.pi/6))
        loopVector.onTap = { [unowned self] (vector: V2) in
            if self.universePicker.pageNo == 0 {
                self.newtonianView.v = V2(vector.x, -vector.y)
            } else {
                self.kinematicsView.Vl = vector
            }
            self.expAButton.activated = false
            self.expBButton.activated = false
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
        
        expAButton.activated = true
        expAButton.addAction(for: .touchUpInside) {[unowned self] in
            let q = 0.3
            let sn = sin(Double.pi/6)
            let cs = cos(Double.pi/6)
            
            self.kinematicsView.Xa = V2(0, 0)
            self.kinematicsView.Va = V2(0.5, -1.5)
            self.kinematicsView.Vl = V2(-cs*q/2, -sn*q/4)
            
            self.kinematicsView.x = 3
            self.kinematicsView.y = 3
            self.kinematicsView.o = 1

            self.aetherVector.vector = self.kinematicsView.Va
            self.loopVector.vector = self.kinematicsView.Vl
            
            self.expAButton.activated = true
            self.expBButton.activated = false
        }
        
        expBButton.addAction(for: .touchUpInside) {[unowned self] in
            self.kinematicsView.Xa = V2(0, 0)
            self.kinematicsView.Va = V2(0, -1)
            self.kinematicsView.Vl = V2(0, 0)
            
            if Screen.iPhone {
                self.kinematicsView.x = 1
                self.kinematicsView.y = 0
                self.kinematicsView.o = 1
            } else {
                self.kinematicsView.x = 3
                self.kinematicsView.y = 0
                self.kinematicsView.o = 0
            }
            
            self.aetherVector.vector = self.kinematicsView.Va
            self.loopVector.vector = self.kinematicsView.Vl
            
            self.expAButton.activated = false
            self.expBButton.activated = true
        }

        netButton.addAction(for: .touchUpInside) { [unowned self] in
            self.kinematicsView.aetherVisible = !self.kinematicsView.aetherVisible
            self.netButton.on = self.kinematicsView.aetherVisible
            self.netButton.setNeedsDisplay()
        }
        
        // Message
//        message.key = "KinematicsLab"
        
        // Swapper =========================
        if Screen.iPhone {
            swapButton.addAction(for: .touchUpInside) { [unowned self] in
                self.swapButton.rotateView()
                if self.isFirst {
                    self.isFirst = false
//                    self.dimLimbos(self.first)
//                    self.brightenLimbos(self.second)
//                    self.limbos = [self.swapper] + self.second + [self.close]
                } else {
                    self.isFirst = true
//                    self.dimLimbos(self.second)
//                    self.brightenLimbos(self.first)
//                    self.limbos = [self.swapper] + self.first + [self.close]
                }
                self.swapper.removeFromSuperview()
                self.view.addSubview(self.swapper)
                self.close.removeFromSuperview()
                self.view.addSubview(self.close)
            }
            swapper.content = swapButton
        }
        
        zoneA.addSubview(playButton)
        zoneA.addSubview(netButton)
        
        zoneB.addSubview(universePicker)
        
        zoneC.addSubview(aetherVector)
        zoneC.addSubview(loopVector)
        zoneC.addSubview(aetherLabel)
        zoneC.addSubview(loopLabel)
        
        zoneD.addSubview(expAButton)
        zoneD.addSubview(expBButton)


        cyto.cells = [
            universeCell,
            MaskCell(content: articleScroll, c: 4, r: 0, h: 2, cutout: true),
            LimboCell(content: zoneB, c: 0, r: 1),
            LimboCell(content: zoneA, c: 1, r: 1),
            LimboCell(content: zoneC, c: 2, r: 1),
            LimboCell(content: zoneD, c: 3, r: 1)
        ]
        cyto.layout()
        view.addSubview(cyto)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if universePicker.pageNo == 0 {
            Aexels.sync.onFire = { (link: CADisplayLink, complete: @escaping ()->()) in
                self.newtonianView.tic()
                complete()
            }
        } else {
            Aexels.sync.onFire = { (link: CADisplayLink, complete: @escaping ()->()) in
                self.kinematicsView.tic()
                complete()
            }
        }
        Aexels.sync.link.preferredFramesPerSecond = 60
        playButton.play()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        playButton.stop()
    }
    
// AEViewController ================================================================================
    override func layout1024x768() {
        let topY: CGFloat = Screen.safeTop + (Screen.mac ? 5*s : 0)
        let botY: CGFloat = Screen.safeBottom + (Screen.mac ? 5*s : 0)
        let height = Screen.height - topY - botY
        let s = height / 748
        
//        let p: CGFloat = 5*s
        let uw: CGFloat = height - 110*s

//        message.closeOn = true
//        message.renderPaths()
//        message.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 70*s, right: 0)

//        closeButton.topLeft(dx: message.right-50*s, dy: message.top, width: 50*s, height: 50*s)

        universePicker.center(size: CGSize(width: 120*s, height: 67*s))
        
        playButton.center(dx: -35*s, size: CGSize(width: 50*s, height: 30*s))
        netButton.center(dx: 27*s, size: CGSize(width: 48*s, height: 48*s))

        aetherVector.left(dx: 6*s, dy: 10*s, size: CGSize(width: 63*s, height: 63*s))
        aetherLabel.left(dx: aetherVector.left, dy: -32*s, size: CGSize(width: aetherVector.width, height: 16*s))
        loopVector.left(dx: aetherVector.right+12, dy: 10*s, size: CGSize(width: 63*s, height: 63*s))
        loopLabel.left(dx: loopVector.left, dy: -32*s, size: CGSize(width: loopVector.width, height: 16*s))

        expAButton.center(dx: -26*s, size: CGSize(width: 40*s, height: 50*s))
        expBButton.center(dx: 26*s, size: CGSize(width: 40*s, height: 50*s))

        cyto.Xs = [160*s, 150*s, 180*s, uw-490*s]
        cyto.Ys = [uw]
        cyto.frame = CGRect(x: 5*s, y: topY, width: view.width-10*s, height: view.height-topY-botY)
        cyto.layout()
        
        articleView.load()
        articleScroll.contentSize = articleView.scrollViewContentSize
        articleView.frame = CGRect(x: 10*s, y: 0, width: articleScroll.width-20*s, height: articleScroll.height)
    }

    
    
    
    
    
    
    
    
    
    
// =================================================================================================
// =================================================================================================
// =================================================================================================
// =================================================================================================
// =================================================================================================

	
	
// Events ==========================================================================================
//	override func onOpen() {
//		if universePicker.pageNo == 0 {
//			Aexels.sync.onFire = { (link: CADisplayLink, complete: @escaping ()->()) in
//				self.newtonianView.tic()
//				complete()
//			}
//		} else {
//			Aexels.sync.onFire = { (link: CADisplayLink, complete: @escaping ()->()) in
//				self.kinematicsView.tic()
//				complete()
//			}
//		}
//		Aexels.sync.link.preferredFramesPerSecond = 60
//	}
//	override func onOpened() {
//		playButton.play()
//	}
//	override func onClose() {
//		playButton.stop()
//		if Screen.iPhone {
//			swapButton.resetView()
////			limbos = first + [swapper, close]
//		}
//	}

// Explorer ========================================================================================
	override func layout375x667() {
		let size = UIScreen.main.bounds.size
		
		let h = size.height - 110*s - 20*s
//		let w = size.width - 10*s
		let ch = size.height - 20*s - h - 15*2*s + 1*s
		let vw: CGFloat = 72*s



//		zoneA.cutouts[.bottomRight] = Cutout(width: zoneA.width-60*s+5*s, height: zoneB.height-60*s+5*s)
//		zoneA.renderPaths()
//		
//		zoneB.renderPaths()
//
//		zoneC.renderPaths()
//		
//		zoneD.cutouts[.bottomLeft] = Cutout(width: zoneD.width-139*s, height: zoneB.height-60*s)
//		zoneD.renderPaths()
		
		playButton.top(dy: 32*s, size: CGSize(width: 48*s, height: 30*s))
		netButton.top(dy: playButton.bottom+20*s, size: CGSize(width: 48*s, height: 48*s))

		let dx: CGFloat = 32*s
		loopVector.topRight(dx: -dx, dy: 32*s, size: CGSize(width: vw, height: vw))
		aetherVector.topLeft(dx: dx, dy: 32*s, size: CGSize(width: vw, height: vw))
		loopLabel.topLeft(dx: loopVector.left, dy: loopVector.top-20*s, size: CGSize(width: vw, height: 16*s))
		aetherLabel.topLeft(dx: aetherVector.left, dy: aetherVector.top-20*s, size: CGSize(width: vw, height: 16*s))
		
		expAButton.left(dx: 108*s, size: CGSize(width: 40*s, height: 50*s))
		expBButton.left(dx: expAButton.right+10*s, size: CGSize(width: 40*s, height: 50*s))

		universePicker.center(size: CGSize(width: 120*s, height: ch-12*s))

		swapper.frame = CGRect(x: 5*s, y: (667-56-5)*s, width: 56*s, height: 56*s)

//		message.frame = CGRect(x: 5*s, y: 20*s, width: w, height: size.height-20*s-5*s)
//		message.cutouts[Position.bottomRight] = Cutout(width: 139*s, height: 60*s)
//		message.cutouts[Position.bottomLeft] = Cutout(width: 56*s, height: 56*s)
//		message.renderPaths()

//		close.topLeft(dx: message.right-139*s, dy: message.bottom-60*s, width: 139*s, height: 60*s)
	}
	override func layout375x812() {
		let size = UIScreen.main.bounds.size
		
		let h = size.height - 110*s - 20*s
//		let w = size.width - 10*s
		let ch = size.height - 20*s - h - 15*2*s + 1*s
		let vw: CGFloat = 72*s
//		let sh: CGFloat = 56*s
		
		
//		zoneA.cutouts[.bottomRight] = Cutout(width: zoneA.width-60*s+5*s, height: zoneB.height-60*s+5*s)
//		zoneA.renderPaths()
//		
//		zoneB.renderPaths()
//		
//		zoneC.renderPaths()
//		
//		zoneD.cutouts[.bottomLeft] = Cutout(width: zoneD.width-139*s, height: zoneB.height-60*s)
//		zoneD.renderPaths()
		
		playButton.top(dy: 32*s, size: CGSize(width: 48*s, height: 30*s))
		netButton.top(dy: playButton.bottom+20*s, size: CGSize(width: 48*s, height: 48*s))
		
		let dx: CGFloat = 32*s
		loopVector.topRight(dx: -dx, dy: 32*s, size: CGSize(width: vw, height: vw))
		aetherVector.topLeft(dx: dx, dy: 32*s, size: CGSize(width: vw, height: vw))
		loopLabel.topLeft(dx: loopVector.left, dy: loopVector.top-20*s, size: CGSize(width: vw, height: 16*s))
		aetherLabel.topLeft(dx: aetherVector.left, dy: aetherVector.top-20*s, size: CGSize(width: vw, height: 16*s))
		
		expAButton.left(dx: 108*s, size: CGSize(width: 40*s, height: 50*s))
		expBButton.left(dx: expAButton.right+10*s, size: CGSize(width: 40*s, height: 50*s))
		
		universePicker.center(size: CGSize(width: 120*s, height: ch-12*s))
		
//		message.frame = CGRect(x: 5*s, y: Screen.safeTop, width: w, height: Screen.height-Screen.safeTop-Screen.safeBottom)
//		message.cutouts[Position.bottomRight] = Cutout(width: 139*s, height: 60*s)
//		message.cutouts[Position.bottomLeft] = Cutout(width: 56*s, height: 56*s)
//		message.renderPaths()
		
//		swapper.topLeft(dx: 5*s, dy: message.bottom-56*s, width: 56*s, height: 56*s)
//        close.topLeft(dx: message.right-139*s, dy: message.bottom-60*s, width: 139*s, height: 60*s)
	}
}
