//
//  TimelineNavigationState.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/16.
//

//
//  TimelineNavigationState.swift
//  myDiary
//

import Foundation

/// タイムライン上で表示する場所を表す。
struct TimelineNavigationTarget: Equatable {

    /// タイムライン上で表示するトップレベル投稿
    let postID: Int64

    /// スクロールやハイライトの対象。
    /// nilなら投稿カード全体を表示する。
    let focusedPostID: Int64?
}

/// タイムラインの現在位置と履歴を管理する。
struct TimelineNavigationState {

    var currentTarget:
        TimelineNavigationTarget?

    var history:
        [TimelineNavigationTarget] = []
}
