//
//  UIFont+AX.swift
//  Aexels
//
//  Created by Joe Charlier on 1/2/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import UIKit

extension UIFont {
	static func ax(size: CGFloat) -> UIFont { UIFont(name: "Trajan Pro", size: size)! }
	static func axBold(size: CGFloat) -> UIFont { UIFont(name: "TrajanPro-Bold", size: size)! }
    static func optima(size: CGFloat) -> UIFont { UIFont(name: "Optima", size: size)! }
    static func avenir(size: CGFloat) -> UIFont { UIFont(name: "Avenir-Heavy", size: size)! }
}
