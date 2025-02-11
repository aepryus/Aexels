//
//  ExperimentsTab.swift
//  Aexels
//
//  Created by Joe Charlier on 1/23/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

import Acheron
import OoviumEngine
import OoviumKit
import UIKit

class ExperimentView: AXButton {
    var experiment: Experiment! { didSet { setNeedsDisplay() } }
    
    override init() {
        super.init()
        backgroundColor = .clear
    }
    
    static let namePen: Pen = Pen(font: .optima(size: 14*Screen.s), color: .white.shade(0.6))
    static let notesPen: Pen = Pen(font: .optima(size: 12*Screen.s), color: .white)

// UIView ==========================================================================================
    override var isHighlighted: Bool {
        didSet { setNeedsDisplay() }
    }
    
    override func draw(_ rect: CGRect) {
        let p: CGFloat = 3*s
        let radius: CGFloat = 8*s
        let th: CGFloat = 20*s
        
        let x1 = p
        let x3 = width - p
        let x2 = (x1+x3)/2
        
        let y1 = p
        let y2 = y1 + th
        let y4 = height - p
        let y3 = (y1+y4)/2
        
        let color: CGColor = isHighlighted ? OOColor.lavender.uiColor.cgColor : UIColor.white.cgColor
        
        let c = UIGraphicsGetCurrentContext()!
        c.move(to: CGPoint(x: x1, y: y2))
        c.addArc(tangent1End: CGPoint(x: x1, y: y1), tangent2End: CGPoint(x: x2, y: y1), radius: radius)
        c.addArc(tangent1End: CGPoint(x: x3, y: y1), tangent2End: CGPoint(x: x3, y: y2), radius: radius)
        c.addLine(to: CGPoint(x: x3, y: y2))
        c.closePath()
        c.setLineWidth(1)
        c.setStrokeColor(color)
        c.setFillColor(color)
        c.drawPath(using: .eoFillStroke)

        c.move(to: CGPoint(x: x1, y: y3))
        c.addArc(tangent1End: CGPoint(x: x1, y: y1), tangent2End: CGPoint(x: x2, y: y1), radius: radius)
        c.addArc(tangent1End: CGPoint(x: x3, y: y1), tangent2End: CGPoint(x: x3, y: y3), radius: radius)
        c.addArc(tangent1End: CGPoint(x: x3, y: y4), tangent2End: CGPoint(x: x2, y: y4), radius: radius)
        c.addArc(tangent1End: CGPoint(x: x1, y: y4), tangent2End: CGPoint(x: x1, y: y3), radius: radius)
        c.closePath()
        
        c.setLineWidth(2*s)
        c.strokePath()

        experiment.name.draw(at: CGPoint(x: x1+6*s, y: y1+2*s), pen: ExperimentView.namePen)
        experiment.notes.draw(at: CGPoint(x: x1+6*s, y: y2+6*s), pen: ExperimentView.notesPen)
    }
}

class ExperimentsCell: UITableViewCell {
    var experiment: Experiment! {
        didSet { experimentView.experiment = experiment }
    }
    weak var tab: ExperimentsTab?
    
    let experimentView: ExperimentView = ExperimentView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(experimentView)
        experimentView.addAction { [weak self] in
            guard let self, let tab = self.tab else { return }
            tab.onSelected(experiment: self.experiment)
        }
    }
    required init?(coder: NSCoder) { fatalError() }
    
// UIView ==========================================================================================
    override func layoutSubviews() {
        experimentView.frame = bounds.insetBy(dx: 5*s, dy: 5*s)
    }
}

class ExperimentsTab: TabsCellTab, UITableViewDataSource, UITableViewDelegate {
    unowned let explorer: Explorer!
    
    let tableView: UITableView = AETableView()
    
    init(explorer: Explorer) {
        self.explorer = explorer
        super.init(name: "Experiments".localized)
        
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = false
        tableView.alwaysBounceVertical = true
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ExperimentsCell.self, forCellReuseIdentifier: "cell")
        addSubview(tableView)
    }
    
// Events ==========================================================================================
    func onSelected(experiment: Experiment) {
        explorer.experiment = experiment
        if Screen.iPhone { explorer.tapSwapButton() }
    }
    
// UIView ==========================================================================================
    override func layoutSubviews() {
        tableView.frame = CGRect(x: 10*s, y: 10*s, width: bounds.size.width-20*s, height: bounds.size.height-44*s)
    }
    
// UITableViewDataSource ===========================================================================
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { explorer.experiments.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! ExperimentsCell
        cell.experiment = explorer.experiments[indexPath.row]
        cell.tab = self
        return cell
    }
    
// UITableViewDelegate =============================================================================
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 80*s }
}
