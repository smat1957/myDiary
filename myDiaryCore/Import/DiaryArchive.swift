//
//  DiaryArchive.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/11.
//

import Foundation

// MARK: - Root

struct DiaryArchive: Codable {

    let format: String
    let version: Int

    let generator: DiaryArchiveGenerator

    let title: String
    let createdAt: Date

    let posts: [DiaryArchivePost]

    enum CodingKeys: String, CodingKey {
        case format
        case version
        case generator
        case title
        case createdAt = "created_at"
        case posts
    }
}

// MARK: - Generator

struct DiaryArchiveGenerator: Codable {

    let application: String
    let version: String
}

// MARK: - Post

struct DiaryArchivePost: Codable {

    /// Diary Package内で一意のID
    let id: String

    let type: DiaryArchivePostType

    let title: String?
    let body: String

    let createdAt: Date
    let updatedAt: Date
    let diaryDate: Date

    let isFavorite: Bool

    let media: [DiaryArchiveMedia]
    let links: [DiaryArchivePostLink]
    let tags: [String]

    let source: DiaryArchiveSource?
    
    let parentPostID: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case title
        case body

        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case diaryDate = "diary_date"

        case isFavorite = "is_favorite"

        case media
        case links
        case tags
        case source
        
        case parentPostID = "parent_post_id"
    }
}

enum DiaryArchivePostType: String, Codable {
    case post
    case comment
}

// MARK: - Source

struct DiaryArchiveSource: Codable {

    let system: String
    let id: String?
}

// MARK: - Media
struct DiaryArchiveMedia: Codable, Identifiable {
    
    let id: String
    let type: DiaryArchiveMediaType
    
    let path: String?
    let displayPath: String?
    let thumbnailPath: String?
    
    let sourceURLString: String?
    
    let originalExtension: String?
    let width: Int?
    let height: Int?
    let caption: String?
    let sortOrder: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case path
        
        case displayPath = "display_path"
        case thumbnailPath = "thumbnail_path"
        
        case sourceURLString = "source_url"
        
        case originalExtension = "original_extension"
        case width
        case height
        case caption
        case sortOrder = "sort_order"
    }
    
    var sourceURL: URL? {
        guard let sourceURLString else {
            return nil
        }
        
        return Self.makeURL(from: sourceURLString)
    }
    
    private static func makeURL(from value: String) -> URL? {
        let trimmed = value.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmed.isEmpty else {
            return nil
        }

        if let url = URL(string: trimmed) {
            return url
        }

        guard let encoded = trimmed.addingPercentEncoding(
            withAllowedCharacters: .urlFragmentAllowed
        ),
        let url = URL(string: encoded)
        else {
            print("URL変換失敗:", value)
            return nil
        }

        print("URLをエンコードして使用:", value)
        return url
    }

}

enum DiaryArchiveMediaType: String, Codable {
    case photo
    case youtube
    case link
    case generated
    case video
    case audio
    case pdf
    case unknown

    var imageSourceType: ImageSourceType? {
        switch self {
        case .photo:
            return .photo

        case .youtube:
            return .youtube

        case .link:
            return .link

        case .generated:
            return .generated

        case .video, .audio, .pdf, .unknown:
            return nil
        }
    }
}

// MARK: - Post link

struct DiaryArchivePostLink: Codable {

    /// リンク先投稿のDiary Package ID
    let target: String

    let sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case target
        case sortOrder = "sort_order"
    }
}
