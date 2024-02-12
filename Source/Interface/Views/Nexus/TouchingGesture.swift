//
//  TouchingGesture.swift
//  Aexels
//
//  Created by Joe Charlier on 10/16/18.
//  Copyright © 2018 Aepryus Software. All rights reserved.
//

import UIKit

class TouchingGesture: UIGestureRecognizer {	
// UIGestureRecognizer =============================================================================
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) { if state == .possible { state = .began } }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) { state = .ended }
	override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) { state = .ended }
}
