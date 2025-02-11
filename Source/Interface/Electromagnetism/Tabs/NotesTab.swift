//
//  NotesTab.swift
//  Aexels
//
//  Created by Joe Charlier on 1/23/25.
//  Copyright © 2025 Aepryus Software. All rights reserved.
//

import UIKit

class NotesTab: TabsCellTab {
    let key: String
    
    let articleScroll: UIScrollView = UIScrollView()
    let articleView: ArticleView = ArticleView()

    init(key: String) {
        self.key = key
        
        super.init(name: "Notes".localized)
        
        articleView.font = UIFont(name: "Verdana", size: 18*s)!
        articleView.color = .white
        articleView.scrollView = articleScroll
        articleView.key = "\(key)Lab"
        articleScroll.addSubview(articleView)
        
        articleScroll.showsVerticalScrollIndicator = false
        addSubview(articleScroll)
    }
    
// UIView ==========================================================================================
    override func layoutSubviews() {
        articleScroll.frame = CGRect(x: 5*s, y: 10*s, width: bounds.size.width-10*s, height: bounds.size.height-44*s)
        
        articleView.load()
        articleScroll.contentSize = articleView.scrollViewContentSize
        articleView.frame = CGRect(x: 10*s, y: 0, width: articleScroll.width-20*s, height: articleScroll.height)
    }
}
