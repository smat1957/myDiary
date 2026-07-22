//
//  ImageGridView.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/20.
//

import SwiftUI
import UIKit

struct ImageGridView: View {

    let images: [DiaryImage]
    var scale: CGFloat = 1.0

    // 投稿編集画面でだけ true にする
    var allowsDeletion: Bool = false

    let onTapImage: (DiaryImage) -> Void
    let onDelete: (DiaryImage) -> Void
    let onOpenSource: (DiaryImage) -> Void

    private let spacing: CGFloat = 4

    var body: some View {
        GeometryReader { geometry in
            let availableWidth = max(0, geometry.size.width)

            VStack(alignment: .leading, spacing: 8) {

                //Text("画像 \(images.count) 枚")
                //Text(
                //    String(localized: "images.count")
                //)
                Text(
                    String.localizedStringWithFormat(
                        String(localized: "images.count"),
                        Int64(images.count)
                    )
                )
                .font(.headline)
                
                switch images.count {

                case 0:
                    EmptyView()

                case 1:
                    singleImage(
                        images[0],
                        width: availableWidth
                    )

                case 2:
                    twoImages(
                        images[0],
                        images[1],
                        width: availableWidth
                    )

                case 3:
                    threeImages(
                        images[0],
                        images[1],
                        images[2],
                        width: availableWidth
                    )

                case 4:
                    fourImages(
                        images,
                        width: availableWidth
                    )

                default:
                    manyImages(
                        images,
                        width: availableWidth
                    )
                }
            }
            .frame(
                width: availableWidth,
                alignment: .leading
            )
        }
        .frame(height: gridHeight)
    }

    // MARK: - Grid height

    // MARK: - Grid height

    private var gridHeight: CGFloat {

        let titleHeight: CGFloat = 28
        let titleSpacing: CGFloat = 8

        switch images.count {

        case 0:
            return titleHeight

        case 1:
            return titleHeight
                + titleSpacing
                + 320 * scale

        case 2:
            return titleHeight
                + titleSpacing
                + 260 * scale

        case 3:
            return titleHeight
                + titleSpacing
                + 220 * scale
                + spacing
                + 180 * scale

        case 4:
            return titleHeight
                + titleSpacing
                + 180 * scale
                + spacing
                + 180 * scale

        default:
            return titleHeight
                + titleSpacing
                + 180 * scale
                + spacing
                + 180 * scale
        }
    }
    
    // MARK: - Layouts
    private func singleImage(
        _ image: DiaryImage,
        width: CGFloat
    ) -> some View {

        mediaCell(
            image,
            width: width,
            height: 320 * scale
        )
    }

    private func twoImages(
        _ image1: DiaryImage,
        _ image2: DiaryImage,
        width: CGFloat
    ) -> some View {

        let cellWidth = max(
            0,
            (width - spacing) / 2
        )

        return HStack(spacing: spacing) {

            mediaCell(
                image1,
                width: cellWidth,
                height: 260 * scale
            )

            mediaCell(
                image2,
                width: cellWidth,
                height: 260 * scale
            )
        }
        .frame(
            width: width,
            height: 260 * scale,
            alignment: .leading
        )
        .clipped()
    }

    private func threeImages(
        _ image1: DiaryImage,
        _ image2: DiaryImage,
        _ image3: DiaryImage,
        width: CGFloat
    ) -> some View {

        let cellWidth = max(
            0,
            (width - spacing) / 2
        )

        return VStack(spacing: spacing) {

            mediaCell(
                image1,
                width: width,
                height: 220 * scale
            )

            HStack(spacing: spacing) {

                mediaCell(
                    image2,
                    width: cellWidth,
                    height: 180 * scale
                )

                mediaCell(
                    image3,
                    width: cellWidth,
                    height: 180 * scale
                )
            }
            .frame(
                width: width,
                height: 180 * scale,
                alignment: .leading
            )
        }
        .frame(
            width: width,
            alignment: .leading
        )
        .clipped()
    }

    private func fourImages(
        _ images: [DiaryImage],
        width: CGFloat
    ) -> some View {

        VStack(spacing: spacing) {

            twoCellRow(
                images[0],
                images[1],
                width: width,
                height: 180 * scale
            )

            twoCellRow(
                images[2],
                images[3],
                width: width,
                height: 180 * scale
            )
        }
        .frame(
            width: width,
            alignment: .leading
        )
        .clipped()
    }

    private func manyImages(
        _ images: [DiaryImage],
        width: CGFloat
    ) -> some View {

        let visibleImages = Array(
            images.prefix(4)
        )

        let remainingCount =
            images.count - 4

        return VStack(spacing: spacing) {

            twoCellRow(
                visibleImages[0],
                visibleImages[1],
                width: width,
                height: 180 * scale
            )

            twoCellRow(
                visibleImages[2],
                visibleImages[3],
                width: width,
                height: 180 * scale,
                remainingCount: remainingCount
            )
        }
        .frame(
            width: width,
            alignment: .leading
        )
        .clipped()
    }
    
    private func twoCellRow(
        _ image1: DiaryImage,
        _ image2: DiaryImage,
        width: CGFloat,
        height: CGFloat,
        remainingCount: Int = 0
    ) -> some View {

        let cellWidth = max(
            0,
            (width - spacing) / 2
        )

        return HStack(spacing: spacing) {

            mediaCell(
                image1,
                width: cellWidth,
                height: height
            )

            mediaCell(
                image2,
                width: cellWidth,
                height: height,
                remainingCount: remainingCount
            )
        }
        .frame(
            width: width,
            height: height,
            alignment: .leading
        )
        .clipped()
    }
    
    /*
    // MARK: - Media cell

    @ViewBuilder
    private func mediaCell(
        _ image: DiaryImage,
        width: CGFloat,
        height: CGFloat,
        remainingCount: Int? = nil
    ) -> some View {

        let url = ImageStore.shared.url(
            for: image,
            kind: .thumbnail
        )

        //if let nsImage = NSImage(contentsOf: url) {
        if let uiImage = UIImage(contentsOfFile: url.path) {
            
            Button {
                onTapImage(image)
            } label: {

                ZStack(alignment: .topLeading) {

                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(
                            width: width,
                            height: height
                        )
                        .clipped()

                    VStack {
                        HStack {
                            sourceButton(for: image)
                            Spacer()
                            if allowsDeletion {
                                deleteButton(for: image)
                            }
                        }
                        Spacer()
                    }

                    if let remainingCount,
                       remainingCount > 0 {
                        
                        Color.black
                            .opacity(0.45)
                            .frame(
                                width: width,
                                height: height
                            )
                        
                        Text("+\(remainingCount)")
                            .font(
                                .system(
                                    size: 42,
                                    weight: .bold
                                )
                            )
                            .foregroundStyle(.white)
                            .frame(
                                width: width,
                                height: height
                            )
                    }
                }
                .frame(
                    width: width,
                    height: height
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 8
                    )
                )
                .contentShape(
                    Rectangle()
                )
            }
            .buttonStyle(.plain)
            .frame(
                width: width,
                height: height
            )

        } else {

            //Text("読み込み失敗")
            Text(String(localized: "image.loadFailed"))
                .frame(
                    width: width,
                    height: height
                )
                .background(
                    .gray.opacity(0.2)
                )
        }
    }
     */
    // MARK: - Media cell

    @ViewBuilder
    private func mediaCell(
        _ image: DiaryImage,
        width: CGFloat,
        height: CGFloat,
        remainingCount: Int? = nil
    ) -> some View {

        let url = ImageStore.shared.url(
            for: image,
            kind: .thumbnail
        )

        if let uiImage = UIImage(
            contentsOfFile: url.path
        ) {
            ZStack(alignment: .topLeading) {

                /*
                 画像本体を押した場合は、
                 sourceTypeに関係なくImageViewerを開く。
                 */
                Button {
                    onTapImage(image)
                } label: {
                    ZStack {

                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(
                                width: width,
                                height: height
                            )
                            .clipped()

                        /*
                         5枚以上ある場合の「+N」表示。

                         このオーバーレイも画像本体Buttonの中に
                         あるため、押すとImageViewerが開く。
                         */
                        if let remainingCount,
                           remainingCount > 0 {

                            Color.black
                                .opacity(0.45)

                            Text("+\(remainingCount)")
                                .font(
                                    .system(
                                        size: 42,
                                        weight: .bold
                                    )
                                )
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(
                        width: width,
                        height: height
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .frame(
                    width: width,
                    height: height
                )

                /*
                 左上のリンクボタンと、
                 右上の削除ボタンは画像Buttonの外側へ置く。
                 */
                HStack {
                    sourceButton(for: image)
                        .zIndex(2)

                    Spacer()

                    if allowsDeletion {
                        deleteButton(for: image)
                            .zIndex(2)
                    }
                }
                .frame(width: width)
            }
            .frame(
                width: width,
                height: height
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 8
                )
            )

        } else {
            Text(
                String(
                    localized: "image.loadFailed"
                )
            )
            .frame(
                width: width,
                height: height
            )
            .background(
                .gray.opacity(0.2)
            )
        }
    }
    // MARK: - Source button

    @ViewBuilder
    private func sourceButton(
        for image: DiaryImage
    ) -> some View {

        switch image.sourceType {

        case .youtube:
            Button {
                onOpenSource(image)
            } label: {
                Image(
                    systemName:
                        "play.circle.fill"
                )
                .font(
                    .system(size: 32)
                )
                .foregroundStyle(
                    .white
                )
                .shadow(radius: 3)
                .padding(8)
            }
            .buttonStyle(.plain)

        case .link:
            Button {
                onOpenSource(image)
            } label: {
                Image(
                    systemName: "globe"
                )
                .font(
                    .system(size: 28)
                )
                .foregroundStyle(
                    .white
                )
                .shadow(radius: 3)
                .padding(8)
            }
            .buttonStyle(.plain)
            .help(String(localized: "image.openSource"))

        case .photo, .generated:
            EmptyView()
        }
    }
    
    @ViewBuilder
    private func deleteButton(
        for image: DiaryImage
    ) -> some View {

        Button {
            onDelete(image)
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 28, weight: .bold))
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, .black.opacity(0.75))
            /*
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 24))
                .foregroundStyle(.white)
                .background(
                    Circle()
                        .fill(.black.opacity(0.55))
                )
            */
        }
        .buttonStyle(.plain)
        .help(String(localized: "common.delete"))
        .padding(8)
    }
}
