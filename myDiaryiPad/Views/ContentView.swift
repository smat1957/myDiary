//
//  ContentView.swift
//  myDiaryiPad
//
//  Created by 的池秋成 on 2026/07/20.
//
//
//  ContentView.swift
//  myDiaryiPad
//

import SwiftUI

struct ContentView: View {
    
    @State private var vm = TimelineViewModel()
    @State private var selectedPostID: Int64?
    @State private var isShowingEditor = false
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedPostID) {
                Section("Timeline") {
                    ForEach(vm.posts, id: \.id) { post in
                        NavigationLink(value: post.id) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(
                                    post.createdAt.formatted(
                                        date: .abbreviated,
                                        time: .shortened
                                    )
                                )
                                .font(.headline)

                                Text(post.body)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("myDiary")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isShowingEditor = true
                    } label: {
                        Label("新規投稿", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingEditor) {
                PostEditorView(vm: vm)
            }
        }
        detail: {
            if let selectedPostID,
               let post = vm.posts.first(
                   where: { $0.id == selectedPostID }
               ) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(
                            post.createdAt.formatted(
                                date: .long,
                                time: .shortened
                            )
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                        Divider()

                        Text(post.body)
                            .font(.body)
                    }
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .padding()
                }
                .navigationTitle("Diary")
                .navigationBarTitleDisplayMode(.inline)
            } else {
                ContentUnavailableView(
                    "Select a Post",
                    systemImage: "book.closed",
                    description: Text(
                        "Choose a diary entry from the timeline."
                    )
                )
            }
        }
    }
}

#Preview {
    ContentView()
}
