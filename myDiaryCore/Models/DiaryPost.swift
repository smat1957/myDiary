//
//  DiaryPost.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/07.
//

import Foundation

struct DiaryPost: Identifiable {

    var id: Int64 = 0

    var packagePostID: String?

    var body: String

    var diaryDate: Date
    var createdAt: Date
    var updatedAt: Date

    var parentPostId: Int64?

    var images: [DiaryImage]
    var links: [PostLink]

    init(
        id: Int64 = 0,
        packagePostID: String? = nil,
        body: String,
        diaryDate: Date = Date(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        parentPostId: Int64? = nil,
        images: [DiaryImage] = [],
        links: [PostLink] = []
    ) {
        self.id = id
        self.packagePostID = packagePostID
        self.body = body
        self.diaryDate = diaryDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.parentPostId = parentPostId
        self.images = images
        self.links = links
    }
}
extension DiaryPost {
    // タイムラインや一覧表示で代表画像として使う
    var coverImage: DiaryImage? {
        images.first
    }
}
