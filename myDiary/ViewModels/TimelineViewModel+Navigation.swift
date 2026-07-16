//
//  TimelineViewModel+Navigation.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/16.
//

//
//  TimelineViewModel+Navigation.swift
//  myDiary
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
            postDictionary[
                targetPostID
            ] != nil
        else {
            return
        }

        jumpToPost(
            targetPostID,
            from: sourcePostID
        )
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
}
