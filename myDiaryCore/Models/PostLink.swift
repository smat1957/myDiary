//
//  PostLink.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/10.
//

import Foundation

struct PostLink: Identifiable, Hashable {
    let id = UUID()

    var fromPostId: Int64
    var toPostId: Int64
    var sortOrder: Int
}
