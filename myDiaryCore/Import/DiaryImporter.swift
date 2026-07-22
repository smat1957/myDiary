//
//  DiaryImporter.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/10.
//

import Foundation

final class DiaryImporter {

    struct ImportResult {
        let importedPostCount: Int
        let skippedPostCount: Int

        let importedMediaCount: Int
        let importedLinkCount: Int
        let skippedMediaCount: Int
    }
    
    private let repository: PostRepository
    private let imageStore: ImageStore
    private let progress: ImportProgressState?
    
    init(
        repository: PostRepository = PostRepository(),
        imageStore: ImageStore = .shared,
        progress: ImportProgressState? = nil
    ) {
        self.repository = repository
        self.imageStore = imageStore
        self.progress = progress
    }

    /*
    func importPackage(
        from packageURL: URL
    ) async throws -> ImportResult {

        // diary.json 読み込み
        // archive decode

        var importedPostIDs: [String: Int64] = [:]
        var insertedPosts: [String: DiaryPost] = [:]

        // =============================================
        // 第1パス
        // 投稿とメディアを登録
        // =============================================

        for archivePost in archive.posts {

            // 既存投稿なら
            // importedPostIDs に既存DB IDを登録してスキップ

            // 新規投稿なら
            // media import
            // repository.insert()
            // importedPostIDs に新DB IDを登録
            // insertedPosts に保持
        }


        // =============================================
        // 第2パス
        // parent_post_id を設定
        // =============================================

        var importedParentLinkCount = 0

        for archivePost in archive.posts {

            guard
                let parentPackagePostID =
                    archivePost.parentPostID
            else {
                continue
            }

            guard
                let commentPostID =
                    importedPostIDs[archivePost.id],
                let parentPostID =
                    importedPostIDs[parentPackagePostID]
            else {
                continue
            }

            guard commentPostID != parentPostID else {
                continue
            }

            guard
                var commentPost =
                    insertedPosts[archivePost.id]
            else {
                continue
            }

            commentPost.parentPostId =
                parentPostID

            try repository.update(
                commentPost
            )

            insertedPosts[archivePost.id] =
                commentPost

            importedParentLinkCount += 1
        }


        // =============================================
        // 第3パス
        // 通常の PostLink を登録
        // =============================================

        var importedLinkCount = 0
         for archivePost in archive.posts {

             guard newlyInsertedPackageIDs.contains(
                 archivePost.id
             ) else {
                 continue
             }

             guard
                 let sourcePostID =
                     importedPostIDs[archivePost.id],

                 var sourcePost =
                     insertedPosts[archivePost.id]
             else {
                 continue
             }

             let sortedLinks = archivePost.links.sorted {
                 $0.sortOrder < $1.sortOrder
             }

             var postLinks: [PostLink] = []

             for archiveLink in sortedLinks {

                 guard
                     let targetPostID =
                         importedPostIDs[archiveLink.target]
                 else {
                     print(
                         "リンク先投稿が見つかりません:",
                         archiveLink.target
                     )
                     continue
                 }

                 /*
                  自分自身へのリンクは登録しない。
                  */
                 guard sourcePostID != targetPostID else {
                     continue
                 }

                 postLinks.append(
                     PostLink(
                         fromPostId: sourcePostID,
                         toPostId: targetPostID,
                         sortOrder: postLinks.count
                     )
                 )

                 importedLinkCount += 1
             }

             if !postLinks.isEmpty {
                 sourcePost.links = postLinks
                 try repository.update(sourcePost)
             }
         }
        //for archivePost in archive.posts {

            // 現在の links 処理
        //}


        return ImportResult(
            importedPostCount: importedPostCount,
            skippedPostCount: skippedPostCount,
            importedMediaCount: importedMediaCount,
            importedLinkCount: importedLinkCount,
            skippedMediaCount: skippedMediaCount
        )
    }
    */

    func importPackage(
        from packageURL: URL
    ) async throws -> ImportResult {
                
        do{
            let accessing =
                packageURL.startAccessingSecurityScopedResource()

            defer {
                if accessing {
                    packageURL.stopAccessingSecurityScopedResource()
                }
            }
                    
            let jsonURL = packageURL
                .appendingPathComponent("diary.json")

            guard FileManager.default.fileExists(
                atPath: jsonURL.path
            ) else {
                throw ImportError.diaryJSONNotFound
            }
                    
            let archive = try decodeArchive(
                from: jsonURL
            )

            guard archive.format == "myDiary" else {
                throw ImportError.invalidFormat(
                    archive.format
                )
            }
            
            guard archive.version == 1 else {
                throw ImportError.unsupportedVersion(
                    archive.version
                )
            }

            let packageRoot = packageURL
            
            await MainActor.run {
                progress?.start(
                    total: archive.posts.count
                )
            }
            
            /*
             Diary Package側の投稿ID
                ↓
             SQLite側の投稿ID
             */
            var importedPostIDs: [String: Int64] = [:]

            /*
             投稿間リンクを後から登録するため、
             SQLite登録後のDiaryPostを保持する。
             */
            var insertedPosts: [String: DiaryPost] = [:]

            /*
             今回、新しく登録した投稿だけを記録する。
             再Import時に既存投稿のリンクを上書きしないため。
             */
            var newlyInsertedPackageIDs: Set<String> = []

            var importedPostCount = 0
            var skippedPostCount = 0

            var importedMediaCount = 0
            var skippedMediaCount = 0

            // MARK: - 第1段階
            // 投稿とメディアを登録する

            //for archivePost in archive.posts {
            for (
                index,
                archivePost
            ) in archive.posts.enumerated() {

                await MainActor.run {
                    progress?.update(
                        current: index + 1,
                        phase: .importingPosts,
                        //message: String(
                        //    localized:
                        //        "import.progress.importingPosts"
                        //),
                        detail: archivePost.diaryDate.formatted(
                            date: .numeric,
                            time: .shortened
                        )
                    )
                }
                
                /*
                 重複チェックは画像コピーより前に行う。
                 同じpackagePostIDが既にあれば、投稿全体をスキップする。
                 */
                if let existingPost =
                    try repository.fetchByPackagePostID(
                        archivePost.id
                    )
                {
                    importedPostIDs[archivePost.id] =
                        existingPost.id

                    insertedPosts[archivePost.id] =
                        existingPost

                    skippedPostCount += 1

                    print(
                        "既存投稿をスキップ:",
                        archivePost.id
                    )

                    continue
                }

                var images: [DiaryImage] = []

                let sortedMedia = archivePost.media.sorted {
                    $0.sortOrder < $1.sortOrder
                }

                for media in sortedMedia {
                    
                    await MainActor.run {
                        progress?.update(
                            current: index + 1,
                            phase: .copyingMedia,
                            //message: String(
                            //    localized:
                            //        "import.progress.copyingMedia"
                            //),
                            detail:
                                media.path ?? ""
                        )
                    }
                    
                    do {
                        if let image = try await importMedia(
                            media,
                            packageRoot: packageRoot,
                            postDate: archivePost.diaryDate
                        ) {
                            images.append(image)
                            importedMediaCount += 1
                        } else {
                            skippedMediaCount += 1
                        }

                    } catch {
                        print(
                            "メディアImport失敗:",
                            media.id,
                            error.localizedDescription
                        )

                        skippedMediaCount += 1
                    }
                }

                let post = DiaryPost(
                    packagePostID: archivePost.id,
                    body: archivePost.body,
                    diaryDate: archivePost.diaryDate,
                    createdAt: archivePost.createdAt,
                    updatedAt: archivePost.updatedAt,
                    images: images,
                    links: []
                )

                let newPostID = try repository.insert(post)

                let insertedPost = DiaryPost(
                    id: newPostID,
                    packagePostID: archivePost.id,
                    body: archivePost.body,
                    diaryDate: archivePost.diaryDate,
                    createdAt: archivePost.createdAt,
                    updatedAt: archivePost.updatedAt,
                    images: images,
                    links: []
                )

                importedPostIDs[archivePost.id] =
                    newPostID

                insertedPosts[archivePost.id] =
                    insertedPost

                newlyInsertedPackageIDs.insert(
                    archivePost.id
                )

                importedPostCount += 1
            }

            // MARK: - 第2段階
            
            // -----------------------------------------------------
            // コメントの parent_post_id を myDiary内部IDへ変換して保存
            // -----------------------------------------------------

            var importedParentLinkCount = 0

            for archivePost in archive.posts {
                
                guard
                    let parentPackagePostID =
                        archivePost.parentPostID
                else {
                    continue
                }

                guard
                    let commentPostID =
                        importedPostIDs[archivePost.id]
                else {
                    print(
                        "コメント投稿IDが見つかりません:",
                        archivePost.id
                    )
                    continue
                }

                guard
                    let parentPostID =
                        importedPostIDs[parentPackagePostID]
                else {
                    print(
                        "親投稿が見つかりません:",
                        archivePost.id,
                        "->",
                        parentPackagePostID
                    )
                    continue
                }

                // 自分自身を親にはしない
                guard commentPostID != parentPostID else {
                    continue
                }

                guard
                    var commentPost =
                        insertedPosts[archivePost.id]
                else {
                    print(
                        "コメント投稿を取得できません:",
                        archivePost.id
                    )
                    continue
                }

                commentPost.parentPostId =
                    parentPostID

                try repository.update(
                    commentPost
                )

                insertedPosts[archivePost.id] =
                    commentPost

                importedParentLinkCount += 1

                print(
                    "コメント親投稿を設定:",
                    archivePost.id,
                    "->",
                    parentPackagePostID,
                    "(DB:",
                    commentPostID,
                    "->",
                    parentPostID,
                    ")"
                )
            }
            
            // 新規登録した投稿だけ、投稿間リンクを復元する

            var importedLinkCount = 0

            for archivePost in archive.posts {

                guard newlyInsertedPackageIDs.contains(
                    archivePost.id
                ) else {
                    continue
                }

                guard
                    let sourcePostID =
                        importedPostIDs[archivePost.id],

                    var sourcePost =
                        insertedPosts[archivePost.id]
                else {
                    continue
                }

                let sortedLinks = archivePost.links.sorted {
                    $0.sortOrder < $1.sortOrder
                }

                var postLinks: [PostLink] = []

                for archiveLink in sortedLinks {

                    guard
                        let targetPostID =
                            importedPostIDs[archiveLink.target]
                    else {
                        print(
                            "リンク先投稿が見つかりません:",
                            archiveLink.target
                        )
                        continue
                    }

                    /*
                     自分自身へのリンクは登録しない。
                     */
                    guard sourcePostID != targetPostID else {
                        continue
                    }

                    postLinks.append(
                        PostLink(
                            fromPostId: sourcePostID,
                            toPostId: targetPostID,
                            sortOrder: postLinks.count
                        )
                    )

                    importedLinkCount += 1
                }

                if !postLinks.isEmpty {
                    sourcePost.links = postLinks
                    try repository.update(sourcePost)
                }
            }
            
            await MainActor.run {
                progress?.complete()
            }
            
            return ImportResult(
                importedPostCount: importedPostCount,
                skippedPostCount: skippedPostCount,
                importedMediaCount: importedMediaCount,
                importedLinkCount: importedLinkCount,
                skippedMediaCount: skippedMediaCount
            )
        }
        catch {

            await MainActor.run {
                progress?.fail(error)
            }

            throw error
        }
    }
    
    
    // MARK: - Media
    private func importMedia(
        _ media: DiaryArchiveMedia,
        packageRoot: URL,
        postDate: Date
    ) async throws -> DiaryImage? {

        guard
            let sourceType = media.type.imageSourceType
        else {
            return nil
        }

        guard let relativePath = media.path else {
            print(
                "Package内ファイルがないためスキップ:",
                media.id,
                media.sourceURLString ?? ""
            )
            return nil
        }

        let fileURL = packageRoot
            .appendingPathComponent(relativePath)

        guard FileManager.default.fileExists(
            atPath: fileURL.path
        ) else {
            throw ImportError.mediaFileNotFound(
                relativePath
            )
        }

        return try imageStore.importPackagedMedia(
            from: fileURL,
            sourceType: sourceType,
            sourceURL: media.sourceURL,
            originalExtension: media.originalExtension,
            date: postDate
        )
    }

    // MARK: - Decode

    private func decodeArchive(
        from jsonURL: URL
    ) throws -> DiaryArchive {

        let data = try Data(contentsOf: jsonURL)

        //print("DEBUG: decodeArchive Start \(data.count) bytes")

        let decoder = JSONDecoder()
                
        decoder.dateDecodingStrategy = .custom {
            decoder in

            let container =
                try decoder.singleValueContainer()

            let value =
                try container.decode(String.self)

            guard let date = Self.parseDate(value) else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription:
                        "日付を解析できません: \(value)"
                )
            }

            return date
        }
        
        do {
            return try decoder.decode(
                DiaryArchive.self,
                from: data
            )

        } catch let DecodingError.keyNotFound(key, context) {
            print("DecodingError.keyNotFound")
            print("key:", key.stringValue)
            print("path:", context.codingPath.map(\.stringValue).joined(separator: "."))
            print("description:", context.debugDescription)
            throw ImportError.invalidJSON(
                DecodingError.keyNotFound(key, context)
            )

        } catch let DecodingError.typeMismatch(type, context) {
            print("DecodingError.typeMismatch")
            print("type:", type)
            print("path:", context.codingPath.map(\.stringValue).joined(separator: "."))
            print("description:", context.debugDescription)
            throw ImportError.invalidJSON(
                DecodingError.typeMismatch(type, context)
            )

        } catch let DecodingError.valueNotFound(type, context) {
            print("DecodingError.valueNotFound")
            print("type:", type)
            print("path:", context.codingPath.map(\.stringValue).joined(separator: "."))
            print("description:", context.debugDescription)
            throw ImportError.invalidJSON(
                DecodingError.valueNotFound(type, context)
            )

        } catch let DecodingError.dataCorrupted(context) {
            print("DecodingError.dataCorrupted")
            print("path:", context.codingPath.map(\.stringValue).joined(separator: "."))
            print("description:", context.debugDescription)
            throw ImportError.invalidJSON(
                DecodingError.dataCorrupted(context)
            )

        } catch {
            print("その他のデコードエラー:", error)
            throw ImportError.invalidJSON(error)
        }
        
    }
    
    private static func parseDate(_ value: String) -> Date? {

        // タイムゾーン付きISO 8601
        if let date = fractionalISOFormatter.date(from: value) {
            return date
        }

        if let date = regularISOFormatter.date(from: value) {
            return date
        }

        // タイムゾーンなし・小数秒あり
        if let date = localFractionalDateFormatter.date(from: value) {
            return date
        }

        // タイムゾーンなし・小数秒なし
        return localDateFormatter.date(from: value)
    }
    
    private static let fractionalISOFormatter:
        ISO8601DateFormatter = {

        let formatter = ISO8601DateFormatter()

        formatter.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]

        return formatter
    }()

    private static let regularISOFormatter:
        ISO8601DateFormatter = {

        let formatter = ISO8601DateFormatter()

        formatter.formatOptions = [
            .withInternetDateTime
        ]

        return formatter
    }()

    private static let localFractionalDateFormatter: DateFormatter = {
        let formatter = DateFormatter()

        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current

        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"

        return formatter
    }()
    
    private static let localDateFormatter:
        DateFormatter = {

        let formatter = DateFormatter()

        formatter.locale =
            Locale(identifier: "en_US_POSIX")

        formatter.calendar =
            Calendar(identifier: .gregorian)

        formatter.timeZone = .current

        formatter.dateFormat =
            "yyyy-MM-dd'T'HH:mm:ss"

        return formatter
    }()
}

// MARK: - Errors

extension DiaryImporter {

    enum ImportError: LocalizedError {
        
        case diaryJSONNotFound
        case invalidFormat(String)
        case unsupportedVersion(Int)

        case invalidJSON(Error)

        case mediaFileNotFound(String)
        case missingMediaPath(String)
        case missingSourceURL(String)

        var errorDescription: String? {

            switch self {
                
            case .diaryJSONNotFound:
                return """
                選択したフォルダ内に diary.json がありません。
                Diary Packageフォルダを選択してください。
                """

            case .invalidFormat(let format):
                return """
                myDiary形式ではありません。
                format: \(format)
                """

            case .unsupportedVersion(let version):
                return """
                対応していないDiary Packageの
                バージョンです: \(version)
                """

            case .invalidJSON(let error):
                return """
                JSONの読み込みに失敗しました。
                \(error.localizedDescription)
                """

            case .mediaFileNotFound(let path):
                return """
                Diary Package内に画像がありません。
                \(path)
                """

            case .missingMediaPath(let mediaID):
                return """
                メディアのpathがありません。
                \(mediaID)
                """

            case .missingSourceURL(let mediaID):
                return """
                メディアのsource_urlがありません。
                \(mediaID)
                """
            }
        }
    }
}
