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
    var aether: Aether!
	var auto: Auto!
	
	var guideOn: Bool = false
	
	let size: Int

	var frameRate: Int {
		set {Aexels.sync.link.preferredFramesPerSecond = newValue}
		get {return Aexels.sync.link.preferredFramesPerSecond}
	}

	var needsCompile: Bool = true
	
	var cells: UnsafeMutablePointer<Double>
	var next: UnsafeMutablePointer<Double>

	let iterations: Int = 3
	let stride: Int
	var automatas: [UnsafeMutablePointer<Automata>] = []
	
	private var views = [CellularView]()
	
	var onMeasure: ((Double)->())?
	
	init(size: Int) {
		self.size = size
		stride = size/iterations
		cells = UnsafeMutablePointer<Double>.allocate(capacity: size*size)
		next = UnsafeMutablePointer<Double>.allocate(capacity: size*size)
		
//		var last: DispatchTime = DispatchTime.now()
		
		Aexels.sync.onFire = { (link: CADisplayLink, complete: @escaping ()->()) in
//			let current = DispatchTime.now()
//			let delta = Double(current.uptimeNanoseconds - last.uptimeNanoseconds)/1000000000
//			print("=====================================================")
//			print("    total:\t\t\(delta) or \(round(1/delta)) SPS")
//			last = current
			self.step {
				DispatchQueue.global(qos: .userInitiated).async {
//					let start = DispatchTime.now()
					DispatchQueue.concurrentPerform(iterations: self.views.count, execute: { (i: Int) in
						self.views[i].start()
						self.views[i].renderImage()
					})
//					let current = DispatchTime.now()
//					let delta = Double(current.uptimeNanoseconds - start.uptimeNanoseconds)/1000000000
//					print("    render:\t\t\(delta) or \(round(1/delta)) SPS")
					complete()
					DispatchQueue.main.async {
						self.views.forEach {$0.setNeedsDisplay()}
					}
				}
			}
		}
	}
	deinit {
		automatas.forEach {AXAutomataRelease($0)}
	}
	
	func compile(aether: Aether) {
		self.aether = aether
		aether.prepare()

		let sI = AEMemoryIndexForName(aether.memory, "Auto1.Self".toInt8())
		let aI = AEMemoryIndexForName(aether.memory, "Auto1.A".toInt8())
		let bI = AEMemoryIndexForName(aether.memory, "Auto1.B".toInt8())
		let cI = AEMemoryIndexForName(aether.memory, "Auto1.C".toInt8())
		let dI = AEMemoryIndexForName(aether.memory, "Auto1.D".toInt8())
		let eI = AEMemoryIndexForName(aether.memory, "Auto1.E".toInt8())
		let fI = AEMemoryIndexForName(aether.memory, "Auto1.F".toInt8())
		let gI = AEMemoryIndexForName(aether.memory, "Auto1.G".toInt8())
		let hI = AEMemoryIndexForName(aether.memory, "Auto1.H".toInt8())
		let rI = AEMemoryIndexForName(aether.memory, "AtR_1".toInt8())

		let memory: UnsafeMutablePointer<Memory> = AEMemoryCreateClone(aether.memory)
		
		AEMemoryClear(memory)
		auto = aether.firstAuto()!
		auto.foreshadow(memory)
		
		let recipe: UnsafeMutablePointer<Recipe> = Web.compile(result: auto.resultTower, memory: memory)

		automatas.forEach {AXAutomataRelease($0)}
		automatas.removeAll()

		let automata = AXAutomataCreate(recipe, memory, Int32(size), sI, aI, bI, cI, dI, eI, fI, gI, hI, rI);
		for _ in 0..<iterations {
			automatas.append(AXAutomataCreateClone(automata))
		}
		
		AXAutomataRelease(automata)
		AERecipeRelease(recipe)
		AEMemoryRelease(memory)
		
		configureViews()
	}
	func configureViews() {
		views.forEach {$0.configure(auto: auto)}
	}
	
	func addView(_ view: CellularView) {
		self.views.append(view)
		view.engine = self
	}
	func removeView(_ view: CellularView) {
		view.engine = nil
		if let index = self.views.firstIndex(of: view) {
			self.views.remove(at: index)
		}
		view.clear()
		view.setNeedsDisplay()
	}
	func removeAllViews() {
		for view in views {
			view.engine = nil
			if let index = views.firstIndex(of: view) {
				views.remove(at: index)
			}
			view.clear()
			view.setNeedsDisplay()
		}
	}
	
	private func populate () {
		for i in 0..<size {
			for j in 0..<size {
				cells[i+j*size] = Double(arc4random_uniform(UInt32(auto.states.count)))
			}
		}
	}

	var working: Bool = false
	func step(_ complete: @escaping ()->()) {
		guard !working else {/*print("step skipped");*/return}
		working = true
//		let start = DispatchTime.now()

		DispatchQueue.global(qos: .userInitiated).async {
			DispatchQueue.concurrentPerform(iterations: self.iterations, execute: { (i: Int) in
				AXAutomataStep(self.automatas[i], self.cells, self.next, Int32(i*self.stride), Int32(i == self.iterations-1 ? self.size : (i+1)*self.stride))
			})

			(self.cells, self.next) = (self.next, self.cells)

//			let end = DispatchTime.now()
//			let delta = Double(end.uptimeNanoseconds - start.uptimeNanoseconds)/1000000000
//			print("    calculate:\t\(delta) or \(round(1/delta)) SPS")
			self.working = false
			complete()
		}
	}

	func start(aether: Aether) {
		if needsCompile {
			compile(aether: aether)
			needsCompile = false
		}
		Aexels.sync.start()
	}
	func stop() {
		Aexels.sync.stop()
	}
	func reset() {
		populate()
		views.forEach {$0.flash()}
	}
}
