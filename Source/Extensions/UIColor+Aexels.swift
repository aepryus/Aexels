//
//  UIColor+Aexels.swift
//  Aexels
//
//  Created by Joe Charlier on 2/28/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

import UIKit

extension UIColor {
    var simd4: SIMD4<Float> {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return SIMD4<Float>(Float(red), Float(green), Float(blue), Float(alpha))
    }
}
