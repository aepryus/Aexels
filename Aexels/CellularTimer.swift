//
//  CellularTimer.swift
//  Aexels
//
//  Created by Joe Charlier on 1/8/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import Foundation

final class CellularTimer {
	var block: (()->())!
	var interval: Double!
	
	let queue: DispatchQueue = DispatchQueue(label: "cellular")
	let timer: DispatchSourceTimer = DispatchSource.makeTimerSource()
	
	func configure (interval: Double, _ block: @escaping ()->()) {
		self.interval = interval
		self.block = block
		
		timer.scheduleRepeating(deadline: .now(), interval: interval)
		timer.setEventHandler {
			block()
		}
	}
	
	func start () {
		timer.resume()
	}
	func stop () {
		timer.suspend()
	}
}
