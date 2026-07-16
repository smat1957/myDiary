//
//  TimelineViewModel+Links.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/16.
//

//
//  TimelineViewModel+Links.swift
//  myDiary
//

import Foundation

extension TimelineViewModel {

    // MARK: - Post links

    func addLink(
        from source: DiaryPost,
        to target: DiaryPost
    ) {
        var updated = source

        guard !updated.links.contains(
            where: {
                $0.toPostId == target.id
            }
        ) else {
            jumpToPost(
                target.id,
                from: source.id
            )
            return
        }

        updated.links.append(
            PostLink(
                fromPostId: source.id,
                toPostId: target.id,
                sortOrder:
                    updated.links.count
            )
        )

        updatePost(updated)

        jumpToPost(
            target.id,
            from: source.id
        )
    }

    func removeLink(
        from sourcePost: DiaryPost,
        to targetPostID: Int64
    ) {
        var updated = sourcePost

        updated.links.removeAll {
            $0.toPostId == targetPostID
        }

        normalizeLinkOrder(
            in: &updated
        )

        updatePost(updated)
    }

    func moveLink(
        in sourcePost: DiaryPost,
        from sourceIndex: Int,
        to destinationIndex: Int
    ) {
        guard
            sourcePost.links.indices
                .contains(sourceIndex)
        else {
            return
        }

        guard
            destinationIndex >= 0,
            destinationIndex
                < sourcePost.links.count
        else {
            return
        }

        guard sourceIndex != destinationIndex else {
            return
        }

        var updated = sourcePost

        let link =
            updated.links.remove(
                at: sourceIndex
            )

        updated.links.insert(
            link,
            at: destinationIndex
        )

        normalizeLinkOrder(
            in: &updated
        )

        updatePost(updated)
    }

    func backlinks(
        to postID: Int64
    ) -> [DiaryPost] {
        posts
            .filter { post in
                post.links.contains {
                    $0.toPostId == postID
                }
            }
            .sorted {
                $0.diaryDate
                    > $1.diaryDate
            }
    }

    var backlinkDictionary:
        [Int64: [DiaryPost]]
    {
        var result:
            [Int64: [DiaryPost]] = [:]

        for sourcePost in posts {
            for link in sourcePost.links {
                result[
                    link.toPostId,
                    default: []
                ].append(sourcePost)
            }
        }

        for postID in result.keys {
            result[postID]?.sort {
                $0.diaryDate
                    > $1.diaryDate
            }
        }

        return result
    }

    private func normalizeLinkOrder(
        in post: inout DiaryPost
    ) {
        for index in post.links.indices {
            post.links[index]
                .sortOrder = index
        }
    }
}
