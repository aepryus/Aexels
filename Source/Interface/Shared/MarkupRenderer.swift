//
//  MarkupRenderer.swift
//  Aexels
//
//  Renders a MarkupDocument into a single UIImage at a given width, using
//  the same single-bitmap approach as the legacy ArticleView.load() path.
//  This keeps the existing soft-shadow aesthetic and scroll behavior intact
//  while letting article authors write Markdown with inline LaTeX.
//

import Acheron
import SwiftMath
import UIKit

struct MarkupRenderer {
    struct Spacing {
        var paragraph: CGFloat = 16
        var heading1Top: CGFloat = 12
        var heading1Bottom: CGFloat = 8
        var heading2Top: CGFloat = 16
        var heading2Bottom: CGFloat = 8
        var displayMathTop: CGFloat = 10
        var displayMathBottom: CGFloat = 12
        var image: CGFloat = 12
        var blockQuote: CGFloat = 10
        var list: CGFloat = 12
        var codeBlock: CGFloat = 12
        var thematicBreak: CGFloat = 14
    }

    var color: UIColor
    var font: UIFont
    var italicFont: UIFont
    var spacing: Spacing = Spacing()
    var maxImageWidthRatio: CGFloat = 0.84
    var imageLeftInsetMac: CGFloat = 50
    var iPhone: Bool = Screen.iPhone

    private var s: CGFloat { Screen.s }

    func render(_ doc: MarkupDocument, contentWidth w: CGFloat) -> (image: UIImage, size: CGSize) {
        let pens = makePens()
        let blocks = doc.blocks.map { layoutBlock($0, width: w, pens: pens) }

        var totalHeight: CGFloat = 5*s
        for b in blocks { totalHeight += b.height + b.spacingAfter }

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: w, height: totalHeight))
        let image = renderer.image { ctx in
            let cgctx = ctx.cgContext
            cgctx.saveGState()
            cgctx.setShadow(offset: CGSize(width: 2*s, height: 2*s), blur: 2*s,
                            color: UIColor.black.alpha(0.2).cgColor)
            cgctx.setFillColor(UIColor.white.cgColor)

            var y: CGFloat = 5*s
            for b in blocks {
                b.draw(y, w)
                y += b.height + b.spacingAfter
            }
            cgctx.restoreGState()
        }
        return (image, CGSize(width: w, height: totalHeight))
    }

// Pens ============================================================================================
    private struct Pens {
        let body: Pen
        let italic: Pen
        let bold: Pen
        let h1: Pen
        let h2: Pen
        let code: Pen
        let caption: Pen
        let link: Pen
    }

    private func makePens() -> Pens {
        let body = Pen(font: font, color: color, alignment: .left)
        let italic = Pen(font: italicFont, color: color, alignment: .left)
        let h1Font = UIFont(name: "Optima-ExtraBlack", size: font.pointSize * 1.8) ?? font
        let h2Font = UIFont(name: "Optima", size: font.pointSize * 1.3) ?? font
        let boldFont = UIFont(name: "Optima-Bold", size: font.pointSize) ?? font
        let codeFont = UIFont(name: "Menlo", size: font.pointSize * 0.92) ?? font
        return Pens(
            body: body,
            italic: italic,
            bold: Pen(font: boldFont, color: color, alignment: .left),
            h1: Pen(font: h1Font, color: color, alignment: .left),
            h2: Pen(font: h2Font, color: color, alignment: .left),
            code: Pen(font: codeFont, color: color, alignment: .left),
            caption: Pen(font: italicFont, color: color, alignment: .center),
            link: Pen(font: font, color: color, alignment: .left)
        )
    }

// Block layout ====================================================================================
    private struct LaidBlock {
        var height: CGFloat
        var spacingAfter: CGFloat
        var draw: (_ y: CGFloat, _ width: CGFloat) -> Void
    }

    private func layoutBlock(_ block: BlockNode, width w: CGFloat, pens: Pens) -> LaidBlock {
        switch block {
            case .heading(let level, let inlines):
                return layoutHeading(level: level, inlines: inlines, width: w, pens: pens)
            case .paragraph(let inlines):
                return layoutParagraph(inlines: inlines, width: w, pens: pens)
            case .blockQuote(let blocks):
                return layoutBlockQuote(blocks: blocks, width: w, pens: pens)
            case .unorderedList(let items):
                return layoutList(items: items, ordered: false, width: w, pens: pens)
            case .orderedList(let items):
                return layoutList(items: items, ordered: true, width: w, pens: pens)
            case .codeBlock(let text):
                return layoutCodeBlock(text: text, width: w, pens: pens)
            case .displayMath(let latex):
                return layoutDisplayMath(latex: latex, width: w)
            case .image(let name, let tinted, let caption):
                return layoutImage(name: name, tinted: tinted, caption: caption, width: w, pens: pens)
            case .thematicBreak:
                return layoutThematicBreak(width: w)
        }
    }

    private func layoutHeading(level: Int, inlines: [InlineNode], width w: CGFloat, pens: Pens) -> LaidBlock {
        let pen = level <= 1 ? pens.h1 : pens.h2
        let str = attributedString(from: inlines, base: pen, pens: pens)
        let height = str.boundingRect(with: CGSize(width: w, height: .greatestFiniteMagnitude),
                                      options: .usesLineFragmentOrigin, context: nil).height
        let topPad: CGFloat = (level <= 1 ? spacing.heading1Top : spacing.heading2Top) * s
        let bottomPad: CGFloat = (level <= 1 ? spacing.heading1Bottom : spacing.heading2Bottom) * s
        return LaidBlock(height: height + topPad, spacingAfter: bottomPad) { y, _ in
            str.draw(in: CGRect(x: 0, y: y + topPad, width: w, height: height))
        }
    }

    private func layoutParagraph(inlines: [InlineNode], width w: CGFloat, pens: Pens) -> LaidBlock {
        let str = attributedString(from: inlines, base: pens.body, pens: pens)
        let height = str.boundingRect(with: CGSize(width: w, height: .greatestFiniteMagnitude),
                                      options: .usesLineFragmentOrigin, context: nil).height
        return LaidBlock(height: height, spacingAfter: spacing.paragraph * s) { y, _ in
            str.draw(in: CGRect(x: 0, y: y, width: w, height: height))
        }
    }

    private func layoutBlockQuote(blocks: [BlockNode], width w: CGFloat, pens: Pens) -> LaidBlock {
        let indent: CGFloat = 30*s
        let innerWidth = w - indent
        let italicPens = Pens(
            body: pens.italic, italic: pens.italic, bold: pens.italic,
            h1: pens.h1, h2: pens.h2, code: pens.code, caption: pens.caption, link: pens.italic
        )
        let inner = blocks.map { layoutBlock($0, width: innerWidth, pens: italicPens) }
        var totalHeight: CGFloat = 0
        for b in inner { totalHeight += b.height + b.spacingAfter }
        return LaidBlock(height: totalHeight, spacingAfter: spacing.blockQuote * s) { y, _ in
            var cursor = y
            for b in inner {
                let frame = CGRect(x: indent, y: cursor, width: innerWidth, height: b.height)
                UIGraphicsGetCurrentContext()?.saveGState()
                UIGraphicsGetCurrentContext()?.translateBy(x: indent, y: 0)
                b.draw(cursor, innerWidth)
                UIGraphicsGetCurrentContext()?.restoreGState()
                _ = frame
                cursor += b.height + b.spacingAfter
            }
        }
    }

    private func layoutList(items: [[BlockNode]], ordered: Bool, width w: CGFloat, pens: Pens) -> LaidBlock {
        let bulletWidth: CGFloat = 24*s
        let innerWidth = w - bulletWidth
        struct LaidItem { var bullet: NSAttributedString; var blocks: [LaidBlock]; var height: CGFloat }
        var laid: [LaidItem] = []
        for (idx, item) in items.enumerated() {
            let blocks = item.map { layoutBlock($0, width: innerWidth, pens: pens) }
            var h: CGFloat = 0
            for b in blocks { h += b.height + b.spacingAfter }
            let bulletText = ordered ? "\(idx + 1)." : "•"
            let bullet = NSAttributedString(string: bulletText, attributes: pens.body.attributes)
            laid.append(LaidItem(bullet: bullet, blocks: blocks, height: h))
        }
        let total: CGFloat = laid.reduce(0) { $0 + $1.height }
        let bulletWidth_ = bulletWidth
        let body = pens.body
        return LaidBlock(height: total, spacingAfter: spacing.list * s) { y, _ in
            var cursor = y
            for item in laid {
                let bulletRect = CGRect(x: 0, y: cursor, width: bulletWidth_, height: 22*Screen.s)
                item.bullet.draw(in: bulletRect)
                _ = body
                var inner = cursor
                for b in item.blocks {
                    UIGraphicsGetCurrentContext()?.saveGState()
                    UIGraphicsGetCurrentContext()?.translateBy(x: bulletWidth_, y: 0)
                    b.draw(inner, w - bulletWidth_)
                    UIGraphicsGetCurrentContext()?.restoreGState()
                    inner += b.height + b.spacingAfter
                }
                cursor += item.height
            }
        }
    }

    private func layoutCodeBlock(text: String, width w: CGFloat, pens: Pens) -> LaidBlock {
        let pad: CGFloat = 8*s
        let inner = w - 2*pad
        let str = NSAttributedString(string: text, attributes: pens.code.attributes)
        let textHeight = str.boundingRect(with: CGSize(width: inner, height: .greatestFiniteMagnitude),
                                          options: .usesLineFragmentOrigin, context: nil).height
        let height = textHeight + 2*pad
        return LaidBlock(height: height, spacingAfter: spacing.codeBlock * s) { y, _ in
            let rect = CGRect(x: 0, y: y, width: w, height: height)
            UIColor.black.alpha(0.05).setFill()
            UIBezierPath(roundedRect: rect, cornerRadius: 4*Screen.s).fill()
            str.draw(in: CGRect(x: pad, y: y + pad, width: inner, height: textHeight))
        }
    }

    private func layoutDisplayMath(latex: String, width w: CGFloat) -> LaidBlock {
        var img = MathImage(latex: latex, fontSize: font.pointSize * 1.1, textColor: color, labelMode: .display, textAlignment: .center)
        let (_, mathImage, _) = img.asImage()
        let mImg = mathImage
        let topPad: CGFloat = spacing.displayMathTop * s
        let bottomPad: CGFloat = spacing.displayMathBottom * s
        guard let mImg else {
            return LaidBlock(height: topPad, spacingAfter: bottomPad) { _, _ in }
        }
        let height = mImg.size.height + topPad
        // Display math is positioned to match the existing image convention:
        // left-indented on Mac (so it lines up with how rendered-LaTeX PNGs
        // used to sit), flush left on iPhone where width is precious.
        let xOffset: CGFloat = iPhone ? 0 : imageLeftInsetMac * s
        return LaidBlock(height: height, spacingAfter: bottomPad) { y, _ in
            mImg.draw(in: CGRect(x: xOffset, y: y + topPad, width: mImg.size.width, height: mImg.size.height))
        }
    }

    private func layoutImage(name: String, tinted: Bool, caption: [InlineNode]?, width w: CGFloat, pens: Pens) -> LaidBlock {
        guard var image = UIImage(named: name) else {
            return LaidBlock(height: 0, spacingAfter: 0) { _, _ in }
        }
        if tinted { image = image.withTintColor(color) }
        let drawWidth = min(image.size.width, w * maxImageWidthRatio)
        let ratio = drawWidth / image.size.width
        let drawHeight = image.size.height * ratio
        let xOffset: CGFloat = iPhone ? 0 : imageLeftInsetMac * s
        let captionStr: NSAttributedString? = caption.flatMap { caps in
            let s = attributedString(from: caps, base: pens.caption, pens: pens)
            return s.length == 0 ? nil : s
        }
        let captionHeight = captionStr?.boundingRect(with: CGSize(width: w, height: .greatestFiniteMagnitude),
                                                     options: .usesLineFragmentOrigin, context: nil).height ?? 0
        let captionGap: CGFloat = captionStr == nil ? 0 : 4*s
        let total = drawHeight + captionGap + captionHeight
        let drawingImage = image
        return LaidBlock(height: total, spacingAfter: spacing.image * s) { y, _ in
            drawingImage.draw(in: CGRect(x: xOffset, y: y, width: drawWidth, height: drawHeight))
            if let captionStr {
                captionStr.draw(in: CGRect(x: 0, y: y + drawHeight + captionGap, width: w, height: captionHeight))
            }
        }
    }

    private func layoutThematicBreak(width w: CGFloat) -> LaidBlock {
        let height: CGFloat = 1
        return LaidBlock(height: height, spacingAfter: spacing.thematicBreak * s) { y, _ in
            let rect = CGRect(x: w * 0.2, y: y, width: w * 0.6, height: 1)
            UIColor.black.alpha(0.2).setFill()
            UIRectFill(rect)
        }
    }

// Inline composition ==============================================================================
    private func attributedString(from inlines: [InlineNode], base: Pen, pens: Pens) -> NSAttributedString {
        let out = NSMutableAttributedString()
        for node in inlines { append(node, into: out, pen: base, pens: pens) }
        return out
    }

    private func append(_ node: InlineNode, into out: NSMutableAttributedString, pen: Pen, pens: Pens) {
        switch node {
            case .text(let s):
                out.append(NSAttributedString(string: s, attributes: pen.attributes))
            case .strong(let inner):
                let bold = pens.bold
                for n in inner { append(n, into: out, pen: bold, pens: pens) }
            case .emphasis(let inner):
                let it = pens.italic
                for n in inner { append(n, into: out, pen: it, pens: pens) }
            case .code(let s):
                out.append(NSAttributedString(string: s, attributes: pens.code.attributes))
            case .link(_, let inner):
                let lp = pens.link
                for n in inner { append(n, into: out, pen: lp, pens: pens) }
            case .math(let latex, let display):
                appendMath(latex: latex, display: display, into: out, pen: pen)
            case .lineBreak:
                out.append(NSAttributedString(string: "\n", attributes: pen.attributes))
            case .softBreak:
                out.append(NSAttributedString(string: " ", attributes: pen.attributes))
        }
    }

    private func appendMath(latex: String, display: Bool, into out: NSMutableAttributedString, pen: Pen) {
        var img = MathImage(latex: latex, fontSize: pen.font.pointSize * (display ? 1.1 : 1.0),
                            textColor: pen.color, labelMode: display ? .display : .text, textAlignment: .center)
        let (_, mathImage, info) = img.asImage()
        guard let mathImage else {
            out.append(NSAttributedString(string: "[\(latex)]", attributes: pen.attributes))
            return
        }
        let attachment = NSTextAttachment()
        attachment.image = mathImage
        let descent = info?.descent ?? 0
        attachment.bounds = CGRect(x: 0, y: -descent, width: mathImage.size.width, height: mathImage.size.height)
        out.append(NSAttributedString(attachment: attachment))
    }
}
