//
//  LinkPreviewHelper.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/09.
//

import Foundation

enum LinkPreviewHelper {

    static func firstNonYouTubeURL(in text: String) -> URL? {
        allURLs(in: text).first { url in
            YouTubeHelper.videoID(from: url) == nil
        }
    }

    static func allNonYouTubeURLs(in text: String) -> [URL] {
        allURLs(in: text).filter { url in
            YouTubeHelper.videoID(from: url) == nil
        }
    }
    
    static func ogImageURL(from pageURL: URL) async throws -> URL? {
        let (data, response) = try await URLSession.shared.data(from: pageURL)

        guard
            let http = response as? HTTPURLResponse,
            (200..<300).contains(http.statusCode),
            let html = String(data: data, encoding: .utf8)
                ?? String(data: data, encoding: .shiftJIS)
        else {
            return nil
        }

        return extractOGImageURL(fromHTML: html, baseURL: pageURL)
    }
    
    private static func extractOGImageURL(
        fromHTML html: String,
        baseURL: URL
    ) -> URL? {

        let patterns = [

            // Open Graph
            #"<meta[^>]+property=["']og:image["'][^>]+content=["']([^"']+)["'][^>]*>"#,
            #"<meta[^>]+content=["']([^"']+)["'][^>]+property=["']og:image["'][^>]*>"#,

            // Twitter Card
            #"<meta[^>]+name=["']twitter:image["'][^>]+content=["']([^"']+)["'][^>]*>"#,
            #"<meta[^>]+content=["']([^"']+)["'][^>]+name=["']twitter:image["'][^>]*>"#,

            #"<meta[^>]+property=["']twitter:image["'][^>]+content=["']([^"']+)["'][^>]*>"#,
            #"<meta[^>]+content=["']([^"']+)["'][^>]+property=["']twitter:image["'][^>]*>"#,

            // 古い Twitter Card
            #"<meta[^>]+name=["']twitter:image:src["'][^>]+content=["']([^"']+)["'][^>]*>"#,
            #"<meta[^>]+content=["']([^"']+)["'][^>]+name=["']twitter:image:src["'][^>]*>"#,

            // image_src
            #"<link[^>]+rel=["']image_src["'][^>]+href=["']([^"']+)["'][^>]*>"#,
            #"<link[^>]+href=["']([^"']+)["'][^>]+rel=["']image_src["'][^>]*>"#,

            // favicon
            #"<link[^>]+rel=["'][^"']*icon[^"']*["'][^>]+href=["']([^"']+)["'][^>]*>"#,
            #"<link[^>]+href=["']([^"']+)["'][^>]+rel=["'][^"']*icon[^"']*["'][^>]*>"#
        ]

        for pattern in patterns {

            if let value = firstCapture(
                in: html,
                pattern: pattern
            ) {

                return URL(
                    string: value,
                    relativeTo: baseURL
                )?.absoluteURL
            }
        }

        // 最後の保険
        return URL(
            string: "/favicon.ico",
            relativeTo: baseURL
        )?.absoluteURL
    }
    
    /*
    private static func extractOGImageURL(
        fromHTML html: String,
        baseURL: URL
    ) -> URL? {

        let patterns = [
            #"<meta[^>]+property=["']og:image["'][^>]+content=["']([^"']+)["'][^>]*>"#,
            #"<meta[^>]+content=["']([^"']+)["'][^>]+property=["']og:image["'][^>]*>"#,
            #"<meta[^>]+name=["']twitter:image["'][^>]+content=["']([^"']+)["'][^>]*>"#,
            #"<meta[^>]+content=["']([^"']+)["'][^>]+name=["']twitter:image["'][^>]*>"#
        ]

        for pattern in patterns {
            if let value = firstCapture(in: html, pattern: pattern) {
                return URL(string: value, relativeTo: baseURL)?.absoluteURL
            }
        }

        return nil
    }
     */
    
    private static func firstCapture(
        in text: String,
        pattern: String
    ) -> String? {

        guard let regex = try? NSRegularExpression(
            pattern: pattern,
            options: [.caseInsensitive]
        ) else {
            return nil
        }

        let range = NSRange(text.startIndex..<text.endIndex, in: text)

        guard
            let match = regex.firstMatch(in: text, range: range),
            match.numberOfRanges >= 2,
            let captureRange = Range(match.range(at: 1), in: text)
        else {
            return nil
        }

        return String(text[captureRange])
    }

    private static func allURLs(in text: String) -> [URL] {
        let detector = try? NSDataDetector(
            types: NSTextCheckingResult.CheckingType.link.rawValue
        )

        let range = NSRange(text.startIndex..<text.endIndex, in: text)

        let matches = detector?.matches(
            in: text,
            options: [],
            range: range
        ) ?? []

        return matches.compactMap { $0.url }
    }
}
