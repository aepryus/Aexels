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
    static let gravity: Article = Article(key: "gravity")
    static let darkness: Article = Article(key: "darkness")
    static let hyle: Article = Article(key: "hyle")
    static let dilation: Article = Article(key: "dilation")
    static let contraction: Article = Article(key: "contraction")
    static let electromagnetism: Article = Article(key: "electromagnetism")
    static let quantum: Article = Article(key: "quantum")
    static let nuclear: Article = Article(key: "nuclear")
    static let epilogue: Article = Article(key: "epilogue")
    
    static let forward: Article = Article(key: "forward", parent: intro)
    static let claude: Article = Article(key: "claude", parent: intro)
    static let aesthetics: Article = Article(key: "aesthetics", parent: intro)
    static let G: Article = Article(key: "G", parent: gravity)
    static let chronos : Article = Article(key: "chronos", parent: dilation)
    static let floatingLeaf: Article = Article(key: "floatingLeaf", parent: dilation)
    static let fourClocks : Article = Article(key: "fourClocks", parent: dilation)
    static let blackHole : Article = Article(key: "blackHole", parent: dilation)
    static let narwhal : Article = Article(key: "narwhal", parent: contraction)
    static let magnetism: Article = Article(key: "magnetism", parent: electromagnetism)
    static let bellTHooft : Article = Article(key: "bellTHooft", parent: quantum)
    static let thooft: Article = Article(key: "2103.04335v3_pdf", parent: quantum)
    static let glossary : Article = Article(key: "glossary", parent: epilogue)

    static var articles: [Article] = [
        intro, aether, cellular, kinematics, gravity, darkness, hyle, dilation, contraction,
        electromagnetism, quantum, nuclear, epilogue, forward, claude, aesthetics, blackHole, G,
        chronos, floatingLeaf, fourClocks, narwhal, magnetism, bellTHooft, glossary
    ]
    
    static func glyphs(s: CGFloat) -> [GlyphView] {
        let p: CGFloat = 3*s
        
        let universeXGlyph: ArticleGlyph = ArticleGlyph(article: intro, radius: 112*s+2*p, x: 70*s, y: 30*s)
        let aetherGlyph: ArticleGlyph = ArticleGlyph(article: aether, radius: 82*s+2*p, x: 50*s, y: 180*s)
        let cellularGlyph: ArticleGlyph = ArticleGlyph(article: cellular, radius: 102*s+2*p, x: 230*s, y: 330*s)
        let kinematicsGlyph: ArticleGlyph = ArticleGlyph(article: kinematics, radius: 112*s+2*p, x: 30*s, y: 480*s)
        let gravityGlyph: ArticleGlyph = ArticleGlyph(article: gravity, radius: 90*s+2*p, x: 200*s, y: 630*s)
        let darknessGlyph: ArticleGlyph = ArticleGlyph(article: darkness, radius: 110*s+2*p, x: 80*s, y: 760*s)
        let hyleGlyph: ArticleGlyph = ArticleGlyph(article: hyle, radius: 72*s+2*p, x: 280*s, y: 860*s)
        let dilationGlyph: ArticleGlyph = ArticleGlyph(article: dilation, radius: 100*s+2*p, x: 260*s, y: 1040*s)
        let contractionGlyph: ArticleGlyph = ArticleGlyph(article: contraction, radius: 110*s+2*p, x: 100*s, y: 1000*s)
        let electromagnetismGlyph: ArticleGlyph = ArticleGlyph(article: electromagnetism, radius: 116*s+2*p, x: 210*s, y: 1290*s)
        let quantumGlyph: ArticleGlyph = ArticleGlyph(article: quantum, radius: 100*s, x: 100*s, y: 1430*s)
        let nuclearGlyph: ArticleGlyph = ArticleGlyph(article: nuclear, radius: 94*s, x: 250*s, y: 1560*s)
        let epilogueGlyph: ArticleGlyph = ArticleGlyph(article: epilogue, radius: 96*s+2*p, x: 330*s, y: 1687*s)

        let aetherExpGlyph: ExplorerGlyph = ExplorerGlyph(explorer: Aexels.aetherExplorer, radius: 50*s+2*p, x: 75*s, y: 315*s)
        let cellularExpGlyph: ExplorerGlyph = ExplorerGlyph(explorer: Aexels.cellularExplorer, radius: 50*s+2*p, x: 400*s, y: 300*s)
        let kinematicsExpGlyph: ExplorerGlyph = ExplorerGlyph(explorer: Aexels.kinematicsExplorer, radius: 50*s+2*p, x: 230*s, y: 530*s)
        let gravityExpGlyph: ExplorerGlyph = ExplorerGlyph(explorer: Aexels.gravityExplorer, radius: 50*s+2*p, x: 380*s, y: 670*s)
        let dilationExpGlyph: ExplorerGlyph = ExplorerGlyph(explorer: Aexels.dilationExplorer, radius: 50*s+2*p, x: 380*s, y: 960*s)
        let contractionExpGlyph: ExplorerGlyph = ExplorerGlyph(explorer: Aexels.contractionExplorer, radius: 50*s+2*p, x: 30*s, y: 920*s)
        let electromagnetismExpGlyph: ExplorerGlyph = ExplorerGlyph(explorer: Aexels.electromagnetismExplorer, radius: 50*s+2*p, x: 380*s, y: 1420*s)

        let forwardGlyph: AsideGlyph = AsideGlyph(article: forward, radius: 56*s+2*p, x: 250*s, y: 36*s)
        let claudeGlyph: AsideGlyph = AsideGlyph(article: claude, radius: 56*s+2*p, x: 250*s, y: 120*s)
        let aestheticsGlyph: AsideGlyph = AsideGlyph(article: aesthetics, radius: 64*s+2*p, x: 170*s, y: 170*s)
        let chronosGlyph: AsideGlyph = AsideGlyph(article: chronos, radius: 60*s+2*p, x: 400*s, y: 1040*s)
        let floatingLeafGlyph: AsideGlyph = AsideGlyph(article: floatingLeaf, radius: 62*s, x: 396*s, y: 1142*s)
        let fourClocksGlyph: AsideGlyph = AsideGlyph(article: fourClocks, radius: 46*s+2*p, x: 336*s, y: 1190*s)
        let blackHoleGlyph: AsideGlyph = AsideGlyph(article: blackHole, radius: 40*s+2*p, x: 270*s, y: 1200*s)
        let narwhalGlyph: AsideGlyph = AsideGlyph(article: narwhal, radius: 70*s+2*p, x: 30*s, y: 1140*s)
        let magnetismGlyph: AsideGlyph = AsideGlyph(article: magnetism, radius: 74*s, x: 100*s, y: 1230*s)
        let bellTHooftGlyph: AsideGlyph = AsideGlyph(article: bellTHooft, radius: 60*s+2*p, x: 90*s, y: 1340*s)
        let thooftGlyph: AsideGlyph = AsideGlyph(article: thooft, radius: 60*s, x: 110*s, y: 1560*s)
        let glossaryGlyph: AsideGlyph = AsideGlyph(article: glossary, radius: 60*s+2*p, x: 250*s, y: 1830*s)

        var glyphs: [GlyphView] = []
        
        glyphs.append(universeXGlyph)
        glyphs.append(aetherGlyph)
        glyphs.append(cellularGlyph)
        glyphs.append(kinematicsGlyph)
        glyphs.append(gravityGlyph)
        glyphs.append(darknessGlyph)
        glyphs.append(hyleGlyph)
        glyphs.append(dilationGlyph)
        glyphs.append(contractionGlyph)
        glyphs.append(electromagnetismGlyph)
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
        glyphs.append(blackHoleGlyph)
        glyphs.append(chronosGlyph)
        glyphs.append(floatingLeafGlyph)
        glyphs.append(fourClocksGlyph)
        glyphs.append(narwhalGlyph)
        glyphs.append(magnetismGlyph)
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
        
        kinematicsGlyph.link(to: gravityGlyph)
        kinematicsGlyph.link(to: kinematicsExpGlyph)
        
        gravityGlyph.link(to: darknessGlyph)
        gravityGlyph.link(to: gravityExpGlyph)
        
        darknessGlyph.link(to: hyleGlyph)
        
        hyleGlyph.link(to: dilationGlyph)
        
        dilationGlyph.link(to: contractionGlyph)
        dilationGlyph.link(to: dilationExpGlyph)
        dilationGlyph.link(to: chronosGlyph)
        dilationGlyph.link(to: floatingLeafGlyph)
        dilationGlyph.link(to: fourClocksGlyph)
        dilationGlyph.link(to: blackHoleGlyph)

        contractionGlyph.link(to: electromagnetismGlyph)
        contractionGlyph.link(to: contractionExpGlyph)
        contractionGlyph.link(to: narwhalGlyph)
        
        electromagnetismGlyph.link(to: quantumGlyph)
        electromagnetismGlyph.link(to: electromagnetismExpGlyph)
        electromagnetismGlyph.link(to: magnetismGlyph)
        
        quantumGlyph.link(to: nuclearGlyph)
        quantumGlyph.link(to: bellTHooftGlyph)
        quantumGlyph.link(to: thooftGlyph)
        
        nuclearGlyph.link(to: epilogueGlyph)
        
        epilogueGlyph.link(to: glossaryGlyph)
        
        contractionGlyph.contract = true
        
        return glyphs
    }
}
