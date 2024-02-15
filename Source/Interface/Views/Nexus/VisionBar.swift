//
//  VisionBar.swift
//  Aexels
//
//  Created by Joe Charlier on 2/8/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

import Acheron
import UIKit

public class Vision: AEView {
    var visionBar: VisionBar!
    
    override init() {
        super.init()
        backgroundColor = .clear
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap)))
    }
    
    func render() {}
    func rescale() {}
    
// Events ==========================================================================================
    @objc func onTap() { visionBar.tap(vision: self) }
    func onSelect() {}
    func onDeselect() {}
    
// UIView ==========================================================================================
    public override func draw(_ rect: CGRect) {}
}

public class VisionBox {
    let visions: [[Vision?]]
    public init(visions: [[Vision?]]) { self.visions = visions }
    
    var noOfColumns: Int { visions.count }
    var noOfRows: Int { visions[0].count }
    
    func contains(_ vision: Vision) -> Bool { visions.contains(where: { $0.contains(where: { $0 === vision }) }) }
    func vision(col: Int, row: Int) -> Vision? {
        guard col < visions.count else { return nil }
        let column: [Vision?] = visions[col]
        guard row < column.count else { return nil }
        return column[row]
    }
}

class VisionBar: AEView {
    var visionBox: VisionBox
    var selected: Vision
    var expanded: Bool
    
    var onSelect: (Vision)->() = {(vision: Vision) in }
    
    init(visionBox: VisionBox) {
        self.visionBox = visionBox
        selected = self.visionBox.visions[0][0]!
        expanded = false
        
        super.init()
        
        visionBox.visions.forEach({ $0.forEach({
            $0?.visionBar = self
            $0?.alpha = 0
        }) })
        
        selected.alpha = 1
        addSubview(selected)
        selected.topLeft(dx: (noOfColumns-1)*40*s, width: 40*s, height: 40*s)

        topRight(dx: -5*s, dy: Screen.safeTop+5*s, width: noOfColumns*40*s, height: noOfRows*40*s)

        for i in 0..<visionBox.noOfColumns {
            for j in 0..<visionBox.noOfRows {
                guard let vision = visionBox.vision(col: i, row: j),
                      vision !== selected
                    else { continue }
                vision.topLeft(dx: 40*s*CGFloat(i), dy: 40*s*CGFloat(j), width: 40*s, height: 40*s)
            }
        }
    }
    
    private func selectedOrigin() -> CGPoint {
        for i in 0..<visionBox.noOfColumns {
            for j in 0..<visionBox.noOfRows {
                guard let vision = visionBox.vision(col: i, row: j),
                      vision === selected
                    else { continue }
                return CGPoint(x: 40*s*CGFloat(i), y: 40*s*CGFloat(j))
            }
        }
        return .zero
    }
    
    var noOfColumns: CGFloat { CGFloat(visionBox.noOfColumns) }
    var noOfRows: CGFloat { CGFloat(visionBox.noOfRows) }

    func expand() {
        guard !expanded else { return }
        expanded = true
        onExpand()
        selected.topLeft(dx: (noOfColumns-1)*40*s, width: 40*s, height: 40*s)
        visionBox.visions.forEach({ $0.forEach({ if let vision = $0, vision !== selected { addSubview(vision) } }) })
        let origin = selectedOrigin()
        UIView.animate(withDuration: 0.2) {
            self.selected.frame = CGRect(x: origin.x, y: origin.y, width: 40*self.s, height: 40*self.s)
            self.visionBox.visions.forEach({ $0.forEach({ if let vision = $0, vision !== self.selected { vision.alpha = 1 } }) })
        }
    }
    func contract() {
        guard expanded else { return }
        expanded = false
        onContract()
        UIView.animate(withDuration: 0.2) {
            self.selected.topLeft(dx: (self.noOfColumns-1)*40*self.s, width: 40*self.s, height: 40*self.s)
            self.visionBox.visions.forEach({ $0.forEach({ if let vision = $0, vision !== self.selected { vision.alpha = 0 } }) })
        } completion: { (complete: Bool) in
            guard complete && !self.expanded else { return }
            self.visionBox.visions.forEach({ $0.forEach({ if let vision = $0, vision !== self.selected { vision.removeFromSuperview() } }) })
        }
    }
    
    func select(vision: Vision) {
        selected = vision
        selected.topLeft(dx: (self.noOfColumns-1)*40*self.s, width: 40*self.s, height: 40*self.s)
        selected.alpha = 1
        addSubview(selected)
        visionBox.visions.forEach({ $0.forEach({ if let vision = $0, vision !== self.selected {
            vision.alpha = 0
            vision.removeFromSuperview()
        } }) })

    }
    func tap(vision: Vision) {
        if expanded {
            selected.onDeselect()
            selected = vision
            selected.onSelect()
            onSelect(vision)
            contract()
        } else { expand() }
    }
    
// Events ==========================================================================================
    func onExpand() {}
    func onContract() {}
    
// UIView ==========================================================================================
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        return view !== self ? view : nil
    }
}

class ExplorerVision: Vision {
    let explorer: AEViewController
    let imageView: UIImageView = UIImageView()
    
    init(explorer: AEViewController) {
        self.explorer = explorer
        super.init()
        
        imageView.contentMode = .scaleAspectFill
        imageView.layer.borderColor = UIColor.black.tint(0.5).cgColor
        imageView.layer.borderWidth = 2
        
        let named: String
        if let explorer = explorer as? Explorer { named = "\(explorer.key)_icon" }
        else { named = "nexus_icon" }
        
        imageView.image = UIImage(named: named)!
        imageView.layer.masksToBounds = true
        addSubview(imageView)
    }
    
// Vision ==========================================================================================
    override func onSelect() {
        Aexels.explorerViewController.explorer = explorer
    }
    
// UIView ==========================================================================================
    override func layoutSubviews() {
        imageView.center(width: width-2*s, height: height-2*s)
        imageView.layer.cornerRadius = imageView.width/2
    }
}
