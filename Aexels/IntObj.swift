//
//  IntObj.swift
//  Aexels
//
//  Created by Joe Charlier on 1/8/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import Foundation
import OoviumLib

class IntObj: Obj {
	var n: Int = 0

// Obj =============================================================================================
	public var def: Def {
		get {return RealDef.def}
	}
	public var description: String {
		get {return ""}
	}
	func mimic (_ obj: Obj) {}
}
