//
//  PostSearchView.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/16.
//

import SwiftUI

struct PostSearchView: View {

    let vm: TimelineViewModel

    let onSelect:
        (TimelineSearchResult) -> Void

    @Environment(\.dismiss)
    private var dismiss

    @State private var searchText = ""

    private var normalizedSearchText: String {
        searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    private var results:
        [TimelineSearchResult]
    {
        vm.searchPosts(
            query: normalizedSearchText
        )
    }

    var body: some View {

        NavigationStack {

            VStack(spacing: 0) {

                searchField

                Divider()

                if normalizedSearchText.isEmpty {

                    emptySearchView

                } else {

                    resultCountView

                    Divider()

                    if results.isEmpty {

                        noResultsView

                    } else {

                        resultList
                    }
                }
            }
            .frame(
                minWidth: 600,
                minHeight: 500
            )
            .navigationTitle("検索")
            .toolbar {

                ToolbarItem(
                    placement: .cancellationAction
                ) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Search field

    private var searchField: some View {

        TextField(
            "本文・日付・IDを検索",
            text: $searchText
        )
        .textFieldStyle(
            .roundedBorder
        )
        .padding()
    }

    // MARK: - Result count

    private var resultCountView: some View {

        HStack {

            Text("検索結果")
                .font(.headline)

            Text("\(results.count)件")
                .font(.subheadline)
                .foregroundStyle(
                    .secondary
                )

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    // MARK: - Empty states

    private var emptySearchView: some View {

        ContentUnavailableView(
            "投稿を検索",
            systemImage:
                "magnifyingglass",
            description:
                Text(
                    "検索する文字を入力してください。"
                )
        )
    }

    private var noResultsView: some View {

        ContentUnavailableView(
            "検索結果なし",
            systemImage:
                "magnifyingglass",
            description:
                Text(
                    "「\(normalizedSearchText)」に一致する投稿はありません。"
                )
        )
    }

    // MARK: - Results

    private var resultList: some View {

        List(results) { result in

            Button {

                /*
                 先に検索結果をTimelineへ通知し、
                 その後で検索画面を閉じる。
                 */
                onSelect(result)
                dismiss()

            } label: {

                resultRow(
                    result
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func resultRow(
        _ result: TimelineSearchResult
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 6
        ) {

            HStack {

                Text(
                    result.post.diaryDate
                        .formatted(
                            date: .abbreviated,
                            time: .shortened
                        )
                )
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )

                if result.isComment {

                    Label(
                        "コメント",
                        systemImage:
                            "arrowshape.turn.up.left"
                    )
                    .font(.caption2)
                    .foregroundStyle(
                        .secondary
                    )
                }

                Spacer()

                Text(
                    "ID: \(result.post.id)"
                )
                .font(.caption2)
                .foregroundStyle(
                    .tertiary
                )
            }

            Text(result.summary)
                .lineLimit(3)
                .foregroundStyle(
                    .primary
                )

            if !result.post.images.isEmpty {

                Label(
                    "\(result.post.images.count)件のメディア",
                    systemImage:
                        "photo.on.rectangle"
                )
                .font(.caption2)
                .foregroundStyle(
                    .secondary
                )
            }
        }
        .padding(.vertical, 4)
        .contentShape(
            Rectangle()
        )
    }
}
