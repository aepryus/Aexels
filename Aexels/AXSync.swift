//
//  AXSync.swift
//  Aexels
//
//  Created by Joe Charlier on 5/12/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import Foundation
import QuartzCore

class AXSync {
	var onFire: (CADisplayLink,@escaping ()->())->() = {(CADisplayLink,()->()) in}
	
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
		link.add(to: .main, forMode: .common)
	}
	func stop() {
		guard running else {return}
		running = false
		link.remove(from: .main, forMode: .common)
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
