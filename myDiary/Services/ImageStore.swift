//
//  ImageStore.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/06.
//

import Foundation
import AppKit

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
                
        guard let imageURL = try await LinkPreviewHelper.ogImageURL(from: pageURL) else {
            throw NSError(
                domain: "ImageStore",
                code: 20,
                userInfo: [NSLocalizedDescriptionKey: "OGP画像が見つかりません"]
            )
        }

        let tempURL = try await downloadImageToTemporaryFile(
            from: imageURL,
            extensionName: "jpg"
        )

        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }

        return try importPreparedImage(
            from: tempURL,
            originalExtension: "jpg",
            sourceType: .link,
            sourceURLForRecord: pageURL,
            date: date
        )
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

    // MARK: - Utilities

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

    private func createResizedJPEG(
        sourceURL: URL,
        destinationURL: URL,
        maxPixelSize: CGFloat
    ) throws {

        guard let image = NSImage(contentsOf: sourceURL) else {
            throw NSError(
                domain: "ImageStore",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "画像を読み込めません"]
            )
        }

        let originalSize = image.size

        let scale = min(
            maxPixelSize / originalSize.width,
            maxPixelSize / originalSize.height,
            1.0
        )

        let resizedSize = NSSize(
            width: originalSize.width * scale,
            height: originalSize.height * scale
        )

        let resizedImage = NSImage(size: resizedSize)
        resizedImage.lockFocus()
        image.draw(
            in: NSRect(origin: .zero, size: resizedSize),
            from: NSRect(origin: .zero, size: originalSize),
            operation: .copy,
            fraction: 1.0
        )
        resizedImage.unlockFocus()

        guard
            let tiffData = resizedImage.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffData),
            let jpegData = bitmap.representation(
                using: .jpeg,
                properties: [.compressionFactor: 0.85]
            )
        else {
            throw NSError(
                domain: "ImageStore",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "JPEG作成に失敗しました"]
            )
        }

        try jpegData.write(to: destinationURL)
    }
}
