//
//  Migrations.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/07.
//

import Foundation
import GRDB

enum Migrations {

    static func migrate(_ dbQueue: DatabaseQueue) throws {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("001_CreateTables") { db in

            try db.create(table: "posts") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("body", .text).notNull()
                t.column("diaryDate", .datetime).notNull()
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
            }

            try db.create(table: "images") { t in
                t.autoIncrementedPrimaryKey("id")

                t.column("postId", .integer)
                    .notNull()
                    .indexed()
                    .references("posts", onDelete: .cascade)

                t.column("baseName", .text).notNull()
                t.column("originalExtension", .text).notNull()
                t.column("sortOrder", .integer).notNull()
            }
        }
        migrator.registerMigration("002_AddImageSource") { db in
            try db.alter(table: "images") { t in
                t.add(column: "sourceType", .text)
                    .notNull()
                    .defaults(to: "photo")

                t.add(column: "sourceURL", .text)
            }
        }
        migrator.registerMigration("003_CreatePostLinks") { db in
            try db.create(table: "post_links") { t in
                t.autoIncrementedPrimaryKey("id")

                t.column("fromPostId", .integer)
                    .notNull()
                    .references("posts", onDelete: .cascade)

                t.column("toPostId", .integer)
                    .notNull()
                    .references("posts", onDelete: .cascade)

                t.column("sortOrder", .integer)
                    .notNull()
                    .defaults(to: 0)
            }

            try db.create(index: "post_links_on_fromPostId",
                          on: "post_links",
                          columns: ["fromPostId"])

            try db.create(index: "post_links_on_toPostId",
                          on: "post_links",
                          columns: ["toPostId"])
        }
        migrator.registerMigration("004_AddPackagePostID") { db in

            try db.alter(table: "posts") { table in
                table.add(
                    column: "packagePostID",
                    .text
                )
                .notNull()
                .defaults(to: "")
            }

            /*
             既存投稿にはSQLite IDを利用した一意なIDを設定する。
             */
            try db.execute(
                sql: """
                UPDATE posts
                SET packagePostID = 'local-' || id
                WHERE packagePostID = ''
                """
            )

            /*
             同じpackagePostIDを二重登録できないようにする。
             */
            try db.create(
                index: "posts_on_packagePostID",
                on: "posts",
                columns: ["packagePostID"],
                options: .unique
            )
        }
        migrator.registerMigration("add parentPostId to posts") { db in
            try db.alter(table: "posts") { table in
                table.add(
                    column: "parentPostId",
                    .integer
                )
                .references(
                    "posts",
                    onDelete: .setNull
                )
            }
        }
        
        try migrator.migrate(dbQueue)
    }
}
