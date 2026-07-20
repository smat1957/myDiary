//
//  ImageStore.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/06.
//

import Foundation
import GRDB

enum ImageKind {
    case original
    case display
    case thumbnail

    var extensionName: String {
        switch self {
        case .original:
            return ""
        case .display, .thumbnail:
            return "jpg"
        }
    }
}

final class ImageStore {

    static let shared = ImageStore()

    let picturesFolder: URL

    private init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!

        let diaryFolder = appSupport.appendingPathComponent("myDiary")
        picturesFolder = diaryFolder.appendingPathComponent("pictures")

        for source in [
            ImageSourceType.photo,
            .youtube,
            .link,
            .generated
        ] {
            for kind in [
                ImageKind.original,
                .display,
                .thumbnail
            ] {
                try? FileManager.default.createDirectory(
                    at: folder(for: source, kind: kind),
                    withIntermediateDirectories: true
                )
            }
        }
    }

    // MARK: - Public import methods

    func importImage(
        from sourceURL: URL,
        date: Date = Date()
    ) throws -> DiaryImage {

        let accessing = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        return try importPreparedImage(
            from: sourceURL,
            originalExtension: normalizedExtension(from: sourceURL),
            sourceType: .photo,
            sourceURLForRecord: nil,
            date: date
        )
    }

    func importYoutubeThumbnail(
        from youtubeURL: URL,
        date: Date = Date()
    ) async throws -> DiaryImage {

        guard let videoID = YouTubeHelper.videoID(from: youtubeURL) else {
            throw NSError(
                domain: "ImageStore",
                code: 10,
                userInfo: [NSLocalizedDescriptionKey: "YouTube video ID を取得できません"]
            )
        }

        let thumbnailURL = YouTubeHelper.thumbnailURL(videoID: videoID)

        let tempURL = try await downloadImageToTemporaryFile(
            from: thumbnailURL,
            extensionName: "jpg"
        )

        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }

        return try importPreparedImage(
            from: tempURL,
            originalExtension: "jpg",
            sourceType: .youtube,
            sourceURLForRecord: youtubeURL,
            date: date
        )
    }

    func importLinkPreview(
        from pageURL: URL,
        date: Date = Date()
    ) async throws -> DiaryImage {

        if let cachedImage = try loadCachedImage(
            sourceURL: pageURL
        ) {
            return cachedImage
        }

        guard let imageURL =
            try await LinkPreviewHelper.ogImageURL(
                from: pageURL
            )
        else {
            throw NSError(
                domain: "ImageStore",
                code: 20,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "OGP画像が見つかりません"
                ]
            )
        }

        let tempURL = try await downloadImageToTemporaryFile(
            from: imageURL,
            extensionName: "jpg"
        )

        defer {
            try? FileManager.default.removeItem(
                at: tempURL
            )
        }

        let image = try importPreparedImage(
            from: tempURL,
            originalExtension: "jpg",
            sourceType: .link,
            sourceURLForRecord: pageURL,
            date: date
        )

        try saveCachedImage(
            sourceType: .link,
            sourceURL: pageURL.absoluteString,
            image: image
        )

        return image
    }

    // MARK: - URL

    func url(
        for image: DiaryImage,
        kind: ImageKind
    ) -> URL {

        let ext = kind == .original
            ? image.originalExtension
            : kind.extensionName

        return folder(for: image.sourceType, kind: kind)
            .appendingPathComponent(image.baseName)
            .appendingPathExtension(ext)
    }

    func delete(_ image: DiaryImage) {
        try? FileManager.default.removeItem(
            at: url(for: image, kind: .original)
        )

        try? FileManager.default.removeItem(
            at: url(for: image, kind: .display)
        )

        try? FileManager.default.removeItem(
            at: url(for: image, kind: .thumbnail)
        )
    }
    
    // MARK: - Cached images
    func loadCachedImage(
        sourceURL: URL
    ) throws -> DiaryImage? {

        guard let record = try findCachedImage(
            sourceURL: sourceURL.absoluteString
        ) else {
            return nil
        }

        guard let sourceType = ImageSourceType(
            rawValue: record.sourceType
        ) else {
            return nil
        }

        let image = DiaryImage(
            baseName: record.baseName,
            originalExtension: record.originalExtension,
            sourceType: sourceType,
            sourceURL: URL(string: record.sourceURL)
        )

        let originalURL = url(
            for: image,
            kind: .original
        )
        
        guard FileManager.default.fileExists(
            atPath: originalURL.path
        ) else {
            try deleteCachedImage(
                sourceURL: record.sourceURL
            )
            return nil
        }

        return image
    }
    
    func findCachedImage(
        sourceURL: String
    ) throws -> CachedImageRecord? {

        try DatabaseManager.shared.dbQueue.read { db in
            try CachedImageRecord
                .filter(Column("sourceURL") == sourceURL)
                .fetchOne(db)
        }
    }
    
    func hasCachedImage(
        sourceURL: URL
    ) -> Bool {

        (try? findCachedImage(
            sourceURL: sourceURL.absoluteString
        )) != nil
    }
    
    func saveCachedImage(
        sourceType: ImageSourceType,
        sourceURL: String,
        image: DiaryImage
    ) throws {

        try DatabaseManager.shared.dbQueue.write { db in

            let existingRecord = try CachedImageRecord
                .filter(Column("sourceURL") == sourceURL)
                .fetchOne(db)

            guard existingRecord == nil else {
                return
            }

            var record = CachedImageRecord(
                id: nil,
                sourceType: sourceType.rawValue,
                sourceURL: sourceURL,
                baseName: image.baseName,
                originalExtension: image.originalExtension,
                createdAt: Date()
            )

            try record.insert(db)
        }
    }

    func deleteCachedImage(
        sourceURL: String
    ) throws {

        try DatabaseManager.shared.dbQueue.write { db in
            _ = try CachedImageRecord
                .filter(Column("sourceURL") == sourceURL)
                .deleteAll(db)
        }
    }
    
    func findCachedLinkImage(
        for url: URL,
        in images: [DiaryImage]
    ) -> DiaryImage? {

        let key = normalizedURLKey(url)

        return images.first {

            $0.sourceType == .link
            && $0.sourceURL.map(normalizedURLKey) == key
        }
    }
    
    // MARK: - Core import

    private func importPreparedImage(
        from sourceURL: URL,
        originalExtension: String,
        sourceType: ImageSourceType,
        sourceURLForRecord: URL?,
        date: Date
    ) throws -> DiaryImage {

        let baseName = makeBaseName(date: date)

        let diaryImage = DiaryImage(
            baseName: baseName,
            originalExtension: originalExtension,
            sourceType: sourceType,
            sourceURL: sourceURLForRecord
        )

        let originalURL = url(for: diaryImage, kind: .original)
        let displayURL = url(for: diaryImage, kind: .display)
        let thumbnailURL = url(for: diaryImage, kind: .thumbnail)

        try ensureParentDirectory(of: originalURL)
        try ensureParentDirectory(of: displayURL)
        try ensureParentDirectory(of: thumbnailURL)

        try FileManager.default.copyItem(
            at: sourceURL,
            to: originalURL
        )

        try autoreleasepool {
            try ImageResizer.createResizedJPEG(
                sourceURL: originalURL,
                destinationURL: displayURL,
                maxPixelSize: 2500
            )
        }

        try autoreleasepool {
            try ImageResizer.createResizedJPEG(
                sourceURL: originalURL,
                destinationURL: thumbnailURL,
                maxPixelSize: 600
            )
        }
        
        /*
        try autoreleasepool {
            try createResizedJPEG(
                sourceURL: originalURL,
                destinationURL: displayURL,
                maxPixelSize: 2500
            )
        }
        try autoreleasepool {
            try createResizedJPEG(
                sourceURL: originalURL,
                destinationURL: thumbnailURL,
                maxPixelSize: 600
            )
        }
*/
        return diaryImage
    }

    func importPackagedMedia(
        from fileURL: URL,
        sourceType: ImageSourceType,
        sourceURL: URL?,
        originalExtension: String?,
        date: Date = Date()
    ) throws -> DiaryImage {

        let ext = originalExtension
            ?? normalizedExtension(from: fileURL)

        return try importPreparedImage(
            from: fileURL,
            originalExtension: ext,
            sourceType: sourceType,
            sourceURLForRecord: sourceURL,
            date: date
        )
    }
    
    // MARK: - Folder

    private func folder(
        for source: ImageSourceType,
        kind: ImageKind
    ) -> URL {

        let sourceFolder = picturesFolder
            .appendingPathComponent(source.rawValue)

        switch kind {
        case .original:
            return sourceFolder.appendingPathComponent("original")
        case .display:
            return sourceFolder.appendingPathComponent("display")
        case .thumbnail:
            return sourceFolder.appendingPathComponent("thumbnail")
        }
    }

    // MARK: - Export

    struct ExportedImagePaths {
        let path: String
        let displayPath: String
        let thumbnailPath: String
    }

    func exportImage(
        _ image: DiaryImage,
        to packageRoot: URL
    ) throws -> ExportedImagePaths {

        //let fileManager = FileManager.default

        let sourceOriginalURL = url(
            for: image,
            kind: .original
        )

        let sourceDisplayURL = url(
            for: image,
            kind: .display
        )

        let sourceThumbnailURL = url(
            for: image,
            kind: .thumbnail
        )

        let sourceFolderName =
            image.sourceType.rawValue

        let relativeOriginalPath =
            "pictures/\(sourceFolderName)/original/"
            + image.baseName
            + "."
            + image.originalExtension

        let relativeDisplayPath =
            "pictures/\(sourceFolderName)/display/"
            + image.baseName
            + ".jpg"

        let relativeThumbnailPath =
            "pictures/\(sourceFolderName)/thumbnail/"
            + image.baseName
            + ".jpg"

        let destinationOriginalURL =
            packageRoot.appendingPathComponent(
                relativeOriginalPath
            )

        let destinationDisplayURL =
            packageRoot.appendingPathComponent(
                relativeDisplayPath
            )

        let destinationThumbnailURL =
            packageRoot.appendingPathComponent(
                relativeThumbnailPath
            )

        try ensureParentDirectory(
            of: destinationOriginalURL
        )

        try ensureParentDirectory(
            of: destinationDisplayURL
        )

        try ensureParentDirectory(
            of: destinationThumbnailURL
        )

        try copyReplacingExisting(
            from: sourceOriginalURL,
            to: destinationOriginalURL
        )

        try copyReplacingExisting(
            from: sourceDisplayURL,
            to: destinationDisplayURL
        )

        try copyReplacingExisting(
            from: sourceThumbnailURL,
            to: destinationThumbnailURL
        )

        return ExportedImagePaths(
            path: relativeOriginalPath,
            displayPath: relativeDisplayPath,
            thumbnailPath: relativeThumbnailPath
        )
    }

    private func copyReplacingExisting(
        from sourceURL: URL,
        to destinationURL: URL
    ) throws {

        let fileManager = FileManager.default

        if fileManager.fileExists(
            atPath: destinationURL.path
        ) {
            try fileManager.removeItem(
                at: destinationURL
            )
        }

        try fileManager.copyItem(
            at: sourceURL,
            to: destinationURL
        )
    }
    
    // MARK: - Utilities
    
    private func normalizedURLKey(_ url: URL) -> String {

        var components = URLComponents(
            url: url,
            resolvingAgainstBaseURL: false
        )

        components?.fragment = nil

        return components?
            .url?
            .absoluteString
            .lowercased()
            ?? url.absoluteString.lowercased()
    }
    
    private func makeBaseName(date: Date) -> String {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"

        let datePart = formatter.string(from: date)
        let uniquePart = String(UUID().uuidString.prefix(8))

        return "\(year)/\(String(format: "%02d", month))/\(datePart)_\(uniquePart)"
    }

    private func normalizedExtension(from url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        return ext.isEmpty ? "jpg" : ext
    }

    private func ensureParentDirectory(of url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
    }

    private func downloadImageToTemporaryFile(
        from url: URL,
        extensionName: String
    ) async throws -> URL {

        let (data, _) = try await URLSession.shared.data(from: url)

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(extensionName)

        try data.write(to: tempURL)

        return tempURL
    }

}
