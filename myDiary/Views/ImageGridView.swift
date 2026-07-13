//
//  ImageGridView.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/06.
//

import SwiftUI
import AppKit

struct ImageGridView: View {

    let images: [DiaryImage]

    let onTapImage: (DiaryImage) -> Void
    let onDelete: (DiaryImage) -> Void
    let onOpenSource: (DiaryImage) -> Void

    private let spacing: CGFloat = 4

    var body: some View {
        GeometryReader { geometry in
            let availableWidth = max(0, geometry.size.width)

            VStack(alignment: .leading, spacing: 8) {

                Text("画像 \(images.count) 枚")

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

    private var gridHeight: CGFloat {
        let titleHeight: CGFloat = 28
        let titleSpacing: CGFloat = 8

        switch images.count {

        case 0:
            return titleHeight

        case 1:
            return titleHeight
                + titleSpacing
                + 320

        case 2:
            return titleHeight
                + titleSpacing
                + 260

        case 3:
            return titleHeight
                + titleSpacing
                + 220
                + spacing
                + 180

        case 4:
            return titleHeight
                + titleSpacing
                + 180
                + spacing
                + 180

        default:
            return titleHeight
                + titleSpacing
                + 180
                + spacing
                + 180
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
            height: 320
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
                height: 260
            )

            mediaCell(
                image2,
                width: cellWidth,
                height: 260
            )
        }
        .frame(
            width: width,
            height: 260,
            alignment: .leading
        )
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
                height: 220
            )

            HStack(spacing: spacing) {

                mediaCell(
                    image2,
                    width: cellWidth,
                    height: 180
                )

                mediaCell(
                    image3,
                    width: cellWidth,
                    height: 180
                )
            }
            .frame(
                width: width,
                height: 180,
                alignment: .leading
            )
        }
        .frame(
            width: width,
            alignment: .leading
        )
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
                height: 180
            )

            twoCellRow(
                images[2],
                images[3],
                width: width,
                height: 180
            )
        }
        .frame(
            width: width,
            alignment: .leading
        )
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
                height: 180
            )

            let cellWidth = max(
                0,
                (width - spacing) / 2
            )

            HStack(spacing: spacing) {

                mediaCell(
                    visibleImages[2],
                    width: cellWidth,
                    height: 180
                )

                mediaCell(
                    visibleImages[3],
                    width: cellWidth,
                    height: 180,
                    remainingCount: remainingCount
                )
            }
            .frame(
                width: width,
                height: 180,
                alignment: .leading
            )
        }
        .frame(
            width: width,
            alignment: .leading
        )
    }

    private func twoCellRow(
        _ image1: DiaryImage,
        _ image2: DiaryImage,
        width: CGFloat,
        height: CGFloat
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
                height: height
            )
        }
        .frame(
            width: width,
            height: height,
            alignment: .leading
        )
    }

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

        if let nsImage = NSImage(contentsOf: url) {

            Button {
                onTapImage(image)
            } label: {

                ZStack(alignment: .topLeading) {

                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFill()
                        .frame(
                            width: width,
                            height: height
                        )
                        .clipped()

                    sourceButton(
                        for: image
                    )

                    if let remainingCount {

                        Color.black
                            .opacity(0.45)
                            .frame(
                                width: width,
                                height: height
                            )

                        Text(
                            "+\(remainingCount)"
                        )
                        .font(
                            .system(
                                size: 42,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(
                            .white
                        )
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

            Text("読み込み失敗")
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

        case .photo, .generated:
            EmptyView()
        }
    }
}
