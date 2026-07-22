//
//  ImportProgressState.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/22.
//

//
//  ImportProgressState.swift
//  myDiaryCore
//

import Foundation
import Observation

@MainActor
@Observable
public final class ImportProgressState {

    public enum Phase {
        case idle
        case preparing
        case importingPosts
        case copyingMedia
        case fetchingLinkImages
        case finishing
        case completed
        case failed

        public var localizedTitle: String {
            switch self {
            case .idle:
                return "待機中"

            case .preparing:
                return "準備しています"

            case .importingPosts:
                return "投稿を読み込んでいます"

            case .copyingMedia:
                return "画像をコピーしています"

            case .fetchingLinkImages:
                return "リンク画像を取得しています"

            case .finishing:
                return "後処理をしています"

            case .completed:
                return "完了しました"

            case .failed:
                return "エラーが発生しました"
            }
        }
    }
    
    public var phase: Phase = .idle

    /// 投稿数
    public var current = 0
    public var total = 0

    /// 現在のメッセージ
    public var message = ""

    /// 補足情報
    public var detail = ""

    /// 実行中
    public var isRunning = false

    /// エラー
    public var errorMessage: String?

    public init() {
    }

    public var fractionCompleted: Double {

        guard total > 0 else {
            return 0
        }

        return Double(current) / Double(total)
    }

    public var progressText: String {

        guard total > 0 else {
            return ""
        }

        return "\(current) / \(total)"
    }

    public func start(total: Int) {

        self.total = total
        current = 0

        message = "Preparing..."
        detail = ""

        errorMessage = nil

        phase = .preparing
        isRunning = true
    }

    public func update(
        current: Int,
        phase: Phase,
        detail: String = ""
    ) {
        self.current = current
        self.phase = phase
        self.message = phase.localizedTitle
        self.detail = detail
    }
    
    public func complete() {

        current = total

        phase = .completed

        message = "Completed"

        detail = ""

        isRunning = false
    }

    public func fail(
        _ error: Error
    ) {

        phase = .failed

        errorMessage = error.localizedDescription

        message = "Failed"

        isRunning = false
    }
}
