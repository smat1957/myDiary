//
//  TimelineViewModel+Search.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/16.
//

//
//  TimelineViewModel+Search.swift
//  myDiary
//

import Foundation

extension TimelineViewModel {

    // MARK: - Search

    func searchPosts(
        keyword: String,
        date: Date?,
        caseSensitive: Bool
    ) -> [TimelineSearchResult] {

        let words = keyword
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)

        guard !words.isEmpty || date != nil else {
            return []
        }

        let calendar = Calendar.current

        return posts
            .filter { post in

                // 日付が指定されていれば同じ日の投稿だけにする
                if let date,
                   !calendar.isDate(
                        post.diaryDate,
                        inSameDayAs: date
                   ) {
                    return false
                }

                // キーワードがなければ日付条件だけで一致
                guard !words.isEmpty else {
                    return true
                }

                // 空白区切りのAND検索
                return words.allSatisfy { word in
                    contains(
                        post.body,
                        word: word,
                        caseSensitive: caseSensitive
                    )
                }
            }
            .sorted {
                if $0.diaryDate != $1.diaryDate {
                    return $0.diaryDate > $1.diaryDate
                }

                return $0.id > $1.id
            }
            .map {
                TimelineSearchResult(post: $0)
            }
    }

    private func contains(
        _ text: String,
        word: String,
        caseSensitive: Bool
    ) -> Bool {

        if caseSensitive {
            return text.contains(word)
        }

        return text.range(
            of: word,
            options: [
                .caseInsensitive,
                .diacriticInsensitive
            ],
            range: nil,
            locale: .current
        ) != nil
    }

    // MARK: - Newest / oldest

    var newestRootPost: DiaryPost? {
        rootPosts.max {
            if $0.diaryDate != $1.diaryDate {
                return $0.diaryDate < $1.diaryDate
            }

            return $0.id < $1.id
        }
    }

    var oldestRootPost: DiaryPost? {
        rootPosts.min {
            if $0.diaryDate != $1.diaryDate {
                return $0.diaryDate < $1.diaryDate
            }

            return $0.id < $1.id
        }
    }

    private var rootPosts: [DiaryPost] {
        posts.filter {
            $0.parentPostId == nil
        }
    }

    // MARK: - Open search result
/*
    func openSearchResult(
        _ result: TimelineSearchResult
    ) {
        guard let rootPostID =
            rootPostID(for: result.post)
        else {
            return
        }

        if result.post.id == rootPostID {

            showPost(rootPostID)

        } else {

            showPost(
                rootPostID,
                focusedOn: result.post.id
            )
        }
    }
 */
    // MARK: - Open search result

    func openSearchResult(
        _ result: TimelineSearchResult
    ) {
        guard
            let rootPostID =
                rootPostID(for: result.post)
        else {
            return
        }

        let focusedPostID: Int64? =
            result.post.id == rootPostID
            ? nil
            : result.post.id

        let newTarget =
            TimelineNavigationTarget(
                postID: rootPostID,
                focusedPostID: focusedPostID
            )

        guard
            newTarget != navigation.currentTarget
        else {
            return
        }

        // 現在位置を戻る履歴へ積む
        if let currentTarget =
            navigation.currentTarget
        {
            navigation.history.append(
                currentTarget
            )
        }

        navigation.currentTarget =
            newTarget
    }
    
}
