//
//  TimelineViewModel.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/06.
//

import Foundation
import Observation

@Observable
final class TimelineViewModel {

    var posts: [DiaryPost] = []

    var navigationStack: [Int64] = []
    var currentPostID: Int64?

    private let repository = PostRepository()

    init() {
        _ = DatabaseManager.shared
        loadPosts()
    }
    
    // MARK: - Timeline

    /// タイムライン本体に表示する投稿。
    /// 親投稿に紐付いたコメントは除外する。
    var timelinePosts: [DiaryPost] {
        posts.filter {
            $0.parentPostId == nil
        }
    }
    
    // MARK: - Comment relationship
    /// 指定した投稿に紐付くコメントを返す。
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
    
    // MARK: - Post lookup

    var postDictionary: [Int64: DiaryPost] {
        Dictionary(
            uniqueKeysWithValues: posts.map {
                ($0.id, $0)
            }
        )
    }

    func post(for id: Int64) -> DiaryPost? {
        postDictionary[id]
    }

    // MARK: - Navigation

    var canGoBack: Bool {
        !navigationStack.isEmpty
    }

    func jumpToPost(
        _ targetPostID: Int64,
        from currentPostID: Int64?
    ) {
        guard targetPostID != currentPostID else {
            return
        }

        if let currentPostID {
            navigationStack.append(currentPostID)
        }

        self.currentPostID = targetPostID
    }

    func goBack() {
        guard let previousID = navigationStack.popLast() else {
            return
        }

        currentPostID = previousID
    }

    // MARK: - Load

    func loadPosts() {
        do {
            posts = try repository.fetchAll()
        } catch {
            print("投稿読み込み失敗:", error)
        }
        
        /* for Debug
        let linkedComments = posts.filter {
            $0.parentPostId != nil
        }

        print(
            "親投稿に紐付いたコメント:",
            linkedComments.count
        )

        for comment in linkedComments {
            print(
                "comment:",
                comment.id,
                "parent:",
                comment.parentPostId ?? 0
            )
        }
        */
        //repository.debugPostLinks()
    }

    // MARK: - Post operations

    func addPost(_ post: DiaryPost) {
        do {
            _ = try repository.insert(post)
            loadPosts()
        } catch {
            print("投稿保存失敗:", error)
        }
    }
    
    func updatePost(_ post: DiaryPost) {
        do {
            try repository.update(post)
            loadPosts()
        } catch {
            print("投稿更新失敗:", error)
        }
    }

    func deletePost(_ post: DiaryPost) {
        for image in post.images {
            ImageStore.shared.delete(image)
        }

        do {
            try repository.delete(post)

            navigationStack.removeAll {
                $0 == post.id
            }

            if currentPostID == post.id {
                currentPostID = nil
            }

            loadPosts()
        } catch {
            print("投稿削除失敗:", error)
        }
    }

    func deleteImage(
        _ image: DiaryImage,
        from post: DiaryPost
    ) {
        var updatedPost = post

        updatedPost.images.removeAll {
            $0.baseName == image.baseName
        }

        do {
            try repository.update(updatedPost)
            ImageStore.shared.delete(image)
            loadPosts()
        } catch {
            print("画像削除失敗:", error)
        }
    }

    // MARK: - Post links
    
    func addLink(
        from source: DiaryPost,
        to target: DiaryPost
    ) {
        var updated = source

        guard !updated.links.contains(where: {
            $0.toPostId == target.id
        }) else {
            jumpToPost(target.id, from: source.id)
            return
        }

        updated.links.append(
            PostLink(
                fromPostId: source.id,
                toPostId: target.id,
                sortOrder: updated.links.count
            )
        )

        //print(
        //    "リンク追加:",
        //    source.id,
        //    "->",
        //    target.id,
        //    "件数:",
        //    updated.links.count
        //)

        updatePost(updated)
        jumpToPost(target.id, from: source.id)
    }
    
    /*
    func addLink(
        from source: DiaryPost,
        to target: DiaryPost
    ) {
        var updated = source

        guard !updated.links.contains(where: {
            $0.toPostId == target.id
        }) else {
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
                sortOrder: updated.links.count
            )
        )

        print(
            "リンク追加:",
            source.id,
            "->",
            target.id,
            "件数:",
            updated.links.count
        )

        updatePost(updated)

        // ★追加
        repository.debugPostLinks()

        jumpToPost(
            target.id,
            from: source.id
        )
    }
    */
    func openLinkedPost(
        _ targetPostID: Int64,
        from sourcePostID: Int64
    ) {
        guard postDictionary[targetPostID] != nil else {
            return
        }

        jumpToPost(
            targetPostID,
            from: sourcePostID
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

        normalizeLinkOrder(in: &updated)

        updatePost(updated)
    }

    func moveLink(
        in sourcePost: DiaryPost,
        from sourceIndex: Int,
        to destinationIndex: Int
    ) {
        guard sourcePost.links.indices.contains(sourceIndex) else {
            return
        }

        guard destinationIndex >= 0,
              destinationIndex < sourcePost.links.count else {
            return
        }

        guard sourceIndex != destinationIndex else {
            return
        }

        var updated = sourcePost
        let link = updated.links.remove(at: sourceIndex)
        updated.links.insert(link, at: destinationIndex)

        normalizeLinkOrder(in: &updated)

        updatePost(updated)
    }

    private func normalizeLinkOrder(
        in post: inout DiaryPost
    ) {
        for index in post.links.indices {
            post.links[index].sortOrder = index
        }
    }
    
    func backlinks(to postID: Int64) -> [DiaryPost] {
        posts
            .filter { post in
                post.links.contains {
                    $0.toPostId == postID
                }
            }
            .sorted {
                $0.diaryDate > $1.diaryDate
            }
    }
    
    var backlinkDictionary: [Int64: [DiaryPost]] {
        var result: [Int64: [DiaryPost]] = [:]

        for sourcePost in posts {
            for link in sourcePost.links {
                result[link.toPostId, default: []].append(sourcePost)
            }
        }

        for postID in result.keys {
            result[postID]?.sort {
                $0.diaryDate > $1.diaryDate
            }
        }

        return result
    }
}
