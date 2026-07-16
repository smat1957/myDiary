//
//  TimelineViewModel+Comments.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/16.
//

//
//  TimelineViewModel+Comments.swift
//  myDiary
//

import Foundation

extension TimelineViewModel {

    // MARK: - Comment relationship

    /// 指定した投稿に直接紐付くコメントを返す。
    func comments(
        for post: DiaryPost
    ) -> [DiaryPost] {

        guard post.id != 0 else {
            return []
        }

        return posts
            .filter {
                $0.parentPostId == post.id
            }
            .sorted {
                if $0.diaryDate != $1.diaryDate {
                    return $0.diaryDate < $1.diaryDate
                }

                return $0.id < $1.id
            }
    }

    func linkComment(
        _ comment: DiaryPost,
        to parent: DiaryPost
    ) {
        guard comment.id != parent.id else {
            return
        }

        do {
            var updatedComment = comment

            updatedComment.parentPostId = parent.id
            updatedComment.updatedAt = Date()

            try repository.update(
                updatedComment
            )

            loadPosts()

            showPost(
                parent.id,
                focusedOn: comment.id
            )

        } catch {
            print(
                "コメントの親投稿設定失敗:",
                error.localizedDescription
            )
        }
    }
    
    func unlinkComment(
        _ comment: DiaryPost
    ) {
        do {
            var updatedComment = comment

            updatedComment.parentPostId = nil
            updatedComment.updatedAt = Date()

            try repository.update(
                updatedComment
            )

            loadPosts()

        } catch {
            print(
                "コメントの親投稿解除失敗:",
                error.localizedDescription
            )
        }
    }
}
