//
//  ImageViewerState.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/08.
//

import Foundation
import AppKit
import Observation

enum ViewerImageKind {
    case display
    case original
}

@Observable
final class ImageViewerState: Identifiable {

    let id = UUID()

    let post: DiaryPost
    var imageIndex: Int

    init(post: DiaryPost, imageIndex: Int) {
        self.post = post
        self.imageIndex = imageIndex
    }
    
    var viewerImageKind: ViewerImageKind = .display

    var currentURL: URL {
        switch viewerImageKind {
        case .display:
            return ImageStore.shared.url(for: image, kind: .display)
        case .original:
            return ImageStore.shared.url(for: image, kind: .original)
        }
    }

    var currentImage: NSImage? {
        NSImage(contentsOf: currentURL)
    }
    
    var image: DiaryImage {
        post.images[imageIndex]
    }

    var imageCount: Int {
        post.images.count
    }

    var imageNumberText: String {
        "\(imageIndex + 1) / \(imageCount)"
    }

    var hasPrevious: Bool {
        imageIndex > 0
    }

    var hasNext: Bool {
        imageIndex < imageCount - 1
    }

    var displayURL: URL {
        ImageStore.shared.url(for: image, kind: .display)
    }

    var originalURL: URL {
        ImageStore.shared.url(for: image, kind: .original)
    }

    var thumbnailURL: URL {
        ImageStore.shared.url(for: image, kind: .thumbnail)
    }

    var displayImage: NSImage? {
        NSImage(contentsOf: displayURL)
    }

    var displayImageSizeText: String {
        guard let image = displayImage else {
            return ""
        }

        return "\(Int(image.size.width))×\(Int(image.size.height))"
    }

    func showPrevious() {
        if hasPrevious {
            imageIndex -= 1
        }
    }

    func showNext() {
        if hasNext {
            imageIndex += 1
        }
    }

    func showFirst() {
        imageIndex = 0
    }

    func showLast() {
        imageIndex = imageCount - 1
    }
}
