//
//  ImageResizer.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/20.
//

//
//  ImageResizer.swift
//  myDiary
//

import Foundation
import AppKit

enum ImageResizer {

    static func createResizedJPEG(
        sourceURL: URL,
        destinationURL: URL,
        maxPixelSize: CGFloat
    ) throws {

        guard let image = NSImage(contentsOf: sourceURL) else {
            throw NSError(
                domain: "ImageStore",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "画像を読み込めません"
                ]
            )
        }

        let originalSize = image.size

        let scale = min(
            maxPixelSize / originalSize.width,
            maxPixelSize / originalSize.height,
            1.0
        )

        let resizedSize = NSSize(
            width: originalSize.width * scale,
            height: originalSize.height * scale
        )

        let resizedImage = NSImage(size: resizedSize)

        resizedImage.lockFocus()

        image.draw(
            in: NSRect(origin: .zero, size: resizedSize),
            from: NSRect(origin: .zero, size: originalSize),
            operation: .copy,
            fraction: 1.0
        )

        resizedImage.unlockFocus()

        guard
            let tiffData = resizedImage.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffData),
            let jpegData = bitmap.representation(
                using: .jpeg,
                properties: [.compressionFactor: 0.85]
            )
        else {
            throw NSError(
                domain: "ImageStore",
                code: 2,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "JPEG作成に失敗しました"
                ]
            )
        }

        try jpegData.write(to: destinationURL)
    }
}

/*
import AppKit

private func createResizedJPEG(
    sourceURL: URL,
    destinationURL: URL,
    maxPixelSize: CGFloat
) throws {

    guard let image = NSImage(contentsOf: sourceURL) else {
        throw NSError(
            domain: "ImageStore",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "画像を読み込めません"]
        )
    }

    let originalSize = image.size

    let scale = min(
        maxPixelSize / originalSize.width,
        maxPixelSize / originalSize.height,
        1.0
    )

    let resizedSize = NSSize(
        width: originalSize.width * scale,
        height: originalSize.height * scale
    )

    let resizedImage = NSImage(size: resizedSize)
    resizedImage.lockFocus()
    image.draw(
        in: NSRect(origin: .zero, size: resizedSize),
        from: NSRect(origin: .zero, size: originalSize),
        operation: .copy,
        fraction: 1.0
    )
    resizedImage.unlockFocus()

    guard
        let tiffData = resizedImage.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiffData),
        let jpegData = bitmap.representation(
            using: .jpeg,
            properties: [.compressionFactor: 0.85]
        )
    else {
        throw NSError(
            domain: "ImageStore",
            code: 2,
            userInfo: [NSLocalizedDescriptionKey: "JPEG作成に失敗しました"]
        )
    }

    try jpegData.write(to: destinationURL)
}
*/
