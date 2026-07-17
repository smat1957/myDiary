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
        query: String
    ) -> [TimelineSearchResult] {

        let words = query
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .split {
                $0.isWhitespace
            }
            .map(String.init)

        guard !words.isEmpty else {
            return []
        }

        return posts
            .filter { post in
                matchesSearchWords(
                    words,
                    post: post
                )
            }
            .sorted {
                if $0.diaryDate != $1.diaryDate {
                    return $0.diaryDate > $1.diaryDate
                }

                return $0.id > $1.id
            }
            .map {
                TimelineSearchResult(
                    post: $0
                )
            }
    }

    private func matchesSearchWords(
        _ words: [String],
        post: DiaryPost
    ) -> Bool {

        let dateText = post.diaryDate.formatted(
            date: .numeric,
            time: .shortened
        )

        let searchableText = """
        \(post.body)
        \(dateText)
        \(post.id)
        """

        /*
         空白で区切ったすべての語を含む場合に一致。
         例：「Bach guitar」なら両方を含む投稿。
         */
        return words.allSatisfy { word in
            searchableText
                .localizedCaseInsensitiveContains(
                    word
                )
        }
    }

    // MARK: - Open result
    // MARK: - Open search result

    func openSearchResult(
        _ result: TimelineSearchResult
    ) {
        let matchedPost = result.post

        guard
            let rootPostID =
                rootPostID(for: matchedPost)
        else {
            return
        }

        let focusedPostID: Int64? =
            matchedPost.id == rootPostID
            ? nil
            : matchedPost.id

        /*
         検索前に表示していた投稿を履歴へ残す。
         currentTarget がある場合だけ履歴へ追加する。
         */
        if let currentTarget =
            navigation.currentTarget
        {
            navigation.history.append(
                currentTarget
            )
        }

        navigation.currentTarget =
            TimelineNavigationTarget(
                postID: rootPostID,
                focusedPostID: focusedPostID
            )
    }

}

