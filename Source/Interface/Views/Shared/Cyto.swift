//
//  Cyto.swift
//  Aexels
//
//  Created by Joe Charlier on 1/30/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

import Acheron
import UIKit

class Cyto: UIView {
    class Cell: AEView {
        let c: Int
        let r: Int
        let w: Int
        let h: Int
        
        init(c: Int = 0, r: Int = 0, w: Int = 1, h: Int = 1) {
            self.c = c
            self.r = r
            self.w = w
            self.h = h
            super.init()
        }
    }

    var cells: [Cell] = []
    var rows: Int = 1
    var cols: Int = 1
    var Xs: [CGFloat] = []
    var Ys: [CGFloat] = []
    var padding: CGFloat = 10
    
    var showGrid: Bool = false
    
    func dx(_ cell: Cell) -> CGFloat { Xs[0..<cell.c].summate { $0 } }
    func dy(_ cell: Cell) -> CGFloat { Ys[0..<cell.r].summate { $0 } }
    func width(_ cell: Cell) -> CGFloat { Xs[cell.c..<(cell.c+cell.w)].summate { $0 } }
    func height(_ cell: Cell) -> CGFloat { Ys[cell.r..<(cell.r+cell.h)].summate { $0 } }
    
    func layout() {
        Xs = []
        Ys = []
        
        subviews.forEach { $0.removeFromSuperview() }
        
        let cw: CGFloat = width/CGFloat(cols)
        let ch: CGFloat = height/CGFloat(rows)
        
        for _ in 0..<cols { Xs.append(cw) }
        for _ in 0..<rows { Ys.append(ch) }
        
        cells.forEach {
            addSubview($0)
            $0.topLeft(dx: dx($0)+padding, dy: dy($0)+padding, width: width($0)-2*padding, height: height($0)-2*padding)
        }
    }
    
// UIView ==========================================================================================
    override func layoutSubviews() { layout() }
}

class ColorCell: Cyto.Cell {
    init(c: Int, r: Int, w: Int = 1, h: Int = 1, color: UIColor) {
        super.init(c: c, r: r, w: w, h: h)
        backgroundColor = color
    }
}
