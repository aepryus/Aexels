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
    static let blackHole : Article = Article(key: "blackHole", parent: gravity)
    static let G: Article = Article(key: "G", parent: gravity)
    static let chronos : Article = Article(key: "chronos", parent: dilation)
    static let floatingLeaf: Article = Article(key: "floatingLeaf", parent: dilation)
    static let fourClocks : Article = Article(key: "fourClocks", parent: dilation)
    static let narwhal : Article = Article(key: "narwhal", parent: contraction)
    static let magnetism: Article = Article(key: "magnetism", parent: electromagnetism)
    static let bellTHooft : Article = Article(key: "bellTHooft", parent: quantum)
    static let thooft: Article = Article(key: "2103.04335v3_pdf", parent: quantum)
    static let glossary : Article = Article(key: "glossary", parent: epilogue)

    static var articles: [Article] = [
        intro, aether, cellular, kinematics, gravity, darkness, hyle, dilation, contraction,
        electromagnetism, quantum, nuclear, epilogue, forward, claude, blackHole, G, chronos, floatingLeaf,
        fourClocks, narwhal, magnetism, bellTHooft, glossary
    ]
    
    static func wire() {
        intro.next = aether
        aether.next = cellular
        cellular.next = kinematics
        kinematics.next = gravity
        gravity.next = darkness
        darkness.next = hyle
        hyle.next = dilation
        dilation.next = contraction
        contraction.next = electromagnetism
        electromagnetism.next = bellTHooft
        bellTHooft.next = epilogue
        forward.next = claude
        chronos.next = floatingLeaf
        floatingLeaf.next = fourClocks
        aether.explorers.append(Aexels.aetherExplorer)
        cellular.explorers.append(Aexels.cellularExplorer)
        kinematics.explorers.append(Aexels.kinematicsExplorer)
        gravity.explorers.append(Aexels.distanceExplorer)
        gravity.explorers.append(Aexels.gravityExplorer)
        dilation.explorers.append(Aexels.dilationExplorer)
        contraction.explorers.append(Aexels.contractionExplorer)
        electromagnetism.explorers.append(Aexels.electromagnetismExplorer)
    }
}
