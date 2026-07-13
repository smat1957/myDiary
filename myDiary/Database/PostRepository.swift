//
//  PostRepository.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/07.
//

import Foundation
import GRDB

final class PostRepository {

    private let dbQueue: DatabaseQueue

    init(dbQueue: DatabaseQueue = DatabaseManager.shared.dbQueue) {
        self.dbQueue = dbQueue
    }

    func fetchAll() throws -> [DiaryPost] {
        try dbQueue.read { db in
            let postRecords = try PostRecord
                .order(Column("diaryDate").desc)
                .fetchAll(db)

            return try postRecords.map { postRecord in
                let images = try fetchImages(
                    postID: postRecord.id!,
                    db: db
                )
                let links = try fetchLinks(
                    fromPostID: postRecord.id!,
                    db: db
                )
                
                let post = DiaryPost(
                    id: postRecord.id ?? 0,
                    packagePostID: postRecord.packagePostID,
                    body: postRecord.body,
                    diaryDate: postRecord.diaryDate,
                    createdAt: postRecord.createdAt,
                    updatedAt: postRecord.updatedAt,
                    parentPostId: postRecord.parentPostId,
                    images: images,
                    links: links
                )

                return post

                /*
                return DiaryPost(
                    id: postRecord.id!,
                    packagePostID: postRecord.packagePostID,
                    body: postRecord.body,
                    diaryDate: postRecord.diaryDate,
                    createdAt: postRecord.createdAt,
                    updatedAt: postRecord.updatedAt,
                    images: images,
                    links: links
                )
                 */
            }
        }
    }
    
    func insert(_ post: DiaryPost) throws -> Int64 {
        try dbQueue.write { db in

            var postRecord = PostRecord(
                id: nil,
                packagePostID: post.packagePostID,
                body: post.body,
                diaryDate: post.diaryDate,
                createdAt: post.createdAt,
                updatedAt: post.updatedAt,
                parentPostId: post.parentPostId
            )

            try postRecord.insert(db)

            let postID = db.lastInsertedRowID

            for (index, image) in post.images.enumerated() {
                var imageRecord = ImageRecord(
                    id: nil,
                    postId: postID,
                    baseName: image.baseName,
                    originalExtension: image.originalExtension,
                    sourceType: image.sourceType.rawValue,
                    sourceURL: image.sourceURL?.absoluteString,
                    sortOrder: index
                )

                try imageRecord.insert(db)
            }

            for (index, link) in post.links.enumerated() {
                var linkRecord = PostLinkRecord(
                    id: nil,
                    fromPostId: postID,
                    toPostId: link.toPostId,
                    sortOrder: index
                )

                try linkRecord.insert(db)
            }

            return postID
        }
    }
    
    func update(_ post: DiaryPost) throws {
        try dbQueue.write { db in

            var postRecord = PostRecord(
                id: post.id,
                packagePostID: post.packagePostID,
                body: post.body,
                diaryDate: post.diaryDate,
                createdAt: post.createdAt,
                updatedAt: Date(),
                parentPostId: post.parentPostId
            )
            
            try postRecord.update(db)

            try ImageRecord
                .filter(Column("postId") == post.id)
                .deleteAll(db)
            
            try PostLinkRecord
                .filter(Column("fromPostId") == post.id)
                .deleteAll(db)
            
            for (index, link) in post.links.enumerated() {

                var record = PostLinkRecord(
                    id: nil,
                    fromPostId: post.id,
                    toPostId: link.toPostId,
                    sortOrder: index
                )

                try record.insert(db)
            }
            
            for (index, image) in post.images.enumerated() {

                var imageRecord = ImageRecord(
                    id: nil,
                    postId: post.id,
                    baseName: image.baseName,
                    originalExtension: image.originalExtension,
                    sourceType: image.sourceType.rawValue,
                    sourceURL: image.sourceURL?.absoluteString,
                    sortOrder: index
                )
                
                try imageRecord.insert(db)
            }
            
        }
    }
    
    func delete(_ post: DiaryPost) throws {
        try dbQueue.write { db in
            try PostRecord
                .filter(Column("id") == post.id)
                .deleteAll(db)
        }
    }
    
    private func fetchImages(
        postID: Int64,
        db: Database
    ) throws -> [DiaryImage] {

        let imageRecords = try ImageRecord
            .filter(Column("postId") == postID)
            .order(Column("sortOrder"))
            .fetchAll(db)

        return imageRecords.map {
            DiaryImage(
                baseName: $0.baseName,
                originalExtension: $0.originalExtension,
                sourceType: ImageSourceType(rawValue: $0.sourceType) ?? .photo,
                sourceURL: $0.sourceURL.flatMap { URL(string: $0) }
            )
        }
    }
    
    private func fetchLinks(
        fromPostID: Int64,
        db: Database
    ) throws -> [PostLink] {

        let records = try PostLinkRecord
            .filter(Column("fromPostId") == fromPostID)
            .order(Column("sortOrder"))
            .fetchAll(db)

        return records.map {
            PostLink(
                fromPostId: $0.fromPostId,
                toPostId: $0.toPostId,
                sortOrder: $0.sortOrder
            )
        }
    }
    
    func containsPackagePostID(
        _ packagePostID: String
    ) throws -> Bool {

        try dbQueue.read { db in
            try PostRecord
                .filter(
                    Column("packagePostID")
                        == packagePostID
                )
                .fetchCount(db) > 0
        }
    }
    
    func fetchByPackagePostID(
        _ packagePostID: String
    ) throws -> DiaryPost? {

        try dbQueue.read { db in

            guard let postRecord = try PostRecord
                .filter(
                    Column("packagePostID")
                        == packagePostID
                )
                .fetchOne(db)
            else {
                return nil
            }

            guard let postID = postRecord.id else {
                return nil
            }

            let images = try fetchImages(
                postID: postID,
                db: db
            )

            let links = try fetchLinks(
                fromPostID: postID,
                db: db
            )

            return DiaryPost(
                id: postID,
                packagePostID: postRecord.packagePostID,
                body: postRecord.body,
                diaryDate: postRecord.diaryDate,
                createdAt: postRecord.createdAt,
                updatedAt: postRecord.updatedAt,
                images: images,
                links: links
            )
        }
    }
    
}
