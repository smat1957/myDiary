//
//  TimelineViewModel+Posts.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/16.
//

//
//  TimelineViewModel+Posts.swift
//  myDiary
//

import Foundation

extension TimelineViewModel {

    // MARK: - Load

    func loadPosts() {
        do {
            posts = try repository.fetchAll()
        } catch {
            print(
                "投稿読み込み失敗:",
                error.localizedDescription
            )
        }
    }

    // MARK: - Post operations

    func addPost(
        _ post: DiaryPost
    ) {
        do {
            _ = try repository.insert(post)
            loadPosts()
        } catch {
            print(
                "投稿保存失敗:",
                error.localizedDescription
            )
        }
    }

    func updatePost(
        _ post: DiaryPost
    ) {
        do {
            try repository.update(post)
            loadPosts()
        } catch {
            print(
                "投稿更新失敗:",
                error.localizedDescription
            )
        }
    }

    func deletePost(
        _ post: DiaryPost
    ) {
        for image in post.images {
            ImageStore.shared.delete(image)
        }

        do {
            try repository.delete(post)

            navigation.history.removeAll {
                $0.postID == post.id
            }
            
            if currentPostID == post.id {
                navigation.currentTarget = nil
            }
            
            loadPosts()

        } catch {
            print(
                "投稿削除失敗:",
                error.localizedDescription
            )
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
            print(
                "画像削除失敗:",
                error.localizedDescription
            )
        }
    }
}
