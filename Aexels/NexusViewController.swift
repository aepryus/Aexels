//
//  NexusViewController.swift
//  Aexels
//
//  Created by Joe Charlier on 1/2/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import OoviumLib
import UIKit

class NexusViewController: UIViewController {
	let imageView = UIImageView(image: Aexels.backImage())
	var nexusLabel: NexusLabel!
	
	var messageView: MessageView!
	let exploreButton = LimboView()

	var nexusButtons: [NexusButton] = []
	var explorers: [Explorer]!
	var explorer: Explorer?

	var busy = false
	private func display (explorer: Explorer) {
		if explorer.canExplore {
			if Aexels.iPad() {
				messageView.cutouts[AEPoint.bottomRight] = Cutout(width: 176, height: 110)
			} else {
				messageView.cutouts[AEPoint.bottomRight] = Cutout(width: 160, height: 60)
			}
		} else {
			messageView.cutouts.removeAll()
		}
		messageView.renderPaths()
		
		messageView.load(key: explorer.key)
		UIView.animate(withDuration: 0.2, animations: {
			self.messageView.alpha = 1
			if explorer.canExplore {self.exploreButton.alpha = 1}
			else {self.exploreButton.alpha = 0}
		}, completion: { (Bool) in
			self.busy = false
		})
	}
	private func wantsToDisplay (explorer: Explorer) {
		objc_sync_enter(self)
		defer {objc_sync_exit(self)}
		if busy {return}
		busy = true
		
		self.explorer = explorer
		
		if !Aexels.iPad() && !isDimmed() {dimNexus()}
		
		if self.messageView.alpha != 0 {
			if explorer.key == messageView.key {
				busy = false
				return
			}
			UIView.animate(withDuration: 0.2, animations: { 
				self.messageView.alpha = 0
				self.exploreButton.alpha = 0
			}, completion: { (Bool) in
				self.display(explorer: explorer)
			})
		} else {
			self.display(explorer: explorer)
		}
	}
	
	private func buildCutoutPath (x: [CGFloat], y: [CGFloat], radius: CGFloat) -> CGPath {
		let path = CGMutablePath()
		
		path.move(to: CGPoint(x: x[0], y: y[1]))
		path.addArc(tangent1End: CGPoint(x: x[0], y: y[0]), tangent2End: CGPoint(x: x[1], y: y[0]), radius: radius)
		path.addArc(tangent1End: CGPoint(x: x[2], y: y[0]), tangent2End: CGPoint(x: x[2], y: y[1]), radius: radius)
		path.addArc(tangent1End: CGPoint(x: x[2], y: y[3]), tangent2End: CGPoint(x: x[4], y: y[3]), radius: radius)
		path.addArc(tangent1End: CGPoint(x: x[3], y: y[3]), tangent2End: CGPoint(x: x[3], y: y[4]), radius: radius)
		path.addArc(tangent1End: CGPoint(x: x[3], y: y[2]), tangent2End: CGPoint(x: x[1], y: y[2]), radius: radius)
		path.addArc(tangent1End: CGPoint(x: x[0], y: y[2]), tangent2End: CGPoint(x: x[0], y: y[1]), radius: radius)
		path.closeSubpath()
		
		return path
	}
	
	func isDimmed () -> Bool {
		return self.nexusLabel.alpha == 0.1
	}
	func dimNexus () {
		UIView.animate(withDuration: 0.2) {
			self.nexusLabel.alpha = 0.1
			self.messageView.alpha = 0
			self.exploreButton.alpha = 0
			for button in self.nexusButtons {
				button.alpha = 0
			}
		}
	}
	func brightenNexus () {
		UIView.animate(withDuration: 0.2) {
			self.nexusLabel.alpha = 1
			for button in self.nexusButtons {
				button.alpha = 1
			}
		}
	}
	
	func iPadLayout () {
		// Title
		nexusLabel = NexusLabel(text: "Aexels", size:72)
		nexusLabel.frame = CGRect(x: 52, y: 52, width: 300, height: 96)
		view.addSubview(nexusLabel)

		// Menu
		var i: CGFloat = 0
		for explorer in explorers {
			let button = NexusButton(text: explorer.name)
			button.frame = CGRect(x: 50, y: 170+i*70, width: 300, height: 40)
			button.add(for: .touchUpInside, { 
				self.wantsToDisplay(explorer: explorer)
			})
			view.addSubview(button)
			nexusButtons.append(button)
			i += 1
		}

		// Message
		let w: CGFloat = 1024-340-52
		messageView = MessageView(frame: CGRect(x: 1024-w-5, y: 20, width: w, height: 768-20))
		messageView.alpha = 0
		messageView.onTap = { ()->() in
			UIView.animate(withDuration: 0.2) {
				self.messageView.alpha = 0
				self.exploreButton.alpha = 0
			}
		}
		view.addSubview(messageView)
		
//		let rect = messageView.bounds
		
//		// Cutout
//		var p: CGFloat = 6
//		var x1: CGFloat = p
//		var x3: CGFloat = x1 + rect.size.width-2*p
//		var x2: CGFloat = (x1+x3)/2
//		var x4: CGFloat = x3 - 176
//		var x5: CGFloat = (x3+x4)/2
//		var y1: CGFloat = p
//		var y3: CGFloat = y1 + rect.size.height-2*p
//		var y2: CGFloat = (y1+y3)/2
//		var y4: CGFloat = y3 - 110
//		var y5: CGFloat = (y3+y4)/2
//		cutoutPath.strokePath = buildCutoutPath(x: [x1,x2,x3,x4,x5], y: [y1,y2,y3,y4,y5], radius: 10)
//		
//		p = 2
//		x1 = p
//		x3 = x1 + rect.size.width-2*p
//		x2 = (x1+x3)/2
//		x4 = x3 - 176
//		x5 = (x3+x4)/2
//		y1 = p
//		y3 = y1 + rect.size.height-2*p
//		y2 = (y1+y3)/2
//		y4 = y3 - 110
//		y5 = (y3+y4)/2
//		cutoutPath.shadowPath = buildCutoutPath(x: [x1,x2,x3,x4,x5], y: [y1,y2,y3,y4,y5], radius: 10)
//		
//		p = 6
//		x1 = p
//		x3 = x1 + rect.size.width-2*p
//		x2 = (x1+x3)/2
//		x4 = x3 - 176 - 4
//		x5 = (x3+x4)/2
//		y1 = p
//		y3 = y1 + rect.size.height-2*p
//		y2 = (y1+y3)/2
//		y4 = y3 - 110 - 4
//		y5 = (y3+y4)/2
//		cutoutPath.maskPath = buildCutoutPath(x: [x1,x2,x3,x4,x5], y: [y1,y2,y3,y4,y5], radius: 10)
		
		exploreButton.alpha = 0
		exploreButton.frame = CGRect(x: 843, y: 658, width: 176, height: 110)
		view.addSubview(exploreButton)
		
		let button = UIButton(type: .custom)
		button.setTitle("Explore", for: .normal)
		button.titleLabel!.font = UIFont.aexelFont(size: 24)
		button.frame = CGRect(x: 15, y: 17, width: 146, height: 80)
		button.add(for: .touchUpInside) { 
			self.dimNexus()
			self.explorer!.openExplorer(view: self.view)
		}
		
		exploreButton.addSubview(button)
		
	}
	func iPhoneLayout () {
		// Title
		nexusLabel = NexusLabel(text: "Aexels", size:60)
		nexusLabel.frame = CGRect(x: 30, y: 52, width: 240, height: 64)
		view.addSubview(nexusLabel)

		// Menu
		var i: CGFloat = 0
		for explorer in explorers {
			let button = NexusButton(text: explorer.name)
			button.frame = CGRect(x: 36, y: 170+i*60, width: 300, height: 32)
			button.add(for: .touchUpInside, { 
				self.wantsToDisplay(explorer: explorer)
			})
			view.addSubview(button)
			nexusButtons.append(button)
			i += 1
		}

		// Message
		messageView = MessageView(frame: CGRect(x: 5, y: 5+20, width: 375-10, height: 667-10-20))
		messageView.alpha = 0
		messageView.onTap = { ()->() in
			UIView.animate(withDuration: 0.2, animations: { 
				self.messageView.alpha = 0
				self.exploreButton.alpha = 0
			})
			self.brightenNexus()
		}
		view.addSubview(messageView)
		
//		// Cutout
//		let w: CGFloat = 160
//		let h: CGFloat = 60
//		
//		let rect = messageView.bounds
//		var p: CGFloat = 6
//		var x1: CGFloat = p
//		var x3: CGFloat = x1 + rect.size.width-2*p
//		var x2: CGFloat = (x1+x3)/2
//		var x4: CGFloat = x3 - w
//		var x5: CGFloat = (x3+x4)/2
//		var y1: CGFloat = p
//		var y3: CGFloat = y1 + rect.size.height-2*p
//		var y2: CGFloat = (y1+y3)/2
//		var y4: CGFloat = y3 - h
//		var y5: CGFloat = (y3+y4)/2
//		cutoutPath.strokePath = buildCutoutPath(x: [x1,x2,x3,x4,x5], y: [y1,y2,y3,y4,y5], radius: 10)
//		
//		p = 2
//		x1 = p
//		x3 = x1 + rect.size.width-2*p
//		x2 = (x1+x3)/2
//		x4 = x3 - w
//		x5 = (x3+x4)/2
//		y1 = p
//		y3 = y1 + rect.size.height-2*p
//		y2 = (y1+y3)/2
//		y4 = y3 - h
//		y5 = (y3+y4)/2
//		cutoutPath.shadowPath = buildCutoutPath(x: [x1,x2,x3,x4,x5], y: [y1,y2,y3,y4,y5], radius: 10)
//		
//		p = 6
//		x1 = p
//		x3 = x1 + rect.size.width-2*p
//		x2 = (x1+x3)/2
//		x4 = x3 - w - 4
//		x5 = (x3+x4)/2
//		y1 = p
//		y3 = y1 + rect.size.height-2*p
//		y2 = (y1+y3)/2
//		y4 = y3 - h - 4
//		y5 = (y3+y4)/2
//		cutoutPath.maskPath = buildCutoutPath(x: [x1,x2,x3,x4,x5], y: [y1,y2,y3,y4,y5], radius: 10)
		
		// Explore
		exploreButton.alpha = 0
		exploreButton.frame = CGRect(x: 375-160-5, y: 677-60-2*6-4, width: 160, height: 60)
		view.addSubview(exploreButton)

		let button = UIButton(type: .custom)
		button.setTitle("Explore", for: .normal)
		button.titleLabel!.font = UIFont.aexelFont(size: 24)
		button.frame = CGRect(x: 15, y: 17, width: 160-30, height: 60-30)
		button.add(for: .touchUpInside) { 
			self.dimNexus()
			self.explorer!.openExplorer(view: self.view)
		}
		exploreButton.addSubview(button)
	}
	
// UIViewController ================================================================================
	override func viewDidLoad() {
        super.viewDidLoad()

		imageView.frame = view.frame
		view.addSubview(imageView)
		
		explorers = [
			IntroExplorer(view: view),
			CellularExplorer(view: view),
			KinematicsExplorer(view: view),
			GravityExplorer(view: view),
			DilationExplorer(view: view),
			ContractionExplorer(view: view),
			DarknessExplorer(view: view)
		]

		if Aexels.iPad() {
			iPadLayout()
		} else {
			iPhoneLayout()
		}

//		let rect = messageView.bounds
//		normalPath.strokePath = CGPath(roundedRect: rect.insetBy(dx: 6, dy: 6), cornerWidth: 10, cornerHeight: 10, transform: nil)
//		normalPath.shadowPath = CGPath(roundedRect: rect.insetBy(dx: 2, dy: 2), cornerWidth: 10, cornerHeight: 10, transform: nil)
//		normalPath.maskPath = normalPath.strokePath
	}
}
