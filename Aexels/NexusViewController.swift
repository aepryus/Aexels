//
//  NexusViewController.swift
//  Aexels
//
//  Created by Joe Charlier on 1/2/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import UIKit

class NexusViewController: UIViewController {
	let imageView = UIImageView(image: UIImage(named: "Back.png"))
	
	var nexusLabel: NexusLabel!
	var introButton: NexusButton!
	var cellularAutomataButton: NexusButton!
	var kinematicsButton: NexusButton!
	var gravityButton: NexusButton!
	var timeDilationButton: NexusButton!
	var lengthContractionButton: NexusButton!
	var darknessButton: NexusButton!
	
// UIViewController ================================================================================
	override func viewDidLoad() {
        super.viewDidLoad()
		
		let y0: CGFloat = 170
		let mh: CGFloat = 70
		var i: CGFloat = 0
		
		imageView.frame = view.frame
		view.addSubview(imageView)

		nexusLabel = NexusLabel(text: "Aexels")
		nexusLabel.frame = CGRect(x: 52, y: 52, width: 300, height: 96)
		view.addSubview(nexusLabel)
		
		introButton = NexusButton(text: "Intro")
		introButton.frame = CGRect(x: 50, y: y0+i*mh, width: 300, height: 32)
		introButton.addClosure({
			let messageView = MessageView()
			messageView.load(text: NSLocalizedString("Intro", comment: ""))
			self.view.addSubview(messageView)
		}, controlEvents: .touchUpInside)
		view.addSubview(introButton)
		i += 1
		
		cellularAutomataButton = NexusButton(text: "Cellular Automata")
		cellularAutomataButton.frame = CGRect(x: 50, y: y0+i*mh, width: 300, height: 32)
		view.addSubview(cellularAutomataButton)
		i += 1
		
		kinematicsButton = NexusButton(text: "Kinematics")
		kinematicsButton.frame = CGRect(x: 50, y: y0+i*mh, width: 300, height: 32)
		view.addSubview(kinematicsButton)
		i += 1
		
		gravityButton = NexusButton(text: "Gravity")
		gravityButton.frame = CGRect(x: 50, y: y0+i*mh, width: 300, height: 32)
		view.addSubview(gravityButton)
		i += 1
		
		timeDilationButton = NexusButton(text: "Time Dilation")
		timeDilationButton.frame = CGRect(x: 50, y: y0+i*mh, width: 300, height: 32)
		view.addSubview(timeDilationButton)
		i += 1
		
		lengthContractionButton = NexusButton(text: "Length Contraction")
		lengthContractionButton.frame = CGRect(x: 50, y: y0+i*mh, width: 300, height: 32)
		view.addSubview(lengthContractionButton)
		i += 1
		
		darknessButton = NexusButton(text: "Darkness")
		darknessButton.frame = CGRect(x: 50, y: y0+i*mh, width: 300, height: 32)
		view.addSubview(darknessButton)
		i += 1
    }
}
