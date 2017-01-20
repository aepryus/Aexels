//
//  CellularEngine.swift
//  Aexels
//
//  Created by Joe Charlier on 1/7/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import Foundation
import OoviumLib

final class CellularEngine {
//	let aether: Aether
	let auto: Auto
	
	let w: Int
	let h: Int
	var cells: [Obj]
	var next: [Obj]
	var xfer: [Obj]!
	
	var memory: Memory
	let index: Int
	let web: Web
	
	let selfI: Int
	let aI: Int
	let bI: Int
	let cI: Int
	let dI: Int
	let eI: Int
	let fI: Int
	let gI: Int
	let hI: Int
	
	private var views = [CellularView]()
	private var timer: CellularTimer
	
	init? (aetherName: String, w: Int, h: Int) {
		var json: String
		do {
			json = try String(contentsOfFile: Bundle.main.path(forResource: aetherName, ofType: "oo")!)
		} catch {
			print("\(error)")
			return nil
		}
	
		let attributes = JSON.fromJSON(json: json)
		let basket = Basket()
		let aether: Aether = basket.inject(attributes: attributes) as! Aether
		aether.wire()
		aether.calculate()
		memory = aether.memory
		index = memory.index(for: "ATN00001")
		auto = aether.autos.first!
		auto.foreshadow(&memory)
		web = Web(head: auto.headTower, tail: auto.resultTower, memory: &memory)
		
		self.w = w
		self.h = h
		cells = [Obj](repeating: RealObj.zero, count: w*h)
		next = [Obj](repeating: RealObj.zero, count: w*h)
		
		selfI = memory.index(for: "Auto1.Self")
		aI = memory.index(for: "Auto1.A")
		bI = memory.index(for: "Auto1.B")
		cI = memory.index(for: "Auto1.C")
		dI = memory.index(for: "Auto1.D")
		eI = memory.index(for: "Auto1.E")
		fI = memory.index(for: "Auto1.F")
		gI = memory.index(for: "Auto1.G")
		hI = memory.index(for: "Auto1.H")
		
		timer = CellularTimer()
		timer.configure(interval: 1.0/60.0, { 
			self.tic()
		})
		
		populate(auto: auto)
	}
	
	func addView (_ view: CellularView) {
		views.append(view)
		view.engine = self
		view.configure(auto: auto)
	}
	
	private func populate (auto: Auto) {
		for i in 0..<w {
			for j in 0..<h {
				cells[i+j*w] = RealObj(Double(arc4random_uniform(UInt32(auto.states.count))))
			}
		}
	}

	private func loadMemory (_ i: Int, x: Int, y: Int) {
		if x < 0 || x >= w || y < 0 || y >= h {
			memory.mimic(i, obj: RealObj.zero)
		} else {
			memory.mimic(i, obj: cells[x + y*w])
		}
	}
	
	var last: Date = Date()
	var s: Int = 1
	
	func tic () {
		let start = Date()
		
		for j in 0..<h {
			for i in 0..<w {
				memory.clear()
				
				loadMemory(selfI, x: i, y: j)
				loadMemory(aI, x: i-1, y: j-1)
				loadMemory(bI, x: i  , y: j-1)
				loadMemory(cI, x: i+1, y: j-1)
				loadMemory(dI, x: i+1, y: j  )
				loadMemory(eI, x: i+1, y: j+1)
				loadMemory(fI, x: i  , y: j+1)
				loadMemory(gI, x: i-1, y: j+1)
				loadMemory(hI, x: i-1, y: j  )
				
				web.execute(&memory)
				
				next[i + j*w] = memory[index]!
//				next[i + j*w] = Int((memory[index]! as! RealObj).x)
			}
		}
		
		
		xfer = cells
		cells = next
		next = xfer
		
		for view in views {
			view.tic()
		}
		
		let x = Date().timeIntervalSince(start)
		print("\(x)")

		if s % 60 == 0 {
			let now = Date()
			let x = now.timeIntervalSince(last)
			print(String(format: "%.1lf fps", 60.0/x))
			last = now
		}
		s += 1
	}

	func printCells (_ cells: [Int]) {
		for i in 0..<100 {
			print("\(cells[i])", terminator:"")
		}
		print("")
	}

	func start () {
		timer.start()
	}
	func stop () {
		timer.stop()
	}
}
