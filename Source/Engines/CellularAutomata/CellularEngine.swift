//
//  CellularEngine.swift
//  Aexels
//
//  Created by Joe Charlier on 1/7/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import Acheron
import Aegean
import Foundation
import OoviumEngine
import OoviumKit
import QuartzCore

class CellularEngine {
	var aether: Aether!
    private var auto: OoviumEngine.Automata!

	var guideOn: Bool = false
	var frameRate: Int = 60 {
		didSet {
			guard frameRate != oldValue else {return}
			Aexels.sync.link.preferredFramesPerSecond = frameRate
		}
	}

	var needsCompile: Bool = true

	var cells: UnsafeMutablePointer<Double>
	private var next: UnsafeMutablePointer<Double>

	private let side: Int

	private var views = [CellularView]()

	private let iterations: Int = ProcessInfo.processInfo.activeProcessorCount + 1
	private let stride: Int
	private var automatas: [UnsafeMutablePointer<AXAutomata>] = []
	
	init(side: Int) {
		self.side = side
		stride = side/iterations
		cells = UnsafeMutablePointer<Double>.allocate(capacity: side*side)
		next = UnsafeMutablePointer<Double>.allocate(capacity: side*side)
	}
	deinit {
		automatas.forEach {AXAutomataRelease($0)}
	}
	
	private func populate () {
		for i in 0..<side {
			for j in 0..<side {
				cells[i+j*side] = Double(arc4random_uniform(UInt32(auto.states.count)))
			}
		}
	}
	
	func compile(aether: Aether) {
		self.aether = aether
        let automata: Automata = self.aether.first()!
        
        let citadel: Citadel = self.aether.compile()
        
        let automataCore: AutomataCore = citadel.tower(key: automata.mechlikeTokenKey)!.core as! AutomataCore

		let sI = AEMemoryIndexForName(citadel.memory, "Au1.Self".toInt8())
		let aI = AEMemoryIndexForName(citadel.memory, "Au1.A".toInt8())
		let bI = AEMemoryIndexForName(citadel.memory, "Au1.B".toInt8())
		let cI = AEMemoryIndexForName(citadel.memory, "Au1.C".toInt8())
		let dI = AEMemoryIndexForName(citadel.memory, "Au1.D".toInt8())
		let eI = AEMemoryIndexForName(citadel.memory, "Au1.E".toInt8())
		let fI = AEMemoryIndexForName(citadel.memory, "Au1.F".toInt8())
		let gI = AEMemoryIndexForName(citadel.memory, "Au1.G".toInt8())
		let hI = AEMemoryIndexForName(citadel.memory, "Au1.H".toInt8())
		let rI = AEMemoryIndexForName(citadel.memory, "Au1.result".toInt8())

		let memory: UnsafeMutablePointer<Memory> = AEMemoryCreateClone(citadel.memory)
		
		AEMemoryClear(memory)
		auto = aether.first()!
		auto.foreshadow(memory)
		
        let recipe: UnsafeMutablePointer<Recipe> = automataCore.compile(memory: memory)

		automatas.forEach { AXAutomataRelease($0) }
		automatas.removeAll()

        let axAutomata: UnsafeMutablePointer<AXAutomata> = AXAutomataCreate(recipe, memory, Int32(side), sI, aI, bI, cI, dI, eI, fI, gI, hI, rI);
		for _ in 0..<iterations {
			automatas.append(AXAutomataCreateClone(axAutomata))
		}
		
		AXAutomataRelease(axAutomata)
		AERecipeRelease(recipe)
		AEMemoryRelease(memory)
		
		configureViews()
	}
	
	// Views
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
	func configureViews() {
		views.forEach { $0.configure(auto: auto) }
	}
	
	// Timer
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
	
	private var last: Date = Date()
	private var s: Int = 1
	var onMeasure: ((Double)->())?
	func sampleFrameRate() {
		if self.s % 60 == 0 {
			let now = Date()
			let x = now.timeIntervalSince(self.last)
			if let onMeasure = self.onMeasure {
				onMeasure(60.0/x)
			}
			self.last = now
		}
		self.s += 1
	}

	private var working: Bool = false
    func doStep() {
        self.step {
            DispatchQueue.global(qos: .userInitiated).async {
                DispatchQueue.concurrentPerform(iterations: self.views.count, execute: { (i: Int) in
                    self.views[i].start()
                    self.views[i].renderImage()
                })
                DispatchQueue.main.async {
                    self.views.forEach {
                        guard $0.renderMode == .rendered else { return }
                        $0.setNeedsDisplay()
                    }
                }
            }
        }
    }
	func step(_ complete: @escaping ()->()) {
//		guard !working else {print("step skipped");return}
		guard !working else { return }
		working = true
//		let start = DispatchTime.now()

		DispatchQueue.global(qos: .userInitiated).async {
			DispatchQueue.concurrentPerform(iterations: self.iterations, execute: { (i: Int) in
				AXAutomataStep(self.automatas[i], self.cells, self.next, Int32(i*self.stride), Int32(i == self.iterations-1 ? self.side : (i+1)*self.stride))
			})

			(self.cells, self.next) = (self.next, self.cells)

//			let end = DispatchTime.now()
//			let delta = Double(end.uptimeNanoseconds - start.uptimeNanoseconds)/1000000000
//			print("    calculate:\t\(delta) or \(round(1/delta)) SPS")
			self.working = false
			complete()
		}
	}
	func defineOnFire() {
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
						self.views.forEach {
//							guard $0.renderMode == .rendered else {print("draw skipped");return}
							guard $0.renderMode == .rendered else { return }
							$0.setNeedsDisplay()
						}
//						guard self.views[0].renderMode == .rendered else {return}
//						self.sampleFrameRate()
					}
				}
			}
		}
	}
}
