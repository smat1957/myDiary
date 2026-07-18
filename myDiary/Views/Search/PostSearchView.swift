//
//  PostSearchView.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/16.
//
//
//  PostSearchView.swift
//  myDiary
//

import SwiftUI

struct PostSearchView: View {

    let vm: TimelineViewModel

    let onSelect:
        (TimelineSearchResult) -> Void

    @Environment(\.dismiss)
    private var dismiss

    // 最後の検索語を保存する
    @AppStorage("lastSearchKeyword")
    private var keyword = ""

    // 大文字・小文字を区別するか保存する
    @AppStorage("searchCaseSensitive")
    private var caseSensitive = false   // 初回は aa、つまり大文字・小文字を区別しません
    // private var caseSensitive = true // 初回から区別する状態にしたい場合
    
    // 日付は検索画面を開くたびに初期化する
    @State private var selectedDate = Date()
    @State private var isDateFilterEnabled = false
    @State private var isCalendarPresented = false

    private var normalizedKeyword: String {
        keyword.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    private var searchDate: Date? {
        isDateFilterEnabled
            ? selectedDate
            : nil
    }

    private var hasSearchCondition: Bool {
        !normalizedKeyword.isEmpty
        || isDateFilterEnabled
    }

    private var results: [TimelineSearchResult] {
        vm.searchPosts(
            keyword: normalizedKeyword,
            date: searchDate,
            caseSensitive: caseSensitive
        )
    }

    var body: some View {

        NavigationStack {

            VStack(spacing: 0) {

                searchControls

                Divider()

                if !hasSearchCondition {

                    ContentUnavailableView(
                        "投稿を検索",
                        systemImage: "magnifyingglass",
                        description: Text(
                            "キーワードまたは投稿日を指定してください。"
                        )
                    )

                } else if results.isEmpty {

                    ContentUnavailableView(
                        "検索結果なし",
                        systemImage: "magnifyingglass",
                        description: Text(
                            "指定した条件に一致する投稿はありません。"
                        )
                    )

                } else {

                    resultList
                }
            }
            .frame(
                minWidth: 760,
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

    // MARK: - Search controls

    private var searchControls: some View {

        HStack(spacing: 9) {

            // 最新投稿へ移動
            Button {
                openNewestPost()
            } label: {
                Image(
                    systemName: "backward.end.fill"
                )
            }
            .help("最新の投稿へ移動")
            .disabled(vm.newestRootPost == nil)

            // 日付選択
            Button {
                isCalendarPresented.toggle()
            } label: {
                Image(
                    systemName:
                        isDateFilterEnabled
                        ? "calendar.circle.fill"
                        : "calendar"
                )
            }
            .help(calendarHelpText)
            .popover(
                isPresented: $isCalendarPresented,
                arrowEdge: .top
            ) {
                calendarPopover
            }

            // 最古投稿へ移動
            Button {
                openOldestPost()
            } label: {
                Image(
                    systemName: "forward.end.fill"
                )
            }
            .help("最古の投稿へ移動")
            .disabled(vm.oldestRootPost == nil)

            Divider()
                .frame(height: 24)

            searchField

            // 大文字・小文字切替
            Button {
                caseSensitive.toggle()
            } label: {
                Text(
                    caseSensitive
                        ? "Aa"
                        : "aa"
                )
                .font(
                    .system(
                        size: 12,
                        weight: .semibold,
                        design: .rounded
                    )
                )
                .frame(
                    minWidth: 24,
                    minHeight: 20
                )
            }
            .buttonStyle(
                SearchCaseButtonStyle(
                    isEnabled: caseSensitive
                )
            )
            .help(
                caseSensitive
                    ? "大文字・小文字を区別します"
                    : "大文字・小文字を区別しません"
            )

            // 条件クリア
            Button {
                clearSearchConditions()
            } label: {
                Image(
                    systemName: "xmark.circle.fill"
                )
            }
            .buttonStyle(.plain)
            .foregroundStyle(
                hasSearchCondition
                    ? .secondary
                    : .tertiary
            )
            .help("検索条件をクリア")
            .disabled(!hasSearchCondition)

            // 件数
            Text(resultCountText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .frame(
                    minWidth: 52,
                    alignment: .trailing
                )
        }
        .padding()
    }

    private var searchField: some View {

        HStack(spacing: 7) {

            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField(
                "キーワード",
                text: $keyword
            )
            .textFieldStyle(.plain)
        }
        .padding(.horizontal, 10)
        .frame(
            minWidth: 300,
            maxWidth: .infinity,
            minHeight: 29
        )
        .background {
            RoundedRectangle(
                cornerRadius: 8,
                style: .continuous
            )
            .fill(
                Color(
                    nsColor:
                        .controlBackgroundColor
                )
            )
        }
        .overlay {
            RoundedRectangle(
                cornerRadius: 8,
                style: .continuous
            )
            .stroke(
                Color.secondary.opacity(0.25),
                lineWidth: 1
            )
        }
    }

    // MARK: - Result count

    private var resultCountText: String {

        guard hasSearchCondition else {
            return ""
        }

        return "\(results.count)件"
    }

    // MARK: - Calendar

    private var calendarHelpText: String {

        guard isDateFilterEnabled else {
            return "投稿日を選択"
        }

        return selectedDate.formatted(
            date: .long,
            time: .omitted
        )
    }

    private var calendarPopover: some View {

        VStack(spacing: 12) {

            DatePicker(
                "投稿日",
                selection: $selectedDate,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .labelsHidden()
            .onChange(
                of: selectedDate
            ) { _, _ in
                isDateFilterEnabled = true
            }

            Divider()

            HStack {

                if isDateFilterEnabled {

                    Text(
                        selectedDate.formatted(
                            date: .long,
                            time: .omitted
                        )
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Button("日付指定を解除") {
                    isDateFilterEnabled = false
                    isCalendarPresented = false
                }
                .disabled(!isDateFilterEnabled)

                Button("完了") {
                    isDateFilterEnabled = true
                    isCalendarPresented = false
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 380)
    }

    // MARK: - Navigation

    private func openNewestPost() {

        guard let post = vm.newestRootPost else {
            return
        }

        onSelect(
            TimelineSearchResult(
                post: post
            )
        )

        dismiss()
    }

    private func openOldestPost() {

        guard let post = vm.oldestRootPost else {
            return
        }

        onSelect(
            TimelineSearchResult(
                post: post
            )
        )

        dismiss()
    }

    // MARK: - Clear

    private func clearSearchConditions() {
        keyword = ""
        isDateFilterEnabled = false
        isCalendarPresented = false
    }

    // MARK: - Results

    private var resultList: some View {

        List(results) { result in

            Button {

                onSelect(result)
                dismiss()

            } label: {

                resultRow(result)
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
                .foregroundStyle(.secondary)

                if result.isComment {

                    Label(
                        "コメント",
                        systemImage:
                            "arrowshape.turn.up.left"
                    )
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Text("ID: \(result.post.id)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Text(result.summary)
                .lineLimit(3)
                .foregroundStyle(.primary)

            if !result.post.images.isEmpty {

                Label(
                    "\(result.post.images.count)件のメディア",
                    systemImage:
                        "photo.on.rectangle"
                )
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

private struct SearchCaseButtonStyle:
    ButtonStyle
{
    let isEnabled: Bool

    func makeBody(
        configuration: Configuration
    ) -> some View {

        configuration.label
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .foregroundStyle(
                isEnabled
                    ? Color.white
                    : Color.primary
            )
            .background {
                RoundedRectangle(
                    cornerRadius: 5,
                    style: .continuous
                )
                .fill(
                    isEnabled
                        ? Color.accentColor
                        : Color.secondary.opacity(0.12)
                )
            }
            .opacity(
                configuration.isPressed
                    ? 0.7
                    : 1
            )
    }
}
