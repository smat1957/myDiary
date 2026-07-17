//
//  TimelineSearchResult.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/16.
//
//
//  TimelineSearchResult.swift
//  myDiary
//

import Foundation

struct TimelineSearchResult: Identifiable {

    let post: DiaryPost

    var id: Int64 {
        post.id
    }

    var summary: String {
        let trimmed = post.body
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .replacingOccurrences(
                of: "\n",
                with: " "
            )

        if trimmed.isEmpty {
            return "本文なし"
        }

        return trimmed
    }

    var isComment: Bool {
        post.parentPostId != nil
    }
}

