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
    
    // 後で TimelineViewModel に置き換える
    @State private var vm = TimelineViewModel()

    @State private var selectedPostID: Int?
    
    private let samplePosts = Array(1...10)
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedPostID) {
                Section("Timeline") {
                    //ForEach(1...10, id: \.self) { postID in
                    ForEach(samplePosts, id: \.self) { postID in
                        NavigationLink(value: postID) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Post \(postID)")
                                    .font(.headline)

                                Text("This is a sample diary entry.")
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
        } detail: {
            if let selectedPostID {
                SamplePostDetailView(
                    postID: selectedPostID
                )
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

private struct SamplePostDetailView: View {

    let postID: Int

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Post \(postID)")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text(
                    Date.now.formatted(
                        date: .long,
                        time: .shortened
                    )
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Divider()

                Text("""
                This is a temporary diary entry used to verify the iPad layout.

                The real diary data will be connected after the basic NavigationSplitView structure is working.
                """)
                .font(.body)
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .padding()
        }
        .navigationTitle("Post \(postID)")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ContentView()
}
