//
//  CellularEngine.swift
//  Aexels
//
//  Created by Joe Charlier on 1/7/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import Aepryus
import Foundation
import Loom
import OoviumLib

final class CellularEngine {
    let aether: Aether
	let auto: Auto
	
	var guideOn: Bool = false
	
	let w: Int
	let h: Int
	var interval: Double {
		set {
			timer.interval = newValue
		}
		get {return timer.interval}
	}
	
	var cells: UnsafeMutablePointer<Obj>
	var next: UnsafeMutablePointer<Obj>
	var xfer: UnsafeMutablePointer<Obj>!
	
	var memory: UnsafeMutablePointer<Memory>!
	let index: Int
	let web: Web
//	let recipeS: RecipeS
	let recipe: UnsafeMutablePointer<Recipe>
	
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
	private var timer: AXTimer
	
	private let conQue: DispatchQueue = DispatchQueue(label: "Aexels", attributes: .concurrent)
	
	var onMeasure: ((Double)->())?
	
	init? (aetherName: String, w: Int, h: Int) {
		
		var json: String
		do {
			json = try String(contentsOfFile: Bundle.main.path(forResource: aetherName, ofType: "oo")!)
		} catch {
			print("\(error)")
			return nil
		}
	
		let attributes = JSON.fromJSON(json: json)
//		let basket = Basket(iOSPersist(), forked: false)
		aether = Aether()
		aether.load(attributes: attributes)
//		aether = basket.inject(attributes) as! Aether
//		aether.wire()
//		aether.calculate()
		memory = aether.memory
//		AEMemoryPrint(memory);
		index = Int(AEMemoryIndexForName(memory, "AtR_1".toInt8()))
		auto = aether.firstAuto()!
		auto.foreshadow(memory)
		web = Web(head: auto.headTower, tail: auto.resultTower, memory: memory)
//		recipeS = web.recipeS
//		recipe = recipeS.compile()
		recipe = web.recipe
//		AERecipePrint(recipe)
		
		
		self.w = w
		self.h = h
		cells = UnsafeMutablePointer<Obj>.allocate(capacity: w*h)
		next = UnsafeMutablePointer<Obj>.allocate(capacity: w*h)
		
		selfI = Int(AEMemoryIndexForName(memory, "Auto1.Self".toInt8()))
		aI = Int(AEMemoryIndexForName(memory, "Auto1.A".toInt8()))
		bI = Int(AEMemoryIndexForName(memory, "Auto1.B".toInt8()))
		cI = Int(AEMemoryIndexForName(memory, "Auto1.C".toInt8()))
		dI = Int(AEMemoryIndexForName(memory, "Auto1.D".toInt8()))
		eI = Int(AEMemoryIndexForName(memory, "Auto1.E".toInt8()))
		fI = Int(AEMemoryIndexForName(memory, "Auto1.F".toInt8()))
		gI = Int(AEMemoryIndexForName(memory, "Auto1.G".toInt8()))
		hI = Int(AEMemoryIndexForName(memory, "Auto1.H".toInt8()))
		
		timer = AXTimer()
		timer.configure(interval: interval, {
			self.tic()
		})
		
		populate(auto: auto)
	}
	
	func addView (_ view: CellularView) {
		DispatchQueue.main.async {
			self.views.append(view)
			view.engine = self
			view.configure(auto: self.auto)
		}
	}
	func removeView (_ view: CellularView) {
		DispatchQueue.main.async {
			view.engine = nil
			if let index = self.views.index(of: view) {
				self.views.remove(at: index)
			}
			view.clear()
			view.setNeedsDisplay()
		}
	}
	
	private func populate (auto: Auto) {
		for i in 0..<w {
			for j in 0..<h {
				cells[i+j*w].a.x = Double(arc4random_uniform(UInt32(auto.states.count)))
			}
		}
	}

	private func loadMemory (_ i: Int, x: Int, y: Int) {
		if x < 0 || x >= w || y < 0 || y >= h {
			memory.pointee.slots[i].obj.a.x = 0
		} else {
			memory.pointee.slots[i].obj.a.x = cells[x + y*w].a.x
		}
		memory.pointee.slots[i].loaded = 1
	}
	private func loadMemory (memory: UnsafeMutablePointer<Memory>,_ i: Int, x: Int, y: Int) {
		if x < 0 || x >= w || y < 0 || y >= h {
			memory.pointee.slots[i].obj.a.x = 0
		} else {
			memory.pointee.slots[i].obj.a.x = cells[x + y*w].a.x
		}
		memory.pointee.slots[i].loaded = 1
	}

	var last: Date = Date()
	var s: Int = 1
	
//	var groups: [DispatchGroup] = []
	
	func tic() {
		for j in 0..<h {
			for i in 0..<w {
				AEMemoryClear(memory);
				
				loadMemory(selfI, x: i, y: j)
				loadMemory(aI, x: i-1, y: j-1)
				loadMemory(bI, x: i  , y: j-1)
				loadMemory(cI, x: i+1, y: j-1)
				loadMemory(dI, x: i+1, y: j  )
				loadMemory(eI, x: i+1, y: j+1)
				loadMemory(fI, x: i  , y: j+1)
				loadMemory(gI, x: i-1, y: j+1)
				loadMemory(hI, x: i-1, y: j  )
				
//				AEMemoryPrint(memory)
				AERecipeExecute(recipe, memory)
//				AEMemoryPrint(memory)
				next[i + j*w].a.x = memory.pointee.slots[index].obj.a.x
			}
		}
		
		xfer = cells
		cells = next
		next = xfer
		
		DispatchQueue.main.async {
			for view in self.views {
				view.tic()
			}
		}
		
		if s % 60 == 0 {
			let now = Date()
			let x = now.timeIntervalSince(last)
			if let onMeasure = onMeasure {
				onMeasure(60.0/x)
			}
			last = now
		}
		s += 1
	}
//	func threadedTic() {
//		unowned let me = self
////		for j in 0..<h {
////			group.enter()
////			self.conQue.async(group: group, execute: {
////				let q = j;
////				let memory: UnsafeMutablePointer<Memory> = AEMemoryCreate(Int(me.memory.pointee.sn))!;
////				for i in 0..<me.w {
////					AEMemoryClear(memory);
////
////					me.loadMemory(memory: memory, me.selfI, x: i, y: q)
////					me.loadMemory(memory: memory, me.aI, x: i-1, y: q-1)
////					me.loadMemory(memory: memory, me.bI, x: i  , y: q-1)
////					me.loadMemory(memory: memory, me.cI, x: i+1, y: q-1)
////					me.loadMemory(memory: memory, me.dI, x: i+1, y: q  )
////					me.loadMemory(memory: memory, me.eI, x: i+1, y: q+1)
////					me.loadMemory(memory: memory, me.fI, x: i  , y: q+1)
////					me.loadMemory(memory: memory, me.gI, x: i-1, y: q+1)
////					me.loadMemory(memory: memory, me.hI, x: i-1, y: q  )
////
////					AERecipeExecute(me.recipe, memory)
////					me.next[i + q*me.w].a.x = memory.pointee.slots[me.index].obj.a.x
////				}
////				me.group.leave()
////			})
////		}
//		let group = DispatchGroup()
////		groups.append(group)
//		var n: Int = 0
//		let a: Int = me.h
//		let b: Int = me.w
//		for j in 0..<h {
//			group.enter()
//			conQue.async(group: group, execute: {
//				let memory: UnsafeMutablePointer<Memory> = AEMemoryCreate(Int(me.memory.pointee.sn))!;
//				for i in 0..<me.w {
////					AEMemoryClear(memory);
////					AERecipeExecute(me.recipe, memory)
////					me.next[i + j*me.w].a.x = memory.pointee.slots[me.index].obj.a.x
//					n += i + j*b
////					me.next[i + j*me.w].a.x = 0
//				}
//				group.leave()
//			})
//		}
//		group.notify(queue: timer.queue) {
//			me.xfer = me.cells
//			me.cells = me.next
//			me.next = me.xfer
//
//			DispatchQueue.main.async {
//				for view in me.views {
//					view.tic()
//				}
//			}
//
//			if me.s % 60 == 0 {
//				let now = Date()
//				let x = now.timeIntervalSince(me.last)
//				if let onMeasure = me.onMeasure {
//					onMeasure(60.0/x)
//				}
//				me.last = now
//			}
//			me.s += 1
////			me.groups.remove(object: group)
//		}
//
////		group.notify(queue: timer.queue) {
////			me.xfer = me.cells
////			me.cells = me.next
////			me.next = me.xfer
////
////			DispatchQueue.main.async {
////				for view in me.views {
////					view.tic()
////				}
////			}
////
////			if me.s % 60 == 0 {
////				let now = Date()
////				let x = now.timeIntervalSince(me.last)
////				if let onMeasure = me.onMeasure {
////					onMeasure(60.0/x)
////				}
////				me.last = now
////			}
////			me.s += 1
////		}
//	}

	func printCells (_ cells: [Int]) {
		for i in 0..<100 {
			print("\(cells[i])", terminator:"")
		}
		print("")
	}

	func start() {
		timer.start()
	}
	func stop() {
		timer.stop()
	}
	func reset() {
		stop()
		populate(auto: auto)
		for view in views {
			view.tic()
		}
	}
}
