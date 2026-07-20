//
//  ParentPostPickerView.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/14.
//
//
//  ParentPostPickerView.swift
//  myDiary
//

import SwiftUI

struct ParentPostPickerView: View {

    let comment: DiaryPost
    let posts: [DiaryPost]

    let onSelect: (DiaryPost) -> Void

    @Environment(\.dismiss)
    private var dismiss

    @State private var searchText = ""
    
    /*
    private var candidates: [DiaryPost] {

        posts
            .filter { post in
                // 自分自身を除外
                post.id != comment.id

                // 他の投稿の子になっている投稿は
                // 親候補にしない
                && post.parentPostId == nil
            }
            .filter { post in

                guard !searchText.isEmpty else {
                    return true
                }

                return post.body
                    .localizedCaseInsensitiveContains(
                        searchText
                    )
            }
            .sorted {
                $0.diaryDate > $1.diaryDate
            }
    }
    
    private var candidates: [DiaryPost] {

        let query = searchText
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return posts
            .filter {
                $0.id != comment.id
                && $0.parentPostId == nil
            }
            .filter { post in

                guard !query.isEmpty else {
                    return true
                }

                let dateText =
                    post.diaryDate.formatted(
                        date: .numeric,
                        time: .omitted
                    )

                return
                    post.body
                        .localizedCaseInsensitiveContains(
                            query
                        )
                    ||
                    dateText
                        .localizedCaseInsensitiveContains(
                            query
                        )
            }
            .sorted {
                $0.diaryDate > $1.diaryDate
            }
    }
    */
    private var candidates: [DiaryPost] {

        let query = searchText
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        let descendantIDs = descendantPostIDs(
            of: comment.id
        )

        return posts
            .filter { post in

                // 自分自身は除外
                post.id != comment.id

                // 自分の子孫は除外
                && !descendantIDs.contains(
                    post.id
                )
            }
            .filter { post in

                guard !query.isEmpty else {
                    return true
                }

                let dateText =
                    post.diaryDate.formatted(
                        date: .numeric,
                        time: .omitted
                    )

                return
                    post.body
                        .localizedCaseInsensitiveContains(
                            query
                        )
                    ||
                    dateText
                        .localizedCaseInsensitiveContains(
                            query
                        )
            }
            .sorted {
                $0.diaryDate > $1.diaryDate
            }
    }
    
    private func descendantPostIDs(
        of postID: Int64
    ) -> Set<Int64> {

        var result: Set<Int64> = []
        var pending: [Int64] = [postID]

        while let parentID = pending.popLast() {

            let children = posts.filter {
                $0.parentPostId == parentID
            }

            for child in children {

                if result.insert(child.id).inserted {
                    pending.append(child.id)
                }
            }
        }

        return result
    }
    
    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 16
        ) {

            // MARK: - Header

            HStack {

                Text("親投稿を選択")
                    .font(.title2)
                    .bold()

                Spacer()

                Button("キャンセル") {
                    dismiss()
                }
            }

            Divider()

            // MARK: - Comment

            VStack(
                alignment: .leading,
                spacing: 6
            ) {

                Text("紐付ける投稿")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(
                    comment.diaryDate.formatted(
                        date: .abbreviated,
                        time: .shortened
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                Text(comment.body)
                    .lineLimit(5)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
            }
            .padding(10)
            .background(
                Color.secondary.opacity(0.08)
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 8
                )
            )

            // MARK: - Search

            TextField(
                "親投稿の本文を検索",
                text: $searchText
            )
            .textFieldStyle(.roundedBorder)

            Text(
                "候補 \(candidates.count) 件"
            )
            .font(.caption)
            .foregroundStyle(.secondary)

            // MARK: - Candidates

            ScrollView {

                LazyVStack(
                    alignment: .leading,
                    spacing: 8
                ) {

                    ForEach(candidates) { post in

                        Button {
                            onSelect(post)
                            dismiss()

                        } label: {

                            VStack(
                                alignment: .leading,
                                spacing: 6
                            ) {

                                Text(
                                    post.diaryDate.formatted(
                                        date: .abbreviated,
                                        time: .shortened
                                    )
                                )
                                .font(.caption)
                                .foregroundStyle(.secondary)

                                if post.body
                                    .trimmingCharacters(
                                        in: .whitespacesAndNewlines
                                    )
                                    .isEmpty
                                {
                                    Text("本文なし")
                                        .foregroundStyle(.secondary)

                                } else {

                                    Text(post.body)
                                        .lineLimit(4)
                                        .foregroundStyle(.primary)
                                }

                                if !post.images.isEmpty {

                                    Label(
                                        //"画像 \(post.images.count)枚",
                                        String.localizedStringWithFormat(
                                            String(localized: "images.count"),
                                            Int64(post.images.count)
                                        ),
                                        systemImage: "photo"
                                    )
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }
                            }
                            .padding(10)
                            .frame(
                                maxWidth: .infinity,
                                alignment: .leading
                            )
                            .background(
                                Color.secondary.opacity(0.06)
                            )
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: 8
                                )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(20)
        .frame(
            width: 700,
            height: 700
        )
    }
    
}
