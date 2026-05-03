//
//  Markup.swift
//  Aexels
//
//  Article markup AST and parser. Source files are CommonMark Markdown
//  (parsed via swift-markdown) with three custom conventions:
//
//      $$...$$        display math (LaTeX)
//      $...$          inline math (LaTeX)
//      ![](tint:Foo)  tinted image (rendered with the article color)
//      ![](Foo)       full-color image (rendered as-is)
//      [Label](article://key)  cross-article link
//

import Foundation
import Markdown

enum BlockNode {
    case heading(level: Int, inlines: [InlineNode])
    case paragraph([InlineNode])
    case blockQuote([BlockNode])
    case unorderedList([[BlockNode]])
    case orderedList([[BlockNode]])
    case codeBlock(String)
    case displayMath(String)
    case image(name: String, tinted: Bool, caption: [InlineNode]?)
    case thematicBreak
}

enum InlineNode {
    case text(String)
    case strong([InlineNode])
    case emphasis([InlineNode])
    case code(String)
    case link(target: String, inlines: [InlineNode])
    case math(latex: String, display: Bool)
    case lineBreak
    case softBreak
}

struct MarkupDocument {
    let blocks: [BlockNode]
}

enum MarkupParser {

    static func parse(_ source: String) -> MarkupDocument {
        let (sanitized, math) = extractMath(from: source)
        let document = Document(parsing: sanitized)
        let converter = ASTConverter(math: math)
        var blocks: [BlockNode] = []
        for child in document.children { if let b = converter.convertBlock(child) { blocks.append(b) } }
        return MarkupDocument(blocks: blocks)
    }

// Math pre-pass ===================================================================================
    // CommonMark has no notion of math, so we extract $$...$$ and $...$ runs
    // before parsing and replace them with sentinel tokens built from
    // Private Use Area characters. Those tokens survive Markdown parsing
    // intact and are re-expanded into math nodes when walking the AST.

    static let mathOpenSentinel: Character = "\u{E000}"
    static let mathCloseSentinel: Character = "\u{E001}"

    static func extractMath(from source: String) -> (sanitized: String, math: [(display: Bool, latex: String)]) {
        var math: [(Bool, String)] = []
        var out = ""
        var i = source.startIndex
        while i < source.endIndex {
            if source[i] == "$" && !isEscaped(at: i, in: source) {
                let after = source.index(after: i)
                let isDisplay = after < source.endIndex && source[after] == "$"
                let openLen = isDisplay ? 2 : 1
                let bodyStart = source.index(i, offsetBy: openLen)
                if let closeStart = findMathClose(in: source, from: bodyStart, isDisplay: isDisplay) {
                    let latex = String(source[bodyStart..<closeStart])
                    let id = math.count
                    math.append((isDisplay, latex))
                    out.append(mathOpenSentinel)
                    out.append(isDisplay ? "D" : "I")
                    out.append(contentsOf: String(id))
                    out.append(mathCloseSentinel)
                    i = source.index(closeStart, offsetBy: openLen)
                    continue
                }
            }
            out.append(source[i])
            i = source.index(after: i)
        }
        return (out, math)
    }

    private static func isEscaped(at index: String.Index, in source: String) -> Bool {
        guard index > source.startIndex else { return false }
        let prev = source.index(before: index)
        return source[prev] == "\\"
    }

    private static func findMathClose(in source: String, from start: String.Index, isDisplay: Bool) -> String.Index? {
        var i = start
        while i < source.endIndex {
            let c = source[i]
            // Inline math doesn't span line breaks
            if c == "\n" && !isDisplay { return nil }
            if c == "$" && !isEscaped(at: i, in: source) {
                if isDisplay {
                    let next = source.index(after: i)
                    if next < source.endIndex && source[next] == "$" { return i }
                } else {
                    return i
                }
            }
            i = source.index(after: i)
        }
        return nil
    }
}

// AST conversion ==================================================================================
// Walks the swift-markdown tree and produces our simpler BlockNode/InlineNode
// AST. Math sentinels embedded in Text nodes are split out into math nodes
// during inline conversion. A paragraph whose only meaningful child is a
// display-math run (or a single image) is promoted to a standalone block.

private struct ASTConverter {
    let math: [(display: Bool, latex: String)]

    func convertBlock(_ markup: any Markup) -> BlockNode? {
        switch markup {
            case let h as Heading:
                return .heading(level: h.level, inlines: convertInlines(h))
            case let p as Paragraph:
                if let imageBlock = imageOnlyParagraph(p) { return imageBlock }
                let inlines = convertInlines(p)
                return promotedParagraph(inlines) ?? .paragraph(inlines)
            case let bq as BlockQuote:
                return .blockQuote(bq.children.compactMap { convertBlock($0) })
            case let ul as UnorderedList:
                let items: [[BlockNode]] = ul.children.compactMap { ($0 as? ListItem).map { $0.children.compactMap(convertBlock) } }
                return .unorderedList(items)
            case let ol as OrderedList:
                let items: [[BlockNode]] = ol.children.compactMap { ($0 as? ListItem).map { $0.children.compactMap(convertBlock) } }
                return .orderedList(items)
            case let cb as CodeBlock:
                return .codeBlock(cb.code)
            case _ as ThematicBreak:
                return .thematicBreak
            default:
                return nil
        }
    }

    // Detect "block-only" paragraphs and unwrap them. CommonMark wraps a
    // standalone display-math run, or a standalone image, in a Paragraph;
    // we want them as top-level blocks so the renderer can lay them out
    // without flowing them into a text run.
    // Paragraphs whose only meaningful child is an image (with whitespace
    // text or breaks around it) should be promoted to a block-level image
    // so the renderer can size and center it instead of trying to flow it
    // inline. Image title attributes (![alt](url "title")) become captions.
    private func imageOnlyParagraph(_ p: Paragraph) -> BlockNode? {
        var image: Markdown.Image?
        for child in p.children {
            switch child {
                case let img as Markdown.Image:
                    if image != nil { return nil }
                    image = img
                case let t as Markdown.Text:
                    if !t.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return nil }
                case _ as SoftBreak, _ as LineBreak:
                    continue
                default:
                    return nil
            }
        }
        guard let img = image,
              let url = img.source,
              let ref = MarkupImageRef(url: url) else { return nil }
        let captionInlines: [InlineNode]?
        if let title = img.title, !title.isEmpty { captionInlines = [.text(title)] }
        else { captionInlines = nil }
        return .image(name: ref.name, tinted: ref.tinted, caption: captionInlines)
    }

    private func promotedParagraph(_ inlines: [InlineNode]) -> BlockNode? {
        let meaningful = inlines.filter {
            switch $0 {
                case .text(let t): return !t.trimmingCharacters(in: .whitespaces).isEmpty
                case .softBreak, .lineBreak: return false
                default: return true
            }
        }
        if meaningful.count == 1, case .math(let latex, true) = meaningful[0] {
            return .displayMath(latex)
        }
        if meaningful.count == 1, case .link(let target, let inner) = meaningful[0],
           let img = MarkupImageRef(url: target) {
            // [![](image)](article://...) form not supported yet; fall through
            _ = inner
            _ = img
        }
        return nil
    }

    private func convertInlines(_ parent: any Markup) -> [InlineNode] {
        var out: [InlineNode] = []
        for child in parent.children { appendInline(child, into: &out) }
        return out
    }

    private func appendInline(_ markup: any Markup, into out: inout [InlineNode]) {
        switch markup {
            case let t as Markdown.Text:
                out.append(contentsOf: expandMathSentinels(in: t.string))
            case let s as Strong:
                out.append(.strong(convertInlines(s)))
            case let e as Emphasis:
                out.append(.emphasis(convertInlines(e)))
            case let c as InlineCode:
                out.append(.code(c.code))
            case let l as Markdown.Link:
                out.append(.link(target: l.destination ?? "", inlines: convertInlines(l)))
            case let img as Markdown.Image:
                // An image used inline (rather than as its own paragraph). We
                // don't currently have a great rendering for this, so we fall
                // back to alt text. Block-level images are detected and
                // promoted in promotedParagraph.
                let alt = img.plainText
                if !alt.isEmpty { out.append(.text(alt)) }
            case _ as LineBreak:
                out.append(.lineBreak)
            case _ as SoftBreak:
                out.append(.softBreak)
            default:
                // Fall back to plain text for any other inline node type.
                out.append(.text(markup.format()))
        }
    }

    private func expandMathSentinels(in raw: String) -> [InlineNode] {
        guard raw.contains(MarkupParser.mathOpenSentinel) else { return [.text(raw)] }
        var nodes: [InlineNode] = []
        var literal = ""
        var i = raw.startIndex
        while i < raw.endIndex {
            if raw[i] == MarkupParser.mathOpenSentinel {
                let modeIndex = raw.index(after: i)
                if modeIndex < raw.endIndex,
                   let closeIndex = raw[modeIndex...].firstIndex(of: MarkupParser.mathCloseSentinel) {
                    if !literal.isEmpty { nodes.append(.text(literal)); literal = "" }
                    let mode = raw[modeIndex]
                    let idStart = raw.index(after: modeIndex)
                    let idStr = String(raw[idStart..<closeIndex])
                    if let id = Int(idStr), id < math.count {
                        let entry = math[id]
                        let isDisplay = (mode == "D") || entry.display
                        nodes.append(.math(latex: entry.latex, display: isDisplay))
                    }
                    i = raw.index(after: closeIndex)
                    continue
                }
            }
            literal.append(raw[i])
            i = raw.index(after: i)
        }
        if !literal.isEmpty { nodes.append(.text(literal)) }
        return nodes
    }
}

// Image and link URL conventions ==================================================================
// Markdown's image syntax is ![alt](url) and link is [label](url). We use the
// URL slot to encode our app-specific behaviors so source files remain valid
// CommonMark documents.
//
//      ![](tint:Photon)         tinted image (current article color)
//      ![](Photon)              full-color image
//      [Aether](article://aether)   cross-article link
//

struct MarkupImageRef {
    let name: String
    let tinted: Bool

    init?(url: String) {
        if url.hasPrefix("tint:") {
            self.name = String(url.dropFirst("tint:".count))
            self.tinted = true
        } else if !url.contains("://") && !url.hasPrefix("article:") {
            // Treat any non-scheme URL as a bundled asset name.
            self.name = url
            self.tinted = false
        } else {
            return nil
        }
    }
}

struct MarkupArticleLink {
    let key: String
    init?(url: String) {
        guard url.hasPrefix("article://") else { return nil }
        self.key = String(url.dropFirst("article://".count))
    }
}
