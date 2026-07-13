//
//  PostLinkRecord.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/10.
//

import Foundation
import GRDB

struct PostLinkRecord: Codable, FetchableRecord, PersistableRecord, Identifiable {

    var id: Int64?
    var fromPostId: Int64
    var toPostId: Int64
    var sortOrder: Int

    static let databaseTableName = "post_links"
}
