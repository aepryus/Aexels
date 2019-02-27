//
//  CellularTimer.swift
//  Aexels
//
//  Created by Joe Charlier on 1/8/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import Foundation

final class AXTimer {
	let timer: DispatchSourceTimer = DispatchSource.makeTimerSource()			// CADisplayLink

	deinit {
		if !running {timer.resume()}
	}

	var interval: Double = 1.0/60 {
		didSet {timer.schedule(deadline: .now(), repeating: interval)}
	}

	var running: Bool = false
	private var semaphore = DispatchSemaphore(value: 1)
	
	func configure (interval: Double, _ block: @escaping()->()) {
		timer.setEventHandler {
			self.semaphore.wait()
			block()
			self.semaphore.signal()
		}
		self.interval = interval
	}
	
	func start() {
		guard !running else {return}
		running = true
		timer.resume()
	}
	func stop() {
		guard running else {return}
		running = false
		timer.suspend()
		semaphore.wait()
		semaphore.signal()
	}
}
