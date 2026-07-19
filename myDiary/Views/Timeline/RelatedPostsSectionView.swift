//
//  RelatedPostsSectionView.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/16.
//

//
//  RelatedPostsSectionView.swift
//  myDiary
//

import SwiftUI

struct RelatedPostsSectionView: View {

    let post: DiaryPost
    let postDictionary:
        [Int64: DiaryPost]

    let onOpenLinkedPost:
        (Int64) -> Void

    let onDeleteLink:
        (Int64) -> Void

    let onMoveLink:
        (Int, Int) -> Void

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            Divider()

            //Text("関連投稿")
            Text(String(localized: "related.title"))
                .font(.headline)

            ForEach(
                Array(
                    post.links.enumerated()
                ),
                id: \.element.id
            ) { index, link in

                if let targetPost =
                    postDictionary[
                        link.toPostId
                    ]
                {
                    relatedPostRow(
                        targetPost,
                        index: index
                    )

                } else {
                    missingPostRow(
                        targetPostID:
                            link.toPostId
                    )
                }
            }
        }
        .padding(.top, 8)
    }

    private func relatedPostRow(
        _ targetPost: DiaryPost,
        index: Int
    ) -> some View {

        HStack(spacing: 10) {

            Button {
                onOpenLinkedPost(
                    targetPost.id
                )
            } label: {

                HStack(
                    alignment: .top,
                    spacing: 8
                ) {

                    Image(
                        systemName:
                            "arrow.turn.down.right"
                    )
                    .padding(.top, 3)

                    VStack(
                        alignment: .leading,
                        spacing: 3
                    ) {

                        Text(
                            "ID: \(targetPost.id)"
                        )
                        .font(.caption)
                        .foregroundStyle(
                            .secondary
                        )

                        Text(
                            summaryText(
                                for: targetPost
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

            Button {
                onMoveLink(
                    index,
                    index - 1
                )
            } label: {
                Image(
                    systemName: "chevron.up"
                )
            }
            .buttonStyle(.plain)
            .disabled(index == 0)
            .help(String(localized: "common.moveUp"))
            //.help("上へ移動")

            Button {
                onMoveLink(
                    index,
                    index + 1
                )
            } label: {
                Image(
                    systemName: "chevron.down"
                )
            }
            .buttonStyle(.plain)
            .disabled(
                index
                    == post.links.count - 1
            )
            .help(String(localized: "common.moveDown"))
            //.help("下へ移動")

            Button {
                onDeleteLink(
                    targetPost.id
                )
            } label: {
                Image(
                    systemName:
                        "xmark.circle"
                )
            }
            .buttonStyle(.plain)
            .help(String(localized: "related.remove"))
            //.help("関連投稿から削除")
        }
        .padding(.vertical, 3)
    }

    private func missingPostRow(
        targetPostID: Int64
    ) -> some View {

        HStack {

            Image(
                systemName:
                    "exclamationmark.triangle"
            )
            .foregroundStyle(.secondary)

            Text(
                String(
                        localized: "related.missing \(targetPostID)"
                    )
                //"投稿 ID \(targetPostID) が見つかりません"
            )
            .font(.caption)
            .foregroundStyle(.secondary)

            Spacer()

            Button {
                onDeleteLink(
                    targetPostID
                )
            } label: {
                Image(
                    systemName:
                        "xmark.circle"
                )
            }
            .buttonStyle(.plain)
        }
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
            return String(localized: "post.noBody")
            //return "本文なし"
        }

        return trimmed.replacingOccurrences(
            of: "\n",
            with: " "
        )
    }
}
