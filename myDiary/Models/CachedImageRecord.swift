//
//  CachedImageRecord.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/18.
//

//
//  CachedImageRecord.swift
//  myDiary
//

import Foundation
import GRDB

struct CachedImageRecord:

    Codable,
    FetchableRecord,
    MutablePersistableRecord
{
    var id: Int64?

    var sourceType: String

    var sourceURL: String

    var baseName: String

    var originalExtension: String

    var createdAt: Date

    static let databaseTableName =
        "cached_images"
}
