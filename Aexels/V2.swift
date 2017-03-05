//
//  V2.swift
//  Aexels
//
//  Created by Joe Charlier on 2/18/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import Foundation

struct V2 {
	var x: Double
	var y: Double
	
	init (_ x: Double, _ y: Double) {
		self.x = x
		self.y = y
	}

	func len () -> Double {
		return sqrt(x*x+y*y)
	}

	static func + (a: V2, b: V2) -> V2 {
		return V2(a.x+b.x, a.y+b.y)
	}
	static func - (a: V2, b: V2) -> V2 {
		return V2(a.x-b.x, a.y-b.y)
	}
	static func * (a: V2, b: Double) -> V2 {
		return V2(a.x*b, a.y*b)
	}
	
	static func dot (_ a: V2, _ b: V2) -> Double {
		return a.x*b.x+a.y*b.y
	}
	static func det (_ a: V2, _ b: V2) -> Double {
		return a.x*b.y-a.y*b.x
	}
	static func innerAngle (_ a: V2, _ b: V2) -> Double {
		return acos(dot(a,b)/a.len()/b.len())
	}
	static func clockwiseAngle (_ a: V2, _ b: V2) -> Double {
		return atan2(det(a,b), dot(a,b))
	}
}
