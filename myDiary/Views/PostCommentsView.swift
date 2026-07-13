//
//  PostCommentsView.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/14.
//

//
//  PostCommentsView.swift
//  myDiary
//

import SwiftUI

struct PostCommentsView: View {

    let comments: [DiaryPost]

    let onTapImage: (
        DiaryPost,
        DiaryImage
    ) -> Void

    let onDeleteImage: (
        DiaryPost,
        DiaryImage
    ) -> Void

    let onOpenSource: (
        DiaryImage
    ) -> Void

    var body: some View {
        if !comments.isEmpty {

            VStack(
                alignment: .leading,
                spacing: 10
            ) {

                Divider()

                HStack(spacing: 6) {
                    Image(
                        systemName:
                            "bubble.left.and.bubble.right"
                    )

                    Text(
                        "コメント \(comments.count)件"
                    )
                    .font(.headline)
                }
                .foregroundStyle(.secondary)

                ForEach(comments) { comment in
                    commentView(comment)
                }
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
        }
    }

    @ViewBuilder
    private func commentView(
        _ comment: DiaryPost
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            HStack {
                Image(
                    systemName:
                        "arrowshape.turn.up.left"
                )
                .foregroundStyle(.secondary)

                Text(
                    comment.diaryDate.formatted(
                        date: .abbreviated,
                        time: .shortened
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                Spacer()

                if comment.packagePostID != nil {
                    Text("Facebook")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            if !comment.body
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .isEmpty
            {
                Text(
                    comment.body
                )
                .textSelection(.enabled)
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
            }

            if !comment.images.isEmpty {
                ImageGridView(
                    images: comment.images,
                    onTapImage: { image in
                        onTapImage(
                            comment,
                            image
                        )
                    },
                    onDelete: { image in
                        onDeleteImage(
                            comment,
                            image
                        )
                    },
                    onOpenSource: { image in
                        onOpenSource(image)
                    }
                )
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
                .clipped()
            }
        }
        .padding(12)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            Color.secondary.opacity(0.08)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 10
            )
        )
    }
}
