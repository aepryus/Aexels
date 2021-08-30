//
//  NexusViewController.swift
//  Aexels
//
//  Created by Joe Charlier on 1/2/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import Acheron
import OoviumLib
import UIKit

class NexusViewController: UIViewController {
	let imageView = UIImageView(image: Aexels.backImage())
	var nexusLabel: NexusLabel!
	var versionLabel: NexusLabel!
	
	var messageView: MessageLimbo!
	let exploreButton = LimboButton(title: "Explore")

	var nexusButtons: [NexusButton] = []
	var explorers: [Explorer]!
	var explorer: Explorer?

	var busy = false
	private func display(explorer: Explorer) {
		if explorer.canExplore {
			if Screen.iPad {
				let height = Screen.height - Screen.safeTop - Screen.safeBottom
				let s = height / 748
				messageView.cutouts[Position.bottomRight] = Cutout(width: 176*s, height: 110*s)
			} else {
				messageView.cutouts[Position.bottomRight] = Cutout(width: 160*s, height: 60*s)
			}
		} else {
			messageView.cutouts.removeAll()
		}
		messageView.renderPaths()
		
		messageView.key = explorer.key
		messageView.load()
		UIView.animate(withDuration: 0.2, animations: {
			self.messageView.alpha = 1
			if explorer.canExplore {self.exploreButton.alpha = 1}
			else {self.exploreButton.alpha = 0}
		}, completion: { (Bool) in
			self.busy = false
		})
	}
	private func wantsToDisplay(explorer: Explorer) {
		objc_sync_enter(self)
		defer {objc_sync_exit(self)}
		if busy {return}
		busy = true
		
		self.explorer = explorer
		
		if !Screen.iPad && !isDimmed() {dimNexus()}
		
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
	
	private func buildCutoutPath(x: [CGFloat], y: [CGFloat], radius: CGFloat) -> CGPath {
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
	
	func isDimmed() -> Bool {
		return self.nexusLabel.alpha == 0.1
	}
	func dimNexus() {
		UIView.animate(withDuration: 0.2) {
			self.nexusLabel.alpha = 0.1
			self.messageView.alpha = 0
			self.exploreButton.alpha = 0
			for button in self.nexusButtons {
				button.alpha = 0
			}
		}
	}
	func brightenNexus() {
		UIView.animate(withDuration: 0.2) {
			self.nexusLabel.alpha = 1
			for button in self.nexusButtons {
				button.alpha = 1
			}
		}
	}
	
	func iPadLayout() {
		let height = Screen.height - Screen.safeTop - Screen.safeBottom
		let s = height / 748

		// Title
		nexusLabel = NexusLabel(text: "Aexels", size:72*s)
		nexusLabel.frame = CGRect(x: 52*s, y: 52*s, width: 300*s, height: 96*s)
		view.addSubview(nexusLabel)
		nexusLabel.addGestureRecognizer(TouchingGesture(target: self, action: #selector(onTouch)))
		
		// Version
		versionLabel = NexusLabel(text: "v\(Aexels.version)", size:20*s)
		versionLabel.frame = CGRect(x: 52*s, y: 114*s, width: 300*s, height: 24*s)
		versionLabel.alpha = 0
		view.addSubview(versionLabel)

		// Menu
		var i: CGFloat = 0
		for explorer in explorers {
			let button = NexusButton(text: explorer.name)
			button.frame = CGRect(x: 50*s, y: 162*s+i*64*s, width: 300*s, height: 40*s)
			button.addAction(for: .touchUpInside, {
				self.wantsToDisplay(explorer: explorer)
			})
			view.addSubview(button)
			nexusButtons.append(button)
			i += 1
		}

		// Message
		let w: CGFloat = Screen.width-(340+52)*s
		messageView = MessageLimbo()
		messageView.frame = CGRect(x: Screen.width-w-5*s, y: safeTop, width: w, height: Screen.height-safeTop-safeBottom)
		messageView.alpha = 0
		messageView.onTap = {()->() in
			UIView.animate(withDuration: 0.2) {
				self.messageView.alpha = 0
				self.exploreButton.alpha = 0
			}
		}
		view.addSubview(messageView)
		
		exploreButton.alpha = 0
		exploreButton.topLeft(dx: Screen.width-5*s-176*s, dy: Screen.height-safeBottom-110*s, width: 176*s, height: 110*s)
		view.addSubview(exploreButton)
		exploreButton.addAction(for: .touchUpInside) {
			self.dimNexus()
			self.explorer!.openExplorer(view: self.view)
		}
	}
	func iPhoneLayout() {
		// Title
		nexusLabel = NexusLabel(text: "Aexels", size:60*s)
		nexusLabel.frame = CGRect(x: 16*s, y: 52*s, width: 300*s, height: 64*s)
		view.addSubview(nexusLabel)
		nexusLabel.addGestureRecognizer(TouchingGesture(target: self, action: #selector(onTouch)))

		// Version
		versionLabel = NexusLabel(text: "v\(Aexels.version)", size:18*s)
		versionLabel.frame = CGRect(x: 16*s, y: 105*s, width: 300*s, height: 26*s)
		versionLabel.alpha = 0
		view.addSubview(versionLabel)
		
		// Menu
		var i: CGFloat = 0
		for explorer in explorers {
			let button = NexusButton(text: explorer.name)
			button.frame = CGRect(x: 16*s, y: 164*s+i*52*s, width: 300*s, height: 32*s)
			button.addAction(for: .touchUpInside, {
				self.wantsToDisplay(explorer: explorer)
			})
			view.addSubview(button)
			nexusButtons.append(button)
			i += 1
		}

		// Message
		messageView = MessageLimbo()
		messageView.frame = CGRect(x: 5*s, y: (5+20)*s, width: (375-10)*s, height: (667-10-20)*s)
		messageView.alpha = 0
		messageView.onTap = {()->() in
			UIView.animate(withDuration: 0.2, animations: { 
				self.messageView.alpha = 0
				self.exploreButton.alpha = 0
			})
			self.brightenNexus()
		}
		view.addSubview(messageView)
		
		// Explore
		exploreButton.alpha = 0
		exploreButton.frame = CGRect(x: (375-160-5)*s, y: (677-60-2*6-4)*s, width: 160*s, height: 60*s)
		exploreButton.addAction(for: .touchUpInside) {
			self.dimNexus()
			self.explorer!.openExplorer(view: self.view)
		}
		view.addSubview(exploreButton)
	}
	func iPhoneXLayout() {
		// Title
		nexusLabel = NexusLabel(text: "Aexels", size:60*s)
		nexusLabel.frame = CGRect(x: 16*s, y: 102*s, width: 300*s, height: 64*s)
		view.addSubview(nexusLabel)
		nexusLabel.addGestureRecognizer(TouchingGesture(target: self, action: #selector(onTouch)))
		
		// Version
		versionLabel = NexusLabel(text: "v\(Aexels.version)", size:18*s)
		versionLabel.frame = CGRect(x: 16*s, y: 155*s, width: 300*s, height: 26*s)
		versionLabel.alpha = 0
		view.addSubview(versionLabel)
		
		// Menu
		var i: CGFloat = 0
		for explorer in explorers {
			let button = NexusButton(text: explorer.name)
			button.frame = CGRect(x: 16*s, y: 224*s+i*58*s, width: 300*s, height: 32*s)
			button.addAction(for: .touchUpInside, {
				self.wantsToDisplay(explorer: explorer)
			})
			view.addSubview(button)
			nexusButtons.append(button)
			i += 1
		}
		
		// Message
		messageView = MessageLimbo()
		messageView.frame = CGRect(x: 5*s, y: Screen.safeTop, width: Screen.width-10*s, height: Screen.height-Screen.safeTop-Screen.safeBottom)
		messageView.alpha = 0
		messageView.onTap = {()->() in
			UIView.animate(withDuration: 0.2, animations: {
				self.messageView.alpha = 0
				self.exploreButton.alpha = 0
			})
			self.brightenNexus()
		}
		view.addSubview(messageView)
		
		// Explore
		exploreButton.alpha = 0
		exploreButton.frame = CGRect(x: messageView.right-160*s, y: messageView.bottom-60*s, width: 160*s, height: 60*s)
		exploreButton.addAction(for: .touchUpInside) {
			self.dimNexus()
			self.explorer!.openExplorer(view: self.view)
		}
		view.addSubview(exploreButton)
	}
	
// Events ==========================================================================================
	@objc func onTouch(gesture: TouchingGesture) {
		if gesture.state == .began {
			UIView.animate(withDuration: 0.2) {
				self.versionLabel.alpha = 1
			}
		} else if gesture.state == .ended {
			UIView.animate(withDuration: 0.2) {
				self.versionLabel.alpha = 0
			}
		}
	}
	
// UIViewController ================================================================================
	override var prefersHomeIndicatorAutoHidden: Bool {
		return true
	}
	override func viewDidLoad() {
        super.viewDidLoad()

		imageView.frame = view.frame
		view.addSubview(imageView)
		
		explorers = [
			IntroExplorer(parent: view),
			CellularExplorer(parent: view),
			KinematicsExplorer(parent: view),
			GravityExplorer(parent: view),
			DilationExplorer(parent: view),
			ContractionExplorer(parent: view),
			DarknessExplorer(parent: view),
			EquivalenceExplorer(parent: view),
			OddsAndEndsExplorer(parent: view)
		]

		if Screen.iPad {
			iPadLayout()
		} else if Screen.dimensions == .dim375x812 || Screen.dimensions == .dim414x896 {
			iPhoneXLayout()
		} else {
			iPhoneLayout()
		}
	}
}
