//
//  AexelsAI.swift
//  Aexels
//
//  Created by Joe Charlier on 11/8/26.
//  Copyright © 2026 Aepryus Software. All rights reserved.
//
//  Aexels's AI: OoviumKit's tray, a limbo panel that slides in down the right over whatever is on show, opened
//  by the Claude circle beside the vision bar. It always answers on Opus, thinking at xhigh effort. What it knows
//  of Aexels is its prompt, which Pequod adds and keeps warm in Anthropic's cache: its AI Reference, written from
//  Aexels's code, its sims and its articles (AI/Reference.md); every article in full; and Joe's four papers in
//  full, as their latest LaTeX in Vesper; about 255k tokens in all, built by AI/prompt.py and published by
//  AI/publish.sh whenever any of it changes. It's there to explain and explore Universe X with the person, and
//  to push back. It's paid in the Aepryus account's credits; its conversation is kept in the basket under
//  "chatIden".
//

import Acheron
import OoviumKit
import UIKit

enum AexelsAI {
    static let tray: AITray = AITray(feature: "aexels.tray", tools: [], chat: chat, style: LimboStyle(), model: .opus, effort: .xhigh)
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

    /// In from the right, or back out; the explorer under it carries on. On the Mac it opens in the wing instead.
    static func toggle() {
        if let wing: WingViewController = Aexels.wing { return wing.toggle() }
        guard let view: UIView = Aexels.explorerViewController.view else { return }
        open.toggle()
        if tray.superview == nil {
            shade()
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
    /// The limbo panels' shadow.
    static func shade() {
        tray.layer.shadowColor = UIColor.black.cgColor
        tray.layer.shadowOffset = .zero
        tray.layer.shadowRadius = 3*Screen.s
        tray.layer.shadowOpacity = 0.6
    }
    /// Down the right, under the vision bar and its circle; out past the edge when closed.
    static func place(in view: UIView, open: Bool) {
        let s: CGFloat = Screen.s
        let w: CGFloat = min(380*s, view.bounds.width - 12*s)
        let top: CGFloat = Screen.safeTop + 52*s
        tray.frame = CGRect(x: open ? view.bounds.width - w - 6*s : view.bounds.width + 6*s, y: top, width: w, height: view.bounds.height - top - Screen.safeBottom - 6*s)
        tray.layer.shadowPath = CGPath(roundedRect: tray.bounds, cornerWidth: 10*s, cornerHeight: 10*s, transform: nil)
    }
}

/// The Mac's window: the app at its fixed size on the left and, opened, a wing to its right that the window grows
/// into, holding the AI's tray, so the tray covers nothing. The toggle in the app's top right corner opens and closes
/// it, as the Claude circle does; the window's left edge stays where it is.
final class WingViewController: UIViewController {
    private let app: UIViewController
    private let ground: UIImageView = UIImageView(image: UIImage(named: "OldBack"))
    private(set) var open: Bool = false

    /// The app's fixed size, and the wing's width.
    static var appSize: CGSize { CGSize(width: 1194/Screen.scaler, height: 834/Screen.scaler) }
    static var width: CGFloat { 392*Screen.s }

    init(app: UIViewController) {
        self.app = app
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    func toggle() {
        open.toggle()
        Aexels.explorerViewController.wingToggle.rotateView()
        let tray: AITray = AexelsAI.tray
        if open {
            if tray.superview == nil {
                AexelsAI.shade()
                view.addSubview(tray)
            }
            tray.isHidden = false
            resize(width: WingViewController.appSize.width + WingViewController.width)
            tray.onOpen()
        } else {
            tray.onClose()
            resize(width: WingViewController.appSize.width)
        }
    }
    /// The window grown to take the wing, or back to the app alone, its left edge where it was. Its size is pinned
    /// (min = max), so the pin is moved first on the side that lets it change.
    private func resize(width: CGFloat) {
        guard let scene: UIWindowScene = view.window?.windowScene else { return }
        let size: CGSize = CGSize(width: width, height: WingViewController.appSize.height)
        if open {
            scene.sizeRestrictions?.maximumSize = size
            scene.sizeRestrictions?.minimumSize = size
        } else {
            scene.sizeRestrictions?.minimumSize = size
            scene.sizeRestrictions?.maximumSize = size
        }
        if #available(iOS 16.0, *) {
            let frame: CGRect = scene.effectiveGeometry.systemFrame
            let k: CGFloat = frame.width/max(1, view.bounds.width)      // the system's points per the scene's
            scene.requestGeometryUpdate(.Mac(systemFrame: CGRect(x: frame.minX, y: frame.minY, width: width*k, height: frame.height)))
        }
    }

// UIViewController ================================================================================
    override func viewDidLoad() {
        super.viewDidLoad()
        ground.contentMode = .scaleAspectFill
        ground.clipsToBounds = true
        view.addSubview(ground)
        addChild(app)
        view.addSubview(app.view)
        app.didMove(toParent: self)
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let s: CGFloat = Screen.s
        let size: CGSize = WingViewController.appSize
        app.view.frame = CGRect(origin: .zero, size: size)
        ground.frame = CGRect(x: size.width, y: 0, width: max(0, view.bounds.width - size.width), height: view.bounds.height)
        let tray: AITray = AexelsAI.tray
        guard tray.superview === view else { return }
        tray.frame = CGRect(x: size.width + 6*s, y: Screen.safeTop + 6*s, width: WingViewController.width - 12*s, height: view.bounds.height - Screen.safeTop - 12*s)
        tray.layer.shadowPath = CGPath(roundedRect: tray.bounds, cornerWidth: 10*s, cornerHeight: 10*s, transform: nil)
        tray.isHidden = !open && view.bounds.width <= size.width + 1
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
    override func wall(_ label: String, fit: (String, String) -> Int) -> String { AIStyle.ruled(label, fit: fit) }
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
