//
//  DatabaseManager.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/06.
//

import Foundation
import GRDB

final class DatabaseManager {

    static let shared = DatabaseManager()

    let dbQueue: DatabaseQueue

    private init() {

        do {

            let appSupport = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first!

            let diaryFolder =
                appSupport.appendingPathComponent("myDiary")

            try FileManager.default.createDirectory(
                at: diaryFolder,
                withIntermediateDirectories: true
            )

            let dbURL =
                diaryFolder.appendingPathComponent("diary.sqlite")

            dbQueue = try DatabaseQueue(path: dbURL.path)

            try Migrations.migrate(dbQueue)

        }
        catch {

            fatalError(error.localizedDescription)

        }
    }

}
