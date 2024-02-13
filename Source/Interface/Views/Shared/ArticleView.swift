//
//  ArticleView.swift
//  Aexels
//
//  Created by Joe Charlier on 2/12/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

import Acheron
import UIKit

class ArticleView: AEView {
    var key: String? {
        didSet { load() }
    }
    
    var scrollView: UIScrollView? = nil
    let imageView: UIImageView = UIImageView()
    var scrollViewContentSize: CGSize = .zero
    
    override init() {
        super.init()
//        self.backgroundColor = .green.alpha(0.1)
//        self.imageView.backgroundColor = .blue.alpha(0.1)
        addSubview(imageView)
    }
    
    func load() {
        guard let key else { return }
        let template = "\(key)_article".localized
        var texts: [String] = []
        var images: [UIImage] = []

        var i: Int = 0
        while i < template.count {
            if let left: Int = template.loc(of: "<<", after: i), let right: Int = template.loc(of: ">>", after: left) {
                texts.append(template[i...left-1])
                images.append(UIImage(named: template[left+2...right-1])!.withTintColor(.black.tint(0.4)))
                i = right+2
            } else {
                texts.append(template[i...template.count-1])
                i = template.count
            }
        }

        let p: CGFloat = 10*s
        let width: CGFloat = 500*s
        let w = width - p*2
        var y: CGFloat = 0
        var tHs: [CGFloat] = []
        var iHs: [CGFloat] = []

        var h: CGFloat = 0

        let pen = Pen(font: .optima(size: 16*s), color: .black.tint(0.4), alignment: .left)

        for i in 0..<texts.count {
            let height: CGFloat = texts[i].boundingRect(with: CGSize(width: w, height: 19999), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: pen.attributes, context: nil).size.height
            h += height
            tHs.append(height)
            if i < images.count {
                let w: CGFloat = min(images[i].size.width, width * 0.84)
                let r: CGFloat = w / images[i].size.width
                let height: CGFloat = images[i].size.height * r
                h += height
                iHs.append(height)
            }
        }

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: w, height: h))
        let image = renderer.image { (_: UIGraphicsImageRendererContext) in
            guard let c = UIGraphicsGetCurrentContext() else { return }
            c.saveGState()
            c.setShadow(offset: CGSize(width: 2*s, height: 2*s), blur: 2*s, color: UIColor.black.alpha(0.2).cgColor)
            c.setFillColor(UIColor.white.cgColor)

            for i in 0..<texts.count {
                texts[i].draw(in: CGRect(x: 0, y: y, width: w, height: tHs[i]), pen: pen)
                y += tHs[i]
                if i < images.count {
                    let w: CGFloat = min(images[i].size.width, width * 0.84)
                    let r: CGFloat = w / images[i].size.width
                    let size: CGSize = CGSize(width: images[i].size.width * r, height: images[i].size.height * r)
                    images[i].draw(in: CGRect(origin: CGPoint(x: Screen.iPhone ? 0 : 50*s, y: y), size: size))
                    y += iHs[i]
                }
            }

            c.restoreGState()
        }
                
        imageView.frame = CGRect(x: p, y: p, width: w, height: h)
        imageView.image = image

        imageView.frame = CGRect(x: p, y: p, width: w, height: h)
        imageView.image = image

        if let scrollView {
            scrollViewContentSize = CGSize(width: w+2*p, height: max(h+2*p, scrollView.bounds.size.height+1))
        }
    }
}
