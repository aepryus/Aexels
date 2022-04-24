//
//  AXSync.swift
//  Aexels
//
//  Created by Joe Charlier on 5/12/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import Acheron
import Foundation
import QuartzCore

class AXSync {
	var onFire: (CADisplayLink,@escaping ()->())->() = {(link: CADisplayLink,complete: ()->()) in}
	
	lazy var link: CADisplayLink = {
		let link = CADisplayLink(target: self, selector: #selector(fire))
		link.preferredFramesPerSecond = 60
		return link
	}()
	
	deinit {
		link.invalidate()
	}
	
	var running: Bool = false
	private var semaphore = DispatchSemaphore(value: 1)

	func start() {
		guard !running else {return}
		running = true
		link.add(to: .main, forMode: Screen.iPad ? .common : .default)
	}
	func stop() {
		guard running else {return}
		running = false
		link.remove(from: .main, forMode: Screen.iPad ? .common : .default)
		semaphore.wait()
		semaphore.signal()
	}

	@objc private func fire(link: CADisplayLink) {
		self.semaphore.wait()
		onFire(link) {
			self.semaphore.signal()
		}
	}
}
