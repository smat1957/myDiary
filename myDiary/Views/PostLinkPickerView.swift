//
//  PostLinkPickerView.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/09.
//

import SwiftUI

struct PostLinkPickerView: View {

    let posts: [DiaryPost]
    let sourcePost: DiaryPost
    let onSelect: (DiaryPost) -> Void

    @Environment(\.dismiss)
    private var dismiss

    @State private var searchText = ""

    private var filteredPosts: [DiaryPost] {
        let candidates = posts.filter {
            $0.id != sourcePost.id
        }

        let keyword = searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !keyword.isEmpty else {
            return candidates
        }

        return candidates.filter { post in
            post.body.localizedCaseInsensitiveContains(keyword)
            || String(post.id).contains(keyword)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {

                TextField("本文またはIDで検索", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                List(filteredPosts) { post in
                    Button {
                        
                        //print(
                        //    "PostLinkPickerView 選択:",
                        //    sourcePost.id,
                        //    "->",
                        //    post.id
                        //)

                        onSelect(post)
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("ID: \(post.id)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Spacer()

                                Text(post.createdAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }

                            Text(post.body)
                                .lineLimit(3)
                                .foregroundStyle(.primary)

                            if !post.images.isEmpty {
                                Text("画像 \(post.images.count) 枚")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("リンク先を選択")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 600, height: 500)
    }
}
