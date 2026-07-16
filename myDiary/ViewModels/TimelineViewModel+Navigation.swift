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
            navigationStack.append(
                currentPostID
            )
        }

        self.currentPostID =
            targetPostID
    }

    func openLinkedPost(
        _ targetPostID: Int64,
        from sourcePostID: Int64
    ) {
        guard
            postDictionary[targetPostID] != nil
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
            let previousID =
                navigationStack.popLast()
        else {
            return
        }

        currentPostID =
            previousID
    }
}
