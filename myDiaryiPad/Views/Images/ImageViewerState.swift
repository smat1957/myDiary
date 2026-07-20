//
//  ImageViewerState.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/20.
//
//
//  ImageViewerState.swift
//  myDiaryiPad
//


import Foundation
import Observation
import SwiftUI
import UIKit

/*
enum ViewerImageKind:
    String,
    CaseIterable,
    Identifiable
{
    case display = "Display"
    case original = "Original"

    var id: Self {
        self
    }
}
*/

enum ViewerImageKind: String, CaseIterable, Identifiable {

    case display
    case original

    var id: Self { self }

    var localizedName: LocalizedStringKey {
        switch self {
        case .display:
            return "viewer.imageKind.display"

        case .original:
            return "viewer.imageKind.original"
        }
    }
}

@Observable
final class ImageViewerState: Identifiable {

    let id = UUID()

    /*
     Viewerを開いた時点の投稿情報。
     画像配列だけはimagesで別に管理する。
     */
    let post: DiaryPost

    var images: [DiaryImage]
    var imageIndex: Int

    var viewerImageKind:
        ViewerImageKind = .display

    init(
        post: DiaryPost,
        imageIndex: Int
    ) {
        self.post = post
        self.images = post.images

        if post.images.indices.contains(
            imageIndex
        ) {
            self.imageIndex = imageIndex
        } else {
            self.imageIndex = 0
        }
    }

    // MARK: - Current post

    /*
     現在の画像配列を反映した投稿。
     並べ替えや削除時のDB更新に使用する。
     */
    var currentPost: DiaryPost {
        var updatedPost = post
        updatedPost.images = images
        return updatedPost
    }

    // MARK: - Current image

    var hasImages: Bool {
        !images.isEmpty
    }

    var image: DiaryImage {
        images[imageIndex]
    }

    var imageCount: Int {
        images.count
    }

    var imageNumberText: String {
        guard hasImages else {
            return "0 / 0"
        }

        return "\(imageIndex + 1) / \(imageCount)"
    }

    var currentURL: URL {
        switch viewerImageKind {

        case .display:
            return ImageStore.shared.url(
                for: image,
                kind: .display
            )

        case .original:
            return ImageStore.shared.url(
                for: image,
                kind: .original
            )
        }
    }
    
    // iPad
    var currentImage: UIImage? {
        guard hasImages else {
            return nil
        }

        return UIImage(
            contentsOfFile: currentURL.path
        )
    }
    
    /*
    // macOS
    var currentImage: NSImage? {
        guard hasImages else {
            return nil
        }

        return NSImage(
            contentsOf: currentURL
        )
    }
     */
    
    // MARK: - Navigation

    var hasPrevious: Bool {
        imageIndex > 0
    }

    var hasNext: Bool {
        imageIndex < imageCount - 1
    }

    func showPrevious() {
        guard hasPrevious else {
            return
        }

        imageIndex -= 1
    }

    func showNext() {
        guard hasNext else {
            return
        }

        imageIndex += 1
    }

    func showFirst() {
        guard hasImages else {
            return
        }

        imageIndex = 0
    }

    func showLast() {
        guard hasImages else {
            return
        }

        imageIndex = imageCount - 1
    }

    // MARK: - Image deletion

    /*
     現在表示中の画像を配列から削除する。

     最後の画像を削除した場合は、
     一つ前の画像へ移動する。
     */
    func removeCurrentImage() {
        guard
            images.indices.contains(
                imageIndex
            )
        else {
            return
        }

        images.remove(
            at: imageIndex
        )

        guard !images.isEmpty else {
            imageIndex = 0
            return
        }

        if imageIndex >= images.count {
            imageIndex = images.count - 1
        }
    }

    // MARK: - Image ordering

    var canMoveBackward: Bool {
        imageIndex > 0
    }

    var canMoveForward: Bool {
        imageIndex < imageCount - 1
    }

    /*
     現在の画像を一つ前へ移動する。
     */
    func moveCurrentImageBackward() {
        guard canMoveBackward else {
            return
        }

        images.swapAt(
            imageIndex,
            imageIndex - 1
        )

        imageIndex -= 1
    }

    /*
     現在の画像を一つ後ろへ移動する。
     */
    func moveCurrentImageForward() {
        guard canMoveForward else {
            return
        }

        images.swapAt(
            imageIndex,
            imageIndex + 1
        )

        imageIndex += 1
    }
}

