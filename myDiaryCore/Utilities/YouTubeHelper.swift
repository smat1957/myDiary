//
//  YouTubeHelper.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/08.
//

import Foundation

enum YouTubeHelper {

    static func videoID(from text: String) -> String? {
        guard let url = firstURL(in: text) else {
            return nil
        }

        return videoID(from: url)
    }

    static func videoID(from url: URL) -> String? {
        guard let host = url.host?.lowercased() else {
            return nil
        }

        if host.contains("youtu.be") {
            return url.pathComponents.dropFirst().first
        }

        if host.contains("youtube.com") {
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)

            if url.path == "/watch" {
                return components?
                    .queryItems?
                    .first(where: { $0.name == "v" })?
                    .value
            }

            if url.path.hasPrefix("/shorts/") {
                return url.pathComponents.dropFirst().first
            }

            if url.path.hasPrefix("/embed/") {
                return url.pathComponents.dropFirst().first
            }
        }

        return nil
    }

    static func thumbnailURL(videoID: String) -> URL {
        URL(string: "https://i.ytimg.com/vi/\(videoID)/hqdefault.jpg")!
    }
    
    private static func firstURL(in text: String) -> URL? {
        let detector = try? NSDataDetector(
            types: NSTextCheckingResult.CheckingType.link.rawValue
        )

        let range = NSRange(
            text.startIndex..<text.endIndex,
            in: text
        )

        return detector?
            .firstMatch(
                in: text,
                options: [],
                range: range
            )?
            .url
    }
    
    static func youtubeURLs(in text: String) -> [URL] {
        let detector = try? NSDataDetector(
            types: NSTextCheckingResult.CheckingType.link.rawValue
        )

        let range = NSRange(text.startIndex..<text.endIndex, in: text)

        let matches = detector?.matches(
            in: text,
            options: [],
            range: range
        ) ?? []

        return matches.compactMap { match in
            guard let url = match.url else { return nil }
            guard videoID(from: url) != nil else { return nil }
            return url
        }
    }
}
