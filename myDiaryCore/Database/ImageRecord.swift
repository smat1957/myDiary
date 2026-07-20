//
//  ImageRecord.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/07.
//

import Foundation
import GRDB

struct ImageRecord: Codable, FetchableRecord, PersistableRecord, Identifiable {

    var id: Int64?
    var postId: Int64

    var baseName: String
    var originalExtension: String

    var sourceType: String
    var sourceURL: String?

    var sortOrder: Int

    static let databaseTableName = "images"
}
