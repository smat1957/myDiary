//
//  TimelineViewModel+Navigation.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/16.
//

import Foundation

extension TimelineViewModel {
    
    var canGoBack: Bool {
        !navigation.history.isEmpty
    }
    
    // MARK: - 履歴を残す移動
    
    /// 関連記事など、戻る操作が必要な移動。
    func jumpToPost(
        _ targetPostID: Int64,
        from sourcePostID: Int64?
    ) {
        guard
            targetPostID !=
                navigation.currentTarget?.postID
        else {
            return
        }
        
        if let currentTarget =
            navigation.currentTarget
        {
            navigation.history.append(
                currentTarget
            )
            
        } else if let sourcePostID {
            navigation.history.append(
                TimelineNavigationTarget(
                    postID: sourcePostID,
                    focusedPostID: nil
                )
            )
        }
        
        navigation.currentTarget =
        TimelineNavigationTarget(
            postID: targetPostID,
            focusedPostID: nil
        )
    }
    
    // MARK: - 履歴を残さない表示
    
    /// 投稿を表示する。
    /// コメント紐付け後や検索結果表示などに使う。
    func showPost(
        _ postID: Int64
    ) {
        navigation.currentTarget =
        TimelineNavigationTarget(
            postID: postID,
            focusedPostID: nil
        )
    }
    
    /// 親投稿を表示し、その中のコメントや返信に注目する。
    func showPost(
        _ postID: Int64,
        focusedOn focusedPostID: Int64
    ) {
        navigation.currentTarget =
        TimelineNavigationTarget(
            postID: postID,
            focusedPostID:
                focusedPostID
        )
        /*
         print(
         "NavigationTarget:",
         "post:",
         postID,
         "focus:",
         focusedPostID
         )
         */
    }
    
    func openLinkedPost(
        _ targetPostID: Int64,
        from sourcePostID: Int64
    ) {
        guard
            let targetPost =
                postDictionary[targetPostID],
            let targetRootPostID =
                rootPostID(for: targetPost)
        else {
            return
        }

        let focusedPostID: Int64? =
            targetPost.id == targetRootPostID
            ? nil
            : targetPost.id

        let newTarget =
            TimelineNavigationTarget(
                postID: targetRootPostID,
                focusedPostID: focusedPostID
            )

        guard
            newTarget != navigation.currentTarget
        else {
            return
        }

        if let currentTarget =
            navigation.currentTarget
        {
            navigation.history.append(
                currentTarget
            )

        } else if
            let sourcePost =
                postDictionary[sourcePostID],
            let sourceRootPostID =
                rootPostID(for: sourcePost)
        {
            let sourceFocusedPostID: Int64? =
                sourcePost.id == sourceRootPostID
                ? nil
                : sourcePost.id

            navigation.history.append(
                TimelineNavigationTarget(
                    postID: sourceRootPostID,
                    focusedPostID:
                        sourceFocusedPostID
                )
            )
        }

        navigation.currentTarget =
            newTarget
    }
    
    func goBack() {
        guard
            let previousTarget =
                navigation.history.popLast()
        else {
            return
        }
        
        navigation.currentTarget =
        previousTarget
    }
    
    /// 注目対象を消す。
    /// スクロールとハイライト完了後に呼ぶ。
    func clearFocusedPost() {
        guard
            let currentTarget =
                navigation.currentTarget
        else {
            return
        }
        
        navigation.currentTarget =
        TimelineNavigationTarget(
            postID:
                currentTarget.postID,
            focusedPostID: nil
        )
    }
    
    /// アプリ起動時のナビゲーション状態に戻す。
    func resetNavigation() {
        navigation = TimelineNavigationState()
    }

}


