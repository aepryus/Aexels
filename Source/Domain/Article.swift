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
}
