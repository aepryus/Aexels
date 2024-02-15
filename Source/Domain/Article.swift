//
//  Article.swift
//  Aexels
//
//  Created by Joe Charlier on 2/13/24.
//  Copyright © 2024 Aepryus Software. All rights reserved.
//

import Foundation

class Article {
    let key: String
    var parent: Article? = nil
    var children: [Article] = []
    var explorers: [Explorer] = []
    var next: Article? = nil {
        didSet {
            guard next !== oldValue else { return }
            oldValue?.prev = nil
            guard let next else { return }
            next.prev = self
        }
    }
    var prev: Article? = nil
    
    init(key: String, parent: Article? = nil) {
        self.key = key
        self.parent = parent
        
        if let parent { parent.children.append(self) }
    }
    
    var nameToken: String { "\(key)_name" }
    var articleToken: String { "\(key)_article" }
    
    var name: String { nameToken.localized }
    var nameWithoutNL: String { name.filter { !"\n".contains($0) } }
    var article: String { articleToken.localized }
    
    var lineage: [Article] {
        var lineage: [Article] = []
        if let parent { lineage.append(contentsOf: parent.lineage) }
        lineage.append(self)
        return lineage
    }
    
// Static ==========================================================================================
    static let intro: Article = Article(key: "intro")
    static let aether: Article = Article(key: "aether")
    static let cellular: Article = Article(key: "cellular")
    static let kinematics: Article = Article(key: "kinematics")
    static let gravity: Article = Article(key: "gravity")
    static let dilation: Article = Article(key: "dilation")
    static let contraction: Article = Article(key: "contraction")
    static let darkness: Article = Article(key: "darkness")
    static let equivalence: Article = Article(key: "equivalence")
    static let electromagnetism: Article = Article(key: "electromagnetism")
    static let discrepancy: Article = Article(key: "discrepancy")
    static let epilogue: Article = Article(key: "epilogue")
    
    static let blackHole : Article = Article(key: "blackHole", parent: gravity)
    static let twinParadox : Article = Article(key: "twinParadox", parent: dilation)
    static let narwhal : Article = Article(key: "narwhal", parent: contraction)
    static let symmetric : Article = Article(key: "symmetric", parent: discrepancy)
    static let blackShield : Article = Article(key: "blackShield", parent: discrepancy)
    static let quantumBell : Article = Article(key: "quantumBell", parent: discrepancy)
    
    static func wire() {
        intro.next = aether
        aether.next = cellular
        cellular.next = kinematics
        kinematics.next = gravity
        gravity.next = dilation
        dilation.next = contraction
        contraction.next = darkness
        darkness.next = equivalence
        equivalence.next = electromagnetism
        electromagnetism.next = discrepancy
        discrepancy.next = epilogue
        symmetric.next = blackShield
        blackShield.next = quantumBell
        aether.explorers.append(Aexels.aetherExplorer)
        cellular.explorers.append(Aexels.cellularExplorer)
        kinematics.explorers.append(Aexels.kinematicsExplorer)
        dilation.explorers.append(Aexels.dilationExplorer)
        contraction.explorers.append(Aexels.contractionExplorer)
    }
}
