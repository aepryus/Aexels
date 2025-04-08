//
//  ConceptGlyphs.swift
//  Aexels
//
//  Created by Joe Charlier on 3/9/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

import Acheron
import UIKit

class Concepts {
    
    static let intro: Article = Article(key: "intro")
    static let aether: Article = Article(key: "aether")
    static let cellular: Article = Article(key: "cellular")
    static let kinematics: Article = Article(key: "kinematics")
    static let gravity1: Article = Article(key: "gravity1")
    static let darkness: Article = Article(key: "darkness")
    static let hyle: Article = Article(key: "hyle")
    static let dilation: Article = Article(key: "dilation")
    static let contraction: Article = Article(key: "contraction")
    static let electromagnetism: Article = Article(key: "electromagnetism")
    static let gravity2: Article = Article(key: "gravity2")
    static let quantum: Article = Article(key: "quantum")
    static let nuclear: Article = Article(key: "nuclear")
    static let epilogue: Article = Article(key: "epilogue")
    
    static let forward: Article = Article(key: "forward", parent: intro)
    static let claude: Article = Article(key: "claude", parent: intro)
    static let aesthetics: Article = Article(key: "aesthetics", parent: intro)
    static let chronos : Article = Article(key: "chronos", parent: dilation)
    static let floatingLeaf: Article = Article(key: "floatingLeaf", parent: dilation)
    static let fourClocks : Article = Article(key: "fourClocks", parent: dilation)
    static let blackHole : Article = Article(key: "blackHole", parent: gravity2)
    static let narwhal : Article = Article(key: "narwhal", parent: contraction)
    static let magnetism: Article = Article(key: "magnetism", parent: electromagnetism)
    static let bellTHooft : Article = Article(key: "bellTHooft", parent: quantum)
    static let thooft: Article = Article(key: "2103.04335v3_pdf", parent: quantum)
    static let glossary : Article = Article(key: "glossary", parent: epilogue)

    static var articles: [Article] = [
        intro, aether, cellular, kinematics, gravity1, darkness, hyle, dilation, contraction,
        electromagnetism, gravity2, quantum, nuclear, epilogue, forward, claude, aesthetics,
        blackHole, chronos, floatingLeaf, fourClocks, narwhal, magnetism, bellTHooft, glossary
    ]
    
    static func glyphs(s: CGFloat) -> [GlyphView] {
        let p: CGFloat = 3*s
        
        let universeXGlyph: ArticleGlyph = ArticleGlyph(article: intro, radius: 112*s+2*p, x: 70*s, y: 30*s)
        let aetherGlyph: ArticleGlyph = ArticleGlyph(article: aether, radius: 82*s+2*p, x: 50*s, y: 180*s)
        let cellularGlyph: ArticleGlyph = ArticleGlyph(article: cellular, radius: 102*s+2*p, x: 230*s, y: 280*s)
        let kinematicsGlyph: ArticleGlyph = ArticleGlyph(article: kinematics, radius: 112*s+2*p, x: 90*s, y: 490*s)
        let gravity1Glyph: ArticleGlyph = ArticleGlyph(article: gravity1, radius: 93*s+2*p, x: 200*s, y: 680*s)
        let hyleGlyph: ArticleGlyph = ArticleGlyph(article: hyle, radius: 72*s+2*p, x: 280*s, y: 860*s)
        let dilationGlyph: ArticleGlyph = ArticleGlyph(article: dilation, radius: 100*s+2*p, x: 260*s, y: 1040*s)
        let contractionGlyph: ArticleGlyph = ArticleGlyph(article: contraction, radius: 110*s+2*p, x: 100*s, y: 1000*s)
        let electromagnetismGlyph: ArticleGlyph = ArticleGlyph(article: electromagnetism, radius: 116*s+2*p, x: 310*s, y: 1220*s)
        let gravity2Glyph: ArticleGlyph = ArticleGlyph(article: gravity2, radius: 93*s+2*p, x: 300*s, y: 1400*s)
        let darknessGlyph: ArticleGlyph = ArticleGlyph(article: darkness, radius: 110*s+2*p, x: 280*s, y: 1580*s)
        let quantumGlyph: ArticleGlyph = ArticleGlyph(article: quantum, radius: 100*s, x: 100*s, y: 1730*s)
        let nuclearGlyph: ArticleGlyph = ArticleGlyph(article: nuclear, radius: 94*s, x: 250*s, y: 1860*s)
        let epilogueGlyph: ArticleGlyph = ArticleGlyph(article: epilogue, radius: 96*s+2*p, x: 330*s, y: 1987*s)

        let aetherExpGlyph: ExplorerGlyph = ExplorerGlyph(explorer: Aexels.aetherExplorer, radius: 50*s+2*p, x: 75*s, y: 300*s)
        let cellularExpGlyph: ExplorerGlyph = ExplorerGlyph(explorer: Aexels.cellularExplorer, radius: 50*s+2*p, x: 400*s, y: 300*s)
        let kinematicsExpGlyph: ExplorerGlyph = ExplorerGlyph(explorer: Aexels.kinematicsExplorer, radius: 50*s+2*p, x: 50*s, y: 400*s)
        let gravityExpGlyph: ExplorerGlyph = ExplorerGlyph(explorer: Aexels.gravityExplorer, radius: 50*s+2*p, x: 280*s, y: 600*s)
        let dilationExpGlyph: ExplorerGlyph = ExplorerGlyph(explorer: Aexels.dilationExplorer, radius: 50*s+2*p, x: 220*s, y: 960*s)
        let contractionExpGlyph: ExplorerGlyph = ExplorerGlyph(explorer: Aexels.contractionExplorer, radius: 50*s+2*p, x: 30*s, y: 920*s)
        let electromagnetismExpGlyph: ExplorerGlyph = ExplorerGlyph(explorer: Aexels.electromagnetismExplorer, radius: 50*s+2*p, x: 430*s, y: 1350*s)

        let forwardGlyph: AsideGlyph = AsideGlyph(article: forward, radius: 56*s+2*p, x: 250*s, y: 36*s)
        let claudeGlyph: AsideGlyph = AsideGlyph(article: claude, radius: 56*s+2*p, x: 250*s, y: 120*s)
        let aestheticsGlyph: AsideGlyph = AsideGlyph(article: aesthetics, radius: 64*s+2*p, x: 170*s, y: 170*s)
        let chronosGlyph: AsideGlyph = AsideGlyph(article: chronos, radius: 60*s+2*p, x: 400*s, y: 940*s)
        let floatingLeafGlyph: AsideGlyph = AsideGlyph(article: floatingLeaf, radius: 62*s, x: 430*s, y: 1020*s)
        let fourClocksGlyph: AsideGlyph = AsideGlyph(article: fourClocks, radius: 46*s+2*p, x: 416*s, y: 1100*s)
        let narwhalGlyph: AsideGlyph = AsideGlyph(article: narwhal, radius: 70*s+2*p, x: 30*s, y: 1140*s)
        let magnetismGlyph: AsideGlyph = AsideGlyph(article: magnetism, radius: 74*s, x: 200*s, y: 1230*s)
        let blackHoleGlyph: AsideGlyph = AsideGlyph(article: blackHole, radius: 40*s+2*p, x: 220*s, y: 1360*s)
        let bellTHooftGlyph: AsideGlyph = AsideGlyph(article: bellTHooft, radius: 60*s+2*p, x: 90*s, y: 1640*s)
        let thooftGlyph: AsideGlyph = AsideGlyph(article: thooft, radius: 60*s, x: 110*s, y: 1860*s)
        let glossaryGlyph: AsideGlyph = AsideGlyph(article: glossary, radius: 60*s+2*p, x: 250*s, y: 2130*s)

        var glyphs: [GlyphView] = []
        
        glyphs.append(universeXGlyph)
        glyphs.append(aetherGlyph)
        glyphs.append(cellularGlyph)
        glyphs.append(kinematicsGlyph)
        glyphs.append(gravity1Glyph)
        glyphs.append(hyleGlyph)
        glyphs.append(dilationGlyph)
        glyphs.append(contractionGlyph)
        glyphs.append(electromagnetismGlyph)
        glyphs.append(gravity2Glyph)
        glyphs.append(darknessGlyph)
        glyphs.append(quantumGlyph)
        glyphs.append(nuclearGlyph)
        glyphs.append(epilogueGlyph)

        glyphs.append(aetherExpGlyph)
        glyphs.append(cellularExpGlyph)
        glyphs.append(kinematicsExpGlyph)
        glyphs.append(gravityExpGlyph)
        glyphs.append(dilationExpGlyph)
        glyphs.append(contractionExpGlyph)
        glyphs.append(electromagnetismExpGlyph)

        glyphs.append(forwardGlyph)
        glyphs.append(claudeGlyph)
        glyphs.append(aestheticsGlyph)
        glyphs.append(chronosGlyph)
        glyphs.append(floatingLeafGlyph)
        glyphs.append(fourClocksGlyph)
        glyphs.append(narwhalGlyph)
        glyphs.append(magnetismGlyph)
        glyphs.append(blackHoleGlyph)
        glyphs.append(bellTHooftGlyph)
        glyphs.append(thooftGlyph)
        glyphs.append(glossaryGlyph)

        universeXGlyph.link(to: aetherGlyph)
        universeXGlyph.link(to: forwardGlyph)
        universeXGlyph.link(to: claudeGlyph)
        universeXGlyph.link(to: aestheticsGlyph)
        
        aetherGlyph.link(to: cellularGlyph)
        aetherGlyph.link(to: aetherExpGlyph)

        cellularGlyph.link(to: kinematicsGlyph)
        cellularGlyph.link(to: cellularExpGlyph)
        
        kinematicsGlyph.link(to: gravity1Glyph)
        kinematicsGlyph.link(to: kinematicsExpGlyph)
        
        gravity1Glyph.link(to: hyleGlyph)
        gravity1Glyph.link(to: gravityExpGlyph)
        
        hyleGlyph.link(to: dilationGlyph)
        
        dilationGlyph.link(to: contractionGlyph)
        dilationGlyph.link(to: dilationExpGlyph)
        dilationGlyph.link(to: chronosGlyph)
        dilationGlyph.link(to: floatingLeafGlyph)
        dilationGlyph.link(to: fourClocksGlyph)

        contractionGlyph.link(to: electromagnetismGlyph)
        contractionGlyph.link(to: contractionExpGlyph)
        contractionGlyph.link(to: narwhalGlyph)
        
        electromagnetismGlyph.link(to: gravity2Glyph)
        electromagnetismGlyph.link(to: electromagnetismExpGlyph)
        electromagnetismGlyph.link(to: magnetismGlyph)
        
        gravity2Glyph.link(to: darknessGlyph)
        gravity2Glyph.link(to: blackHoleGlyph)
        
        darknessGlyph.link(to: quantumGlyph)

        quantumGlyph.link(to: nuclearGlyph)
        quantumGlyph.link(to: bellTHooftGlyph)
        quantumGlyph.link(to: thooftGlyph)
        
        nuclearGlyph.link(to: epilogueGlyph)
        
        epilogueGlyph.link(to: glossaryGlyph)
        
        contractionGlyph.contract = true
        
        return glyphs
    }
}
