//
//  ImageResizer.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/20.
//

//
//  ImageResizer.swift
//  myDiaryiPad
//

import Foundation
import UIKit

enum ImageResizer {

    static func createResizedJPEG(
        sourceURL: URL,
        destinationURL: URL,
        maxPixelSize: CGFloat
    ) throws {

        guard let image = UIImage(contentsOfFile: sourceURL.path) else {
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

        guard originalSize.width > 0,
              originalSize.height > 0
        else {
            throw NSError(
                domain: "ImageStore",
                code: 2,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "画像サイズが不正です"
                ]
            )
        }

        let scale = min(
            maxPixelSize / originalSize.width,
            maxPixelSize / originalSize.height,
            1.0
        )

        let resizedSize = CGSize(
            width: originalSize.width * scale,
            height: originalSize.height * scale
        )

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(
            size: resizedSize,
            format: format
        )

        let resizedImage = renderer.image { context in
            UIColor.white.setFill()
            context.fill(
                CGRect(
                    origin: .zero,
                    size: resizedSize
                )
            )

            image.draw(
                in: CGRect(
                    origin: .zero,
                    size: resizedSize
                )
            )
        }

        guard let jpegData = resizedImage.jpegData(
            compressionQuality: 0.85
        ) else {
            throw NSError(
                domain: "ImageStore",
                code: 3,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "JPEG作成に失敗しました"
                ]
            )
        }

        try jpegData.write(
            to: destinationURL,
            options: .atomic
        )
    }
}
