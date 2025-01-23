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
        
//        backgroundColor = .red
//        articleScroll.backgroundColor = .green
//        articleView.backgroundColor = .blue
        
        articleView.font = UIFont(name: "Verdana", size: 18*s)!
        articleView.color = .white
        articleView.scrollView = articleScroll
        articleView.key = "\(key)Lab"
        articleScroll.addSubview(articleView)
        addSubview(articleScroll)
    }
    
// UIView ==========================================================================================
    override func layoutSubviews() {
        articleScroll.frame = bounds
        
        articleView.load()
        articleScroll.contentSize = articleView.scrollViewContentSize
        articleView.frame = CGRect(x: 10*s, y: 0, width: articleScroll.width-20*s, height: articleScroll.height)
    }
}
