//
//  PostRecord.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/07.
//

import Foundation
import GRDB

struct PostRecord:
    Codable,
    FetchableRecord,
    MutablePersistableRecord,
    Identifiable
{
    var id: Int64?
    var packagePostID: String?

    var body: String

    var diaryDate: Date
    var createdAt: Date
    var updatedAt: Date

    var parentPostId: Int64?

    static let databaseTableName = "posts"

    mutating func didInsert(
        _ inserted: InsertionSuccess
    ) {
        id = inserted.rowID
    }
}
