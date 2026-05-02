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
    static let hyleBridge: Article = Article(key: "hyleBridge")
    static let cupolaRedux: Article = Article(key: "cupolaRedux")
    static let aexelSources: Article = Article(key: "aexelSources")
    
    static let steppingStones: Article = Article(key: "steppingStones", parent: discovery)
    
    static var articles: [Article] = [
        discovery, expansion, escaping, covariance, reciprocity, eeemcee,
        cupola, squish, hyleBridge, cupolaRedux, aexelSources, steppingStones
    ]
    
    static func glyphs(s: CGFloat) -> [GlyphView] {
        let p: CGFloat = 3*s
        
        let discoveryGlyph: ArticleGlyph = ArticleGlyph(article: discovery, radius: 112*s+2*p, x: 240*s, y: 30*s)
        let expansionGlyph: ArticleGlyph = ArticleGlyph(article: expansion, radius: 112*s+2*p, x: 50*s, y: 180*s)
        let escapingGlyph: ArticleGlyph = ArticleGlyph(article: escaping, radius: 102*s+2*p, x: 180*s, y: 270*s)
        let covarianceGlyph: ArticleGlyph = ArticleGlyph(article: covariance, radius: 124*s+2*p, x: 270*s, y: 410*s)
        let reciprocityGlyph: ArticleGlyph = ArticleGlyph(article: reciprocity, radius: 128*s+2*p, x: 110*s, y: 580*s)
        let eeemceeGlyph: ArticleGlyph = ArticleGlyph(article: eeemcee, radius: 132*s+2*p, x: 190*s, y: 730*s)
        let cupolaGlyph: ArticleGlyph = ArticleGlyph(article: cupola, radius: 92*s+2*p, x: 80*s, y: 930*s)
        let squishGlyph: ArticleGlyph = ArticleGlyph(article: squish, radius: 88*s+2*p, x: 340*s, y: 930*s)
        let hyleBridgeGlyph: ArticleGlyph = ArticleGlyph(article: hyleBridge, radius: 96*s+2*p, x: 50*s, y: 1100*s)
        let cupolaReduxGlyph: ArticleGlyph = ArticleGlyph(article: cupolaRedux, radius: 96*s+2*p, x: 120*s, y: 1270*s)
        let aexelSourcesGlyph: ArticleGlyph = ArticleGlyph(article: aexelSources, radius: 96*s+2*p, x: 310*s, y: 1100*s)
        
        let insideOutExpGlyph: ExplorerGlyph = ExplorerGlyph(explorer: Aexels.insideOutExplorer, radius: 50*s+2*p, x: 420*s, y: 870*s)
        let outsideInExpGlyph: ExplorerGlyph = ExplorerGlyph(explorer: Aexels.outsideInExplorer, radius: 50*s+2*p, x: 430*s, y: 1020*s)
        
        let steppingStonesGlyph: AsideGlyph = AsideGlyph(article: steppingStones, radius: 64*s+2*p, x: 400*s, y: 100*s)

        var glyphs: [GlyphView] = []
        
        glyphs.append(discoveryGlyph)
        glyphs.append(expansionGlyph)
        glyphs.append(escapingGlyph)
        glyphs.append(covarianceGlyph)
        glyphs.append(reciprocityGlyph)
        glyphs.append(eeemceeGlyph)
        glyphs.append(cupolaGlyph)
        glyphs.append(squishGlyph)
        glyphs.append(hyleBridgeGlyph)
        glyphs.append(cupolaReduxGlyph)
        glyphs.append(aexelSourcesGlyph)
        
        glyphs.append(insideOutExpGlyph)
        glyphs.append(outsideInExpGlyph)
        
        glyphs.append(steppingStonesGlyph)
        
        discoveryGlyph.link(to: expansionGlyph)
        discoveryGlyph.link(to: steppingStonesGlyph)
        expansionGlyph.link(to: escapingGlyph)
        escapingGlyph.link(to: covarianceGlyph)
        covarianceGlyph.link(to: reciprocityGlyph)
        reciprocityGlyph.link(to: eeemceeGlyph)
        eeemceeGlyph.link(to: cupolaGlyph)
        eeemceeGlyph.link(to: squishGlyph)
        cupolaGlyph.link(to: hyleBridgeGlyph)
        hyleBridgeGlyph.link(to: cupolaReduxGlyph)
        squishGlyph.link(to: aexelSourcesGlyph)
        squishGlyph.link(to: insideOutExpGlyph)
        squishGlyph.link(to: outsideInExpGlyph)

        return glyphs
    }
}
