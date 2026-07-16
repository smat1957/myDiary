//
//  BacklinksSectionView.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/16.
//

//
//  BacklinksSectionView.swift
//  myDiary
//

import SwiftUI

struct BacklinksSectionView: View {

    let backlinks: [DiaryPost]

    let onOpenLinkedPost:
        (Int64) -> Void

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            Divider()

            Text(
                "この投稿を参照している投稿"
            )
            .font(.headline)

            ForEach(backlinks) {
                sourcePost in

                Button {
                    onOpenLinkedPost(
                        sourcePost.id
                    )
                } label: {

                    HStack(
                        alignment: .top,
                        spacing: 8
                    ) {

                        Image(
                            systemName:
                                "arrow.turn.up.left"
                        )
                        .padding(.top, 3)

                        VStack(
                            alignment: .leading,
                            spacing: 3
                        ) {

                            Text(
                                "ID: \(sourcePost.id)"
                            )
                            .font(.caption)
                            .foregroundStyle(
                                .secondary
                            )

                            Text(
                                summaryText(
                                    for:
                                        sourcePost
                                )
                            )
                            .lineLimit(2)
                            .foregroundStyle(
                                .primary
                            )
                        }

                        Spacer()
                    }
                    .contentShape(
                        Rectangle()
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 8)
    }

    private func summaryText(
        for post: DiaryPost
    ) -> String {

        let trimmed =
            post.body.trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )

        if trimmed.isEmpty {
            return "本文なし"
        }

        return trimmed.replacingOccurrences(
            of: "\n",
            with: " "
        )
    }
}
