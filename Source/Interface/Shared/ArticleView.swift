//
//  ArticleView.swift
//  Aexels
//
//  Created by Joe Charlier on 2/12/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

import Acheron
import PDFKit
import UIKit

class ArticleView: AEView {
    var key: String? {
        didSet {
            if let key, key.hasSuffix("_pdf") { loadPDF() }
            else { load() }
        }
    }
    weak var scrollView: UIScrollView? = nil
    var color: UIColor = .black.tint(0.4)
    var font: UIFont = .optima(size: 16*Screen.s)
    var italicFont: UIFont = .optimaItalic(size: 13*Screen.s)
    
    private let imageView: UIImageView = UIImageView()
    private let pdfView: PDFView = PDFView()
    
    var scrollViewContentSize: CGSize = .zero
    var maxWidth: CGFloat? = nil
    
    override init() {
        super.init()
        addSubview(imageView)
        addSubview(pdfView)
        
        pdfView.isHidden = true
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.backgroundColor = .clear
    }
    
    func loadPDF() {
        guard let key else { return }
        imageView.isHidden = true
        pdfView.isHidden = false
        
        let pathString: String = key[...(key.count-5)]
        if let path = Bundle.main.url(forResource: pathString, withExtension: "pdf"),
           let document = PDFDocument(url: path),
           let firstPage = document.page(at: 0) {
            
            pdfView.document = document
            
            
            let pageSize = firstPage.bounds(for: .mediaBox).size
            let ratio = pageSize.height / pageSize.width
            let width: CGFloat = 770
            let totalHeight = width * ratio * CGFloat(document.pageCount)
            
            
            pdfView.frame = CGRect(origin: .zero, size: CGSize(width: width, height: totalHeight))
            
            scrollViewContentSize = pdfView.bounds.size
        }
    }
    
    func loadOld() {
        imageView.isHidden = false
        pdfView.isHidden = true
        
        guard let key else { return }
        let template = "\(key)_article".localized
        var texts: [String] = []
        var images: [UIImage] = []
        
        let indentWidth: CGFloat = 30*s
        
        var i: Int = 0
        while i < template.count {
            let leftA: Int? = template.loc(of: "<<", after: i)
            let leftB: Int? = template.loc(of: "{{", after: i)
            let leftC: Int? = template.loc(of: "**", after: i)
            
            let markers = [leftA, leftB, leftC].compactMap { $0 }
            guard let closest = markers.min() else {
                texts.append(template[i...template.count-1])
                i = template.count
                continue
            }
            
            if let leftC, closest == leftC, let right: Int = template.loc(of: "**", after: leftC + 2) {
                texts.append(template[i...leftC-1])
                texts.append("§" + template[leftC+2...right-1] + "§")
                i = right + 2
            } else if let leftA, closest == leftA, let right: Int = template.loc(of: ">>", after: leftA) {
                texts.append(template[i...leftA-1])
                images.append(UIImage(named: template[leftA+2...right-1])!.withTintColor(color))
                i = right+2
            } else if let leftB, closest == leftB, let right: Int = template.loc(of: "}}", after: leftB) {
                texts.append(template[i...leftB-1])
                images.append(UIImage(named: template[leftB+2...right-1])!)
                i = right+2
            } else {
                texts.append(template[i...template.count-1])
                i = template.count
            }
        }
        
        let p: CGFloat = 10*s
        let width: CGFloat
        if let scrollView {
            if let maxWidth { width = min(scrollView.width - (Screen.iPhone ? 0 : 2*p), maxWidth) }
            else { width = scrollView.width - 2*p }
        } else {
            width = 500*s
        }
        
        let w = width - p*2
        var y: CGFloat = 5*s
        var tHs: [CGFloat] = []
        var iHs: [CGFloat] = []
        
        var h: CGFloat = y
        
        let pen = Pen(font: font, color: color, alignment: .left)
        let italicPen = Pen(font: italicFont, color: color, alignment: .left)
        
        for i in 0..<texts.count {
            let height: CGFloat
            if texts[i].hasPrefix("§") && texts[i].hasSuffix("§") {
                height = texts[i].boundingRect(with: CGSize(width: w - indentWidth, height: 19999), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: italicPen.attributes, context: nil).size.height
                h += height
            } else {
                height = texts[i].boundingRect(with: CGSize(width: w, height: 19999), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: pen.attributes, context: nil).size.height
                h += height
            }
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
                if texts[i].hasPrefix("§") && texts[i].hasSuffix("§") {
                    let styledText = String(texts[i].dropFirst().dropLast())
                    styledText.draw(in: CGRect(x: indentWidth, y: y, width: w-indentWidth, height: tHs[i]), pen: italicPen)
                } else {
                    texts[i].draw(in: CGRect(x: 0, y: y, width: w, height: tHs[i]), pen: pen)
                }
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
        
        if let scrollView { scrollViewContentSize = CGSize(width: w+2*p, height: max(h+2*p, scrollView.bounds.size.height+1)) }
    }
    
    func load() {
        imageView.isHidden = false
        pdfView.isHidden = true
        
        guard let key else { return }
        let template = "\(key)_article".localized
        var texts: [String] = []
        var textTypes: [String] = []
        var images: [UIImage] = []
        var imageHasCaptions: [Bool] = []
        
        let indentWidth: CGFloat = 30*s
        
        var i: Int = 0
        while i < template.count {
            let leftA: Int? = template.loc(of: "<<", after: i)
            let leftB: Int? = template.loc(of: "{{", after: i)
            let leftC: Int? = template.loc(of: "**", after: i)
            let leftD: Int? = template.loc(of: "#[", after: i)
            let leftE: Int? = template.loc(of: "##[", after: i)
            
            let markers = [leftA, leftB, leftC, leftD, leftE].compactMap { $0 }
            guard let closest = markers.min() else {
                texts.append(template[i...template.count-1])
                textTypes.append("normal")
                i = template.count
                continue
            }
            
            if i < closest {
                texts.append(template[i...closest-1])
                textTypes.append("normal")
            }
            
            if let leftD, closest == leftD, let right: Int = template.loc(of: "]#", after: leftD + 2) {
                texts.append(template[leftD+2...right-1])
                textTypes.append("h1")
                i = right + 2
            } else if let leftE, closest == leftE, let right: Int = template.loc(of: "]##", after: leftE + 3) {
                texts.append(template[leftE+3...right-1])
                textTypes.append("h2")
                i = right + 3
            } else if let leftC, closest == leftC, let right: Int = template.loc(of: "**", after: leftC + 2) {
                if !images.isEmpty && images.count > imageHasCaptions.count {
                    texts.append("")
                    textTypes.append("skip")
                    imageHasCaptions.append(true)
                    texts.append(template[leftC+2...right-1])
                    textTypes.append("caption")
                } else {
                    texts.append(template[leftC+2...right-1])
                    textTypes.append("indented")
                }
                i = right + 2
            } else if let leftA, closest == leftA, let right: Int = template.loc(of: ">>", after: leftA) {
                texts.append("")
                textTypes.append("skip")
                images.append(UIImage(named: template[leftA+2...right-1])!.withTintColor(color))
                imageHasCaptions.append(false)
                i = right+2
            } else if let leftB, closest == leftB, let right: Int = template.loc(of: "}}", after: leftB) {
                texts.append("")
                textTypes.append("skip")
                images.append(UIImage(named: template[leftB+2...right-1])!)
                imageHasCaptions.append(false)
                i = right+2
            } else {
                texts.append(template[i...template.count-1])
                textTypes.append("normal")
                i = template.count
            }
        }
        
        let p: CGFloat = 10*s
        let width: CGFloat
        if let scrollView {
            if let maxWidth { width = min(scrollView.width - (Screen.iPhone ? 0 : 2*p), maxWidth) }
            else { width = scrollView.width - 2*p }
        } else {
            width = 500*s
        }
        
        let w = width - p*2
        var tHs: [CGFloat] = []
        var iHs: [CGFloat] = []
        
        let pen = Pen(font: font, color: color, alignment: .left)
        let italicPen = Pen(font: italicFont, color: color, alignment: .left)
        let captionPen = Pen(font: italicFont, color: color, alignment: .center)
        
        let h1Pen = Pen(
            font: UIFont(name: "Optima-ExtraBlack", size: font.pointSize * 1.8)!,
            color: color,
            alignment: .left
        )

        let h2Pen = Pen(
            font: UIFont(name: "Optima", size: font.pointSize * 1.3)!,
            color: color,
            alignment: .left
        )
        
        // Calculate heights for text elements
        for i in 0..<texts.count {
            if textTypes[i] == "skip" {
                tHs.append(0)
                continue
            }
            
            let height: CGFloat
            if textTypes[i] == "caption" {
                height = texts[i].boundingRect(with: CGSize(width: w, height: 19999),
                                               options: .usesLineFragmentOrigin,
                                               attributes: captionPen.attributes,
                                               context: nil).size.height + 5*s
            } else if textTypes[i] == "indented" {
                height = texts[i].boundingRect(with: CGSize(width: w - indentWidth, height: 19999),
                                               options: .usesLineFragmentOrigin,
                                               attributes: italicPen.attributes,
                                               context: nil).size.height + 2*s
            } else if textTypes[i] == "h1" {
                height = texts[i].boundingRect(with: CGSize(width: w, height: 19999),
                                               options: .usesLineFragmentOrigin,
                                               attributes: h1Pen.attributes,
                                               context: nil).size.height + 15*s
            } else if textTypes[i] == "h2" {
                height = texts[i].boundingRect(with: CGSize(width: w, height: 19999),
                                               options: .usesLineFragmentOrigin,
                                               attributes: h2Pen.attributes,
                                               context: nil).size.height + 8*s
            } else {
                height = texts[i].boundingRect(with: CGSize(width: w, height: 19999),
                                               options: .usesLineFragmentOrigin,
                                               attributes: pen.attributes,
                                               context: nil).size.height
            }
            tHs.append(height)
        }
        
        // Calculate image heights
        for i in 0..<images.count {
            let imageWidth = min(images[i].size.width, width * 0.84)
            let ratio = imageWidth / images[i].size.width
            let height = images[i].size.height * ratio
            iHs.append(height)
        }
        
        // Calculate total height
        var totalHeight: CGFloat = 5*s
        for height in tHs {
            totalHeight += height
        }
        for height in iHs {
            totalHeight += height
        }
        
        // Render to image
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: w, height: totalHeight))
        let image = renderer.image { (_: UIGraphicsImageRendererContext) in
            guard let c = UIGraphicsGetCurrentContext() else { return }
            c.saveGState()
            c.setShadow(offset: CGSize(width: 2*s, height: 2*s), blur: 2*s, color: UIColor.black.alpha(0.2).cgColor)
            c.setFillColor(UIColor.white.cgColor)
            
            var y: CGFloat = 5*s
            var nextImageIndex = 0
            
            for i in 0..<texts.count {
                if textTypes[i] == "skip" {
                    // This is a placeholder for an image
                    if nextImageIndex < images.count {
                        let imgW: CGFloat = min(images[nextImageIndex].size.width, width * 0.84)
                        let r: CGFloat = imgW / images[nextImageIndex].size.width
                        let size: CGSize = CGSize(width: images[nextImageIndex].size.width * r, height: images[nextImageIndex].size.height * r)
                        let xOffset = Screen.iPhone ? 0 : 50*s
                        images[nextImageIndex].draw(in: CGRect(origin: CGPoint(x: xOffset, y: y), size: size))
                        y += iHs[nextImageIndex]
                        
                        nextImageIndex += 1
                    }
                } else if textTypes[i] == "caption" {
                    // Center the caption under the image
                    texts[i].draw(in: CGRect(x: 0, y: y, width: w, height: tHs[i] - 5*s), pen: captionPen)
                    y += tHs[i]
                } else if textTypes[i] == "indented" {
                    texts[i].draw(in: CGRect(x: indentWidth, y: y, width: w-indentWidth, height: tHs[i] - 2*s), pen: italicPen)
                    y += tHs[i]
                } else if textTypes[i] == "h1" {
                    texts[i].draw(in: CGRect(x: 0, y: y, width: w, height: tHs[i] - 15*s), pen: h1Pen)
                    y += tHs[i]
                } else if textTypes[i] == "h2" {
                    texts[i].draw(in: CGRect(x: 0, y: y, width: w, height: tHs[i] - 8*s), pen: h2Pen)
                    y += tHs[i]
                } else {
                    // Normal text
                    texts[i].draw(in: CGRect(x: 0, y: y, width: w, height: tHs[i]), pen: pen)
                    y += tHs[i]
                }
            }
            
            c.restoreGState()
        }
        
        imageView.frame = CGRect(x: p, y: p, width: w, height: totalHeight)
        imageView.image = image
        
        if let scrollView {
            scrollViewContentSize = CGSize(width: w+2*p, height: max(totalHeight+2*p, scrollView.bounds.size.height+1))
        }
    }
}
