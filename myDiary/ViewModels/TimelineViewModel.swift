//
//  TimelineViewModel.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/06.
//

//
//  TimelineViewModel.swift
//  myDiary
//

import Foundation
import Observation

@Observable
final class TimelineViewModel {

    var posts: [DiaryPost] = []

    var navigation = TimelineNavigationState()

    let repository = PostRepository()

    init() {
        _ = DatabaseManager.shared
        loadPosts()
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
}
