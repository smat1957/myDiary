//
//  PostCardHeaderView.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/16.
//

//
//  PostCardHeaderView.swift
//  myDiary
//

import SwiftUI

struct PostCardHeaderView: View {

    let post: DiaryPost

    let onLinkComment: (DiaryPost) -> Void
    let onReplyPost: (DiaryPost) -> Void
    let onOpenViewer: (DiaryPost) -> Void
    let onLinkPost: (DiaryPost) -> Void
    let onEditPost: (DiaryPost) -> Void
    let onDeletePost: (DiaryPost) -> Void

    var body: some View {

        HStack {

            Text(
                post.createdAt.formatted(
                    date: .abbreviated,
                    time: .shortened
                )
            )
            .font(.caption)
            .foregroundStyle(.secondary)

            Text("ID: \(post.id)")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Button {
                onLinkComment(post)
            } label: {
                Label(
                    "親投稿に紐付ける",
                    systemImage:
                        "arrow.turn.down.right"
                )
            }

            Spacer()

            Button {
                onReplyPost(post)
            } label: {
                Label(
                    "返信",
                    systemImage:
                        "arrowshape.turn.up.left"
                )
            }
            .buttonStyle(.plain)
            .help("コメントを追加")

            Button {
                onOpenViewer(post)
            } label: {
                Image(
                    systemName:
                        "photo.on.rectangle"
                )
            }
            .buttonStyle(.plain)
            .help("画像一覧を開く")

            Button {
                onLinkPost(post)
            } label: {
                Label(
                    "関連記事を追加",
                    systemImage: "link"
                )
            }
            .buttonStyle(.plain)
            .help("関連投稿を追加")

            Button {
                onEditPost(post)
            } label: {
                Image(
                    systemName: "pencil"
                )
            }
            .buttonStyle(.plain)
            .help("投稿を編集")

            Button {
                onDeletePost(post)
            } label: {
                Image(
                    systemName: "trash"
                )
            }
            .buttonStyle(.plain)
            .help("投稿を削除")
        }
    }
}
