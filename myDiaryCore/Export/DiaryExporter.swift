//
//  DiaryExporter.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/14.
//

//
//  DiaryExporter.swift
//  myDiary
//

import Foundation

final class DiaryExporter {

    struct ExportResult {
        let exportedPostCount: Int
        let exportedMediaCount: Int
        let exportedLinkCount: Int
        let outputURL: URL
    }

    enum ExportError: LocalizedError {

        case invalidPostID(Int64)
        case parentPostNotFound(Int64)
        case linkTargetNotFound(Int64)

        var errorDescription: String? {
            switch self {

            case .invalidPostID(let id):
                return """
                投稿IDが不正です。
                DB ID: \(id)
                """

            case .parentPostNotFound(let id):
                return """
                コメントの親投稿が見つかりません。
                DB ID: \(id)
                """

            case .linkTargetNotFound(let id):
                return """
                投稿リンクのリンク先が見つかりません。
                DB ID: \(id)
                """
            }
        }
    }
    
    func exportPackage(
        posts: [DiaryPost],
        title: String = "myDiary",
        to packageURL: URL
    ) throws -> ExportResult {

        try FileManager.default.createDirectory(
            at: packageURL,
            withIntermediateDirectories: true
        )

        let packageIDByDatabaseID =
            makePackageIDMap(posts: posts)

        var archivePosts: [DiaryArchivePost] = []

        ////
        let relatedLinkCount =
            posts.reduce(0) {
                $0 + $1.links.count
            }

        let parentLinkCount =
            posts.filter {
                $0.parentPostId != nil
            }.count

        print(
            "Export診断 関連記事リンク:",
            relatedLinkCount
        )

        print(
            "Export診断 コメント親リンク:",
            parentLinkCount
        )
        ////
        
        
        var exportedMediaCount = 0
        var exportedLinkCount = 0
        
        ///
        let postsWithLinks = posts.filter {
            !$0.links.isEmpty
        }

        print()
        print("========== Export Link診断 ==========")
        print("Export対象投稿:", posts.count)
        print("リンクを持つ投稿:", postsWithLinks.count)

        for post in postsWithLinks {
            print(
                "POST:",
                post.id,
                "links:",
                post.links.count
            )

            for link in post.links {
                print(
                    "  ->",
                    link.toPostId
                )
            }
        }

        print(
            "links総数:",
            posts.reduce(0) {
                $0 + $1.links.count
            }
        )

        print("=====================================")
        ///
        for post in posts {

            guard
                let packagePostID =
                    packageIDByDatabaseID[post.id]
            else {
                throw ExportError.invalidPostID(
                    post.id
                )
            }

            let parentPackagePostID =
                try resolveParentPackageID(
                    for: post,
                    packageIDByDatabaseID:
                        packageIDByDatabaseID
                )

            let archiveMedia =
                try makeArchiveMedia(
                    post: post,
                    packagePostID: packagePostID,
                    packageURL: packageURL
                )
            
            let archiveLinks =
                try makeArchiveLinks(
                    post: post,
                    packageIDByDatabaseID:
                        packageIDByDatabaseID
                )

            exportedMediaCount +=
                archiveMedia.count

            exportedLinkCount +=
                archiveLinks.count

            let archivePost = DiaryArchivePost(
                id: packagePostID,

                type:
                    post.parentPostId == nil
                    ? .post
                    : .comment,

                title: nil,
                body: post.body,

                createdAt: post.createdAt,
                updatedAt: post.updatedAt,
                diaryDate: post.diaryDate,

                isFavorite: false,

                media: archiveMedia,
                links: archiveLinks,
                tags: [],

                source: DiaryArchiveSource(
                    system: "myDiary",
                    id: String(post.id)
                ),

                parentPostID:
                    parentPackagePostID
            )

            archivePosts.append(
                archivePost
            )
        }

        archivePosts.sort {
            if $0.diaryDate != $1.diaryDate {
                return $0.diaryDate < $1.diaryDate
            }

            return $0.id < $1.id
        }

        let archive = DiaryArchive(
            format: "myDiary",
            version: 1,

            generator: DiaryArchiveGenerator(
                application: "myDiary",
                version: "1.0"
            ),

            title: title,
            createdAt: Date(),

            posts: archivePosts
        )

        let jsonURL =
            packageURL.appendingPathComponent(
                "diary.json"
            )

        try writeArchive(
            archive,
            to: jsonURL
        )

        return ExportResult(
            exportedPostCount: archivePosts.count,
            exportedMediaCount: exportedMediaCount,
            exportedLinkCount: exportedLinkCount,
            outputURL: jsonURL
        )
    }

    // MARK: - Package IDs

    private func makePackageIDMap(
        posts: [DiaryPost]
    ) -> [Int64: String] {

        var result: [Int64: String] = [:]
        var usedIDs: Set<String> = []

        for post in posts {

            var packageID =
                post.packagePostID?
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )

            if packageID?.isEmpty != false {
                packageID = nil
            }

            var resolvedID =
                packageID
                ?? "mydiary-\(post.id)"

            /*
             万一packagePostIDが重複していた場合は、
             DB IDを加えて一意にする。
             */
            if usedIDs.contains(resolvedID) {
                resolvedID =
                    "\(resolvedID)-\(post.id)"
            }

            usedIDs.insert(
                resolvedID
            )

            result[post.id] =
                resolvedID
        }

        return result
    }

    // MARK: - Parent

    private func resolveParentPackageID(
        for post: DiaryPost,
        packageIDByDatabaseID:
            [Int64: String]
    ) throws -> String? {

        guard
            let parentPostId =
                post.parentPostId
        else {
            return nil
        }

        guard
            let packageID =
                packageIDByDatabaseID[
                    parentPostId
                ]
        else {
            throw ExportError.parentPostNotFound(
                parentPostId
            )
        }

        return packageID
    }

    // MARK: - Links

    private func makeArchiveLinks(
        post: DiaryPost,
        packageIDByDatabaseID:
            [Int64: String]
    ) throws -> [DiaryArchivePostLink] {

        var result: [DiaryArchivePostLink] = []

        for (
            index,
            link
        ) in post.links.enumerated() {

            guard
                let targetPackageID =
                    packageIDByDatabaseID[
                        link.toPostId
                    ]
            else {
                throw ExportError
                    .linkTargetNotFound(
                        link.toPostId
                    )
            }

            result.append(
                DiaryArchivePostLink(
                    target: targetPackageID,
                    sortOrder: index
                )
            )
        }

        return result
    }

    // MARK: - Media

    private func makeArchiveMedia(
        post: DiaryPost,
        packagePostID: String,
        packageURL: URL
    ) throws -> [DiaryArchiveMedia] {

        var result: [DiaryArchiveMedia] = []

        for (
            index,
            image
        ) in post.images.enumerated() {

            let exportedPaths =
                try ImageStore.shared.exportImage(
                    image,
                    to: packageURL
                )

            let archiveMedia =
                DiaryArchiveMedia(
                    id:
                        "\(packagePostID)-media-\(index + 1)",

                    type:
                        archiveMediaType(
                            from: image.sourceType
                        ),

                    path:
                        exportedPaths.path,

                    displayPath:
                        exportedPaths.displayPath,

                    thumbnailPath:
                        exportedPaths.thumbnailPath,

                    sourceURLString:
                        image.sourceURL?
                            .absoluteString,

                    originalExtension:
                        image.originalExtension,

                    width: nil,
                    height: nil,
                    caption: nil,
                    sortOrder: index
                )

            result.append(
                archiveMedia
            )
        }

        return result
    }
    
    private func archiveMediaType(
        from sourceType: ImageSourceType
    ) -> DiaryArchiveMediaType {

        switch sourceType {
        case .photo:
            return .photo

        case .youtube:
            return .youtube

        case .link:
            return .link

        case .generated:
            return .generated
        }
    }

    // MARK: - JSON

    private func writeArchive(
        _ archive: DiaryArchive,
        to url: URL
    ) throws {

        let encoder = JSONEncoder()

        encoder.outputFormatting = [
            .prettyPrinted,
            .sortedKeys,
            .withoutEscapingSlashes
        ]

        encoder.dateEncodingStrategy =
            .custom {
                date,
                encoder in

                var container =
                    encoder.singleValueContainer()

                try container.encode(
                    Self.dateFormatter.string(
                        from: date
                    )
                )
            }

        let data = try encoder.encode(
            archive
        )

        try data.write(
            to: url,
            options: .atomic
        )
    }

    private static let dateFormatter:
        DateFormatter = {

        let formatter = DateFormatter()

        formatter.locale =
            Locale(
                identifier: "en_US_POSIX"
            )

        formatter.calendar =
            Calendar(
                identifier: .gregorian
            )

        formatter.timeZone = .current

        formatter.dateFormat =
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"

        return formatter
    }()
}
