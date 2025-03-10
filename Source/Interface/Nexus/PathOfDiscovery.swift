//
//  PathOfDiscoveryGlyphs.swift
//  Aexels
//
//  Created by Joe Charlier on 3/9/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

import Acheron
import UIKit

class PathOfDiscovery {
    
    static let discovery: Article = Article(key: "discovery")
    static let expansion: Article = Article(key: "expansion")
    static let escaping: Article = Article(key: "escaping")
    static let covariance: Article = Article(key: "covariance")
    static let reciprocity: Article = Article(key: "reciprocity")
    static let eeemcee: Article = Article(key: "eeemcee")
    static let cupola: Article = Article(key: "cupola")
    static let squish: Article = Article(key: "squish")
    
    static var articles: [Article] = [discovery, expansion, escaping, covariance, reciprocity, eeemcee, cupola, squish]
    
    static func glyphs(s: CGFloat) -> [GlyphView] {
        let p: CGFloat = 3*s
        
        let discoveryGlyph: ArticleGlyph = ArticleGlyph(article: discovery, radius: 112*s+2*p, x: 200*s, y: 30*s)
        let expansionGlyph: ArticleGlyph = ArticleGlyph(article: expansion, radius: 112*s+2*p, x: 70*s, y: 180*s)
        let escapingGlyph: ArticleGlyph = ArticleGlyph(article: escaping, radius: 96*s+2*p, x: 200*s, y: 270*s)
        let covarianceGlyph: ArticleGlyph = ArticleGlyph(article: covariance, radius: 118*s+2*p, x: 230*s, y: 410*s)
        let reciprocityGlyph: ArticleGlyph = ArticleGlyph(article: reciprocity, radius: 112*s+2*p, x: 70*s, y: 580*s)
        let eeemceeGlyph: ArticleGlyph = ArticleGlyph(article: eeemcee, radius: 120*s+2*p, x: 150*s, y: 730*s)
        let cupolaGlyph: ArticleGlyph = ArticleGlyph(article: cupola, radius: 80*s+2*p, x: 70*s, y: 930*s)
        let squishGlyph: ArticleGlyph = ArticleGlyph(article: squish, radius: 80*s+2*p, x: 270*s, y: 950*s)
        
        let insideOutExpGlyph: ExplorerGlyph = ExplorerGlyph(explorer: Aexels.distanceExplorer, radius: 50*s+2*p, x: 380*s, y: 890*s)
        let outsideInExpGlyph: ExplorerGlyph = ExplorerGlyph(explorer: Aexels.gravityExplorer, radius: 50*s+2*p, x: 380*s, y: 1040*s)

        var glyphs: [GlyphView] = []
        
        glyphs.append(discoveryGlyph)
        glyphs.append(expansionGlyph)
        glyphs.append(escapingGlyph)
        glyphs.append(covarianceGlyph)
        glyphs.append(reciprocityGlyph)
        glyphs.append(eeemceeGlyph)
        glyphs.append(cupolaGlyph)
        glyphs.append(squishGlyph)
        
        glyphs.append(insideOutExpGlyph)
        glyphs.append(outsideInExpGlyph)
        
        discoveryGlyph.link(to: expansionGlyph)
        expansionGlyph.link(to: escapingGlyph)
        escapingGlyph.link(to: covarianceGlyph)
        covarianceGlyph.link(to: reciprocityGlyph)
        reciprocityGlyph.link(to: eeemceeGlyph)
        eeemceeGlyph.link(to: cupolaGlyph)
        cupolaGlyph.link(to: squishGlyph)
        squishGlyph.link(to: insideOutExpGlyph)
        squishGlyph.link(to: outsideInExpGlyph)

        return glyphs
    }
}
