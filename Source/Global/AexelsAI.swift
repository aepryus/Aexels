//
//  AexelsAI.swift
//  Aexels
//
//  Created by Joe Charlier on 11/8/26.
//  Copyright © 2026 Aepryus Software. All rights reserved.
//
//  Aexels's AI: OoviumKit's tray, a limbo panel that slides in down the right over whatever is on show, opened
//  by the Claude circle beside the vision bar. What it knows of Aexels is its AI Reference, written from Aexels's
//  code, its sims and its articles (Resources/AI Reference.md; update it before a release). It's there to explain
//  and explore Universe X with the person, and to push back. It's paid in the Aepryus account's credits; its
//  conversation is kept in the basket under "chatIden".
//

import Acheron
import OoviumKit
import UIKit

enum AexelsAI {
    static let tray: AITray = AITray(feature: "aexels.tray", instructions: instructions, tools: [], chat: chat, style: LimboStyle())
    /// The circle that opens and closes it: Claude's starburst, as the Nexus's copy button has it.
    static let button: CircleButton = {
        let image: UIImageView = UIImageView(image: UIImage(named: "claude")!.withTintColor(.white.shade(0.15)))
        image.contentMode = .scaleAspectFit
        image.bounds = CGRect(x: 0, y: 0, width: 18*Screen.s, height: 18*Screen.s)
        let button: CircleButton = CircleButton(view: image)
        button.addAction { toggle() }
        return button
    }()
    private(set) static var open: Bool = false

    /// The conversation so far, kept between launches.
    private static var chat: AIChat {
        if let iden: String = Loom.get(key: "chatIden"), let chat: AIChat = Loom.selectBy(iden: iden) { return chat }
        var chat: AIChat!
        Loom.transact { chat = Loom.create() }
        Loom.set(key: "chatIden", value: chat.iden)
        return chat
    }

    /// In from the right, or back out; the explorer under it carries on.
    static func toggle() {
        guard let view: UIView = Aexels.explorerViewController.view else { return }
        open.toggle()
        if tray.superview == nil {
            // the limbo panels' shadow
            tray.layer.shadowColor = UIColor.black.cgColor
            tray.layer.shadowOffset = .zero
            tray.layer.shadowRadius = 3*Screen.s
            tray.layer.shadowOpacity = 0.6
            place(in: view, open: false)
            view.addSubview(tray)
        }
        view.bringSubviewToFront(tray)
        if !open { tray.onClose() }
        UIView.animate(withDuration: 0.25) {
            place(in: view, open: open)
        } completion: { (_: Bool) in
            if open { tray.onOpen() }
        }
    }
    /// Down the right, under the vision bar and its circle; out past the edge when closed.
    static func place(in view: UIView, open: Bool) {
        let s: CGFloat = Screen.s
        let w: CGFloat = min(380*s, view.bounds.width - 12*s)
        let top: CGFloat = Screen.safeTop + 52*s
        tray.frame = CGRect(x: open ? view.bounds.width - w - 6*s : view.bounds.width + 6*s, y: top, width: w, height: view.bounds.height - top - Screen.safeBottom - 6*s)
        tray.layer.shadowPath = CGPath(roundedRect: tray.bounds, cornerWidth: 10*s, cornerHeight: 10*s, transform: nil)
    }

    private static var instructions: String {
        let reference: String = Bundle.main.url(forResource: "AI Reference", withExtension: "md").flatMap { try? String(contentsOf: $0, encoding: .utf8) } ?? ""
        return """
        You are the AI inside Aexels, Aepryus Software's app about Universe X: a universe made only of a quantized aether, whose quanta are aexels, built to be entirely mechanistic, with no magic, and still match every experiment of our own. The app explores it through its simulations (the explorers) and its articles. You explain and explore its concepts with the person: what Universe X proposes, why, what each simulation shows and how it works, and how it compares with our physics.

        Be a good partner in thinking, not a cheerleader. Take its hypotheticals seriously and reason inside them; and push back where an argument is weak, where a claim goes further than a simulation shows, or where Universe X would have to answer an experiment of our own, saying plainly what mainstream physics holds and why. Keep apart what the app's code does, what its articles argue, and what is established physics.

        The reference below was written from Aexels's code, its research sims and its articles. Go by it. When it doesn't cover something, say so rather than guess.

        Write plain text, never Markdown: short paragraphs, no headings, no bold, a numbered list only for steps. Be brief unless asked to go deeper.

        <reference>
        \(reference)
        </reference>
        """
    }
}

/// The tray as Aexels's limbo panels are: dark glass edged in grey, the AI's words in white and the person's in
/// a pale blue, in Optima.
final class LimboStyle: AIStyle {
    override var printed: UIColor { UIColor(white: 0.92, alpha: 1) }
    override var typed: UIColor { UIColor(red: 0.62, green: 0.80, blue: 1, alpha: 1) }
    override func dim(_ ink: UIColor) -> UIColor { ink.shade(0.45) }
    override func faint(_ ink: UIColor) -> UIColor { ink.shade(0.7) }
    override func font(_ size: CGFloat) -> UIFont { .optima(size: size*Screen.s) }
    override var cursor: String { "|" }
    override func ground(_ rect: CGRect) {
        let s: CGFloat = Screen.s
        let path: CGPath = CGPath(roundedRect: rect.insetBy(dx: 0.75*s, dy: 0.75*s), cornerWidth: 10*s, cornerHeight: 10*s, transform: nil)
        let c: CGContext = UIGraphicsGetCurrentContext()!
        c.addPath(path)
        c.setFillColor(UIColor(white: 0.17, alpha: 1).cgColor)
        c.setStrokeColor(UIColor(white: 0.55, alpha: 1).cgColor)
        c.setLineWidth(1.5*s)
        c.drawPath(using: .fillStroke)
    }
    override func button(_ title: String) -> UIControl { LimboKey(title) }
    override func buttonFrame(width: CGFloat, above keys: CGFloat) -> CGRect { CGRect(x: (width - 140*Screen.s)/2, y: keys - 40*Screen.s, width: 140*Screen.s, height: 30*Screen.s) }
}

/// The Aepryus account's modal as a limbo panel too: dark glass edged in grey, Optima, the same keys.
final class LimboAccountStyle: AepryusStyle {
    override func font(_ size: CGFloat) -> UIFont { .optima(size: (size - 2)*Screen.s) }
    override var title: UIColor { UIColor(white: 0.92, alpha: 1) }
    override var text: UIColor { UIColor(white: 0.78, alpha: 1) }
    override var fieldBack: UIColor { UIColor(white: 0.24, alpha: 1) }
    override var fieldEdge: UIColor { UIColor(white: 0.6, alpha: 1) }
    override func panel(_ modal: Modal, cancel: Bool) { LimboStyle().ground(modal.bounds) }
    override func button(_ title: String, _ kind: Button) -> UIControl { LimboKey(title) }
    override func frame(_ kind: Button, slot: CGRect) -> CGRect {
        let s: CGFloat = Screen.s
        switch kind {
            case .ok: return CGRect(x: slot.maxX - 12*s - 120*s, y: slot.maxY - 10*s - 30*s, width: 120*s, height: 30*s)
            case .cancel: return CGRect(x: slot.minX + 12*s, y: slot.maxY - 10*s - 30*s, width: 120*s, height: 30*s)
            case .choice: return CGRect(x: slot.midX - 130*s, y: slot.midY - 15*s, width: 260*s, height: 30*s)
        }
    }
}

/// A rounded key, edged as the panels are.
private final class LimboKey: AXButton {
    let title: String
    init(_ title: String) {
        self.title = title
        super.init()
    }
    override func draw(_ rect: CGRect) {
        let s: CGFloat = Screen.s
        let c: CGContext = UIGraphicsGetCurrentContext()!
        c.addPath(CGPath(roundedRect: bounds.insetBy(dx: 1*s, dy: 1*s), cornerWidth: 7*s, cornerHeight: 7*s, transform: nil))
        c.setFillColor(UIColor(white: isHighlighted ? 0.35 : 0.24, alpha: 1).cgColor)
        c.setStrokeColor(UIColor(white: 0.6, alpha: 1).cgColor)
        c.setLineWidth(1.5*s)
        c.drawPath(using: .fillStroke)
        let pen: Pen = Pen(font: .optima(size: 15*s), color: UIColor(white: 0.92, alpha: 1), alignment: .center)
        (title as NSString).draw(in: CGRect(x: 0, y: (height - pen.font.lineHeight)/2, width: width, height: pen.font.lineHeight), withAttributes: pen.attributes)
    }
}
