//
//  Explorer.swift
//  Aexels
//
//  Created by Joe Charlier on 1/4/17.
//  Copyright © 2017 Aepryus Software. All rights reserved.
//

import Acheron
import OoviumKit
import UIKit

class Explorer: AEViewController, TimeControlDelegate {
    enum Mode { case simulation, configuration }

    var mode: Mode = .simulation    

	let key: String
    
    var cyto: Cyto!
    let configCyto: Cyto = Cyto(rows: 2, cols: 1)
    
    // Title ======
    let titleLabel: UILabel = UILabel()
    
    // Tabs =======
    var tabsCell: TabsCell!

    let titleCell: MaskCell = !Screen.iPhone ? MaskCell(content: UIView(), c: 1, r: 0, cutouts: [.upperRight]) : MaskCell(content: UIView(), c: 0, r: 1, cutouts: [.lowerLeft, .lowerRight])
    
    // Quick ======
    let quickView: UIView = UIView()
    let timeControl: TimeControl = TimeControl()

    // Existing ===
    lazy var vision: Vision = ExplorerVision(explorer: self)
    
    let swapButton: SwapButton = SwapButton()
    let swapperButton: CircleButton
    let glyphsButton: CircleButton
    
    var experiments: [Experiment] = []
    var experiment: Experiment? = nil {
        didSet {
            guard experiment !== oldValue else { return }
        }
    }
    
	init(key: String) {
		self.key = key
        
        swapButton.bounds = CGRect(origin: .zero, size: CGSize(width: 26*Screen.s, height: 26*Screen.s))
        swapperButton = CircleButton(view: swapButton)
        
        let imageView: UIImageView = UIImageView(image: UIImage(named: "glyphs_icon")!)
        imageView.bounds = CGRect(origin: .zero, size: CGSize(width: 30*Screen.s, height: 30*Screen.s))
        glyphsButton = CircleButton(view: imageView)
        glyphsButton.addAction {
            Aexels.explorerViewController.explorer = Aexels.nexusExplorer
        }
        
        super.init()
	}
	
    var iconToken: String { "\(key)_icon" }
    var icon: UIImage { UIImage(named: iconToken)! }
    
    var name: String { "\(key)_name".localized }
    var shortName: String { name }
    var labName: String { "\(key)_lab_name".localized }
    
    func toConfiguration() {
        UIView.animate(withDuration: 0.2) {
            self.cyto.alpha = 0
        } completion: { (complete: Bool) in
            self.cyto.isHidden = true
            self.configCyto.isHidden = false
            UIView.animate(withDuration: 0.2) {
                self.configCyto.alpha = 1
            }
        }
    }
    func toSimulation() {
        UIView.animate(withDuration: 0.2) {
            self.configCyto.alpha = 0
        } completion: { (complete: Bool) in
            self.configCyto.isHidden = true
            self.cyto.isHidden = false
            UIView.animate(withDuration: 0.2) {
                self.cyto.alpha = 1
            }
        }
    }
    
    func swapLimbos() {
        if mode == .simulation {
            mode = .configuration
            toConfiguration()
        } else {
            mode = .simulation
            toSimulation()
        }
    }
    func tapSwapButton() {
        swapButton.rotateView()
        swapLimbos()
    }
    
// AEViewController ================================================================================
    override func layoutRatio056() {        
        let height: CGFloat = Screen.height - Screen.safeTop - Screen.safeBottom
        let uh: CGFloat = height - 80*s
        
        cyto.frame = CGRect(x: 5*s, y: safeTop, width: view.width-10*s, height: height)
        configCyto.frame = cyto.frame

        cyto.Ys = [uh]
        cyto.layout()
        
        configCyto.Ys = [uh]
        configCyto.layout()

        swapperButton.bottomLeft(dx: -2*s, dy: -25*s, width: 54*s, height: 54*s)
        glyphsButton.bottomRight(dx:  2*s, dy: -25*s, width: 54*s, height: 54*s)

        titleLabel.center(width: 300*s, height: 24*s)
        timeControl.center(width: 114*s, height: 54*s)
    }
    
// UIViewController ================================================================================
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configCyto.alpha = 0
        configCyto.isHidden = true
        view.addSubview(configCyto)
        
        // Title ========
        titleLabel.text = labName
        titleLabel.pen = Pen(font: .optima(size: 20*s), color: .white, alignment: .center)
        titleCell.content?.addSubview(titleLabel)
        
        timeControl.playButton.playing = true
        timeControl.delegate = self
        quickView.addSubview(timeControl)
        
        if Screen.iPhone {
            view.addSubview(swapperButton)
            swapButton.addAction { [unowned swapButton] in
                swapButton.rotateView()
                self.swapLimbos()
            }
            
            view.addSubview(glyphsButton)
        }
    }
}
