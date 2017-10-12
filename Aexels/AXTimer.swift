//
//  CellularTimer.swift
//  Aexels
//
//  Created by Joe Charlier on 1/8/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import Foundation

final class AXTimer {
	var block: (()->())!
	var running: Bool = false
	var semaphore = DispatchSemaphore(value: 1)
	
	private var _interval: Double = 0.1
	var interval: Double {
		set {
			_interval = newValue
			timer.schedule(deadline: .now(), repeating: interval)
		}
		get {return _interval}
	}
	
	let queue: DispatchQueue = DispatchQueue(label: "cellular")
	let timer: DispatchSourceTimer = DispatchSource.makeTimerSource()			// CADisplayLink
	
	func configure (interval: Double, _ block: @escaping()->()) {
		timer.setEventHandler {
			self.semaphore.wait()
			block()
			self.semaphore.signal()
		}
		self.interval = interval
		self.block = block
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
	func isRunning() -> Bool {
		return running
	}
}
