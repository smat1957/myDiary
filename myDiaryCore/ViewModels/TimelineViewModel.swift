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
    
    let importProgress = ImportProgressState()
    
    var navigation = TimelineNavigationState()

    let repository = PostRepository()

    init() {
        _ = DatabaseManager.shared
        loadPosts()
        resetNavigation()
        //debugSearch()
    }
    
    var currentPostID: Int64? {
        navigation.currentTarget?.postID
    }

    var focusedPostID: Int64? {
        navigation.currentTarget?
            .focusedPostID
    }
    
    // MARK: - Timeline

    /// タイムライン本体に表示する投稿。
    /// 親投稿に紐付いたコメントは除外する。
    var timelinePosts: [DiaryPost] {
        posts.filter {
            $0.parentPostId == nil
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

    func post(
        for id: Int64
    ) -> DiaryPost? {
        postDictionary[id]
    }
    
    func rootPostID(
        for post: DiaryPost
    ) -> Int64? {

        var currentPost = post
        var visitedPostIDs: Set<Int64> = []

        while let parentPostID =
            currentPost.parentPostId
        {
            guard
                visitedPostIDs.insert(
                    currentPost.id
                ).inserted
            else {
                return nil
            }

            guard
                let parentPost =
                    postDictionary[parentPostID]
            else {
                return nil
            }

            currentPost = parentPost
        }

        return currentPost.id
    }
}
