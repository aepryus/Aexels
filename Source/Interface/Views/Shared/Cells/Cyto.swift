//
//  Cyto.swift
//  Aexels
//
//  Created by Joe Charlier on 1/30/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

import Acheron
import UIKit

class Cyto: AEView {
    class Cell: AEView {
        var c: Int
        var r: Int
        var w: Int
        var h: Int
        
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
    var padding: CGFloat = 0
    
    var showGrid: Bool = false
    
    init(rows: Int, cols: Int) {
        self.rows = rows
        self.cols = cols
        super.init()
    }
    
    func dx(_ col: Int) -> CGFloat {
        if col == 0 { return 0 }
        if col <= Xs.count { return Xs[0..<col].summate { $0 } }
        let eX: CGFloat = Xs.summate { $0 }
        let cw: CGFloat = (width - eX) / CGFloat(cols - Xs.count)
        return eX + cw * CGFloat(col-Xs.count)
    }
    func dy(_ row: Int) -> CGFloat {
        if row == 0 { return 0 }
        if row <= Ys.count { return Ys[0..<row].summate { $0 } }
        let eY: CGFloat = Ys.summate { $0 }
        let ch: CGFloat = (height - eY) / CGFloat(rows - Ys.count)
        return eY + ch * CGFloat(row-Ys.count)
    }
    func width(_ cell: Cell) -> CGFloat { dx(cell.c+cell.w) - dx(cell.c) }
    func height(_ cell: Cell) -> CGFloat { dy(cell.r+cell.h) - dy(cell.r) }
    
    func layout() {
        cells.forEach {
            addSubview($0)
            $0.topLeft(dx: dx($0.c)+padding, dy: dy($0.r)+padding, width: width($0)-2*padding, height: height($0)-2*padding)
        }
    }
    
// UIView ==========================================================================================
    override func layoutSubviews() { layout() }
}
