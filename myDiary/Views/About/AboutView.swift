//
//  AboutView.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/17.
//

import SwiftUI

struct AboutView: View {

    private var version: String {
        Bundle.main.infoDictionary?[
            "CFBundleShortVersionString"
        ] as? String ?? "Unknown"
    }

    private var build: String {
        Bundle.main.infoDictionary?[
            "CFBundleVersion"
        ] as? String ?? "Unknown"
    }

    var body: some View {

        VStack(spacing: 18) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .interpolation(.high)
                .frame(width: 120, height: 120)
                .padding(.bottom, 8)

            Text("myDiary")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Version \(version) (\(build))")
                .foregroundStyle(.secondary)

            Divider()

            Text("""
A local-first diary for preserving your memories.

Store your diary, photos, comments,
and related posts on your own Mac.
""")
            .multilineTextAlignment(.center)

            Divider()

            VStack(alignment: .leading, spacing: 6) {

                Label("Local-first", systemImage: "internaldrive")

                Label("Photo management", systemImage: "photo")

                Label("Threaded comments", systemImage: "text.bubble")

                Label("Related posts", systemImage: "link")

                Label("Full-text search", systemImage: "magnifyingglass")

                Label(
                    "Diary Package Import / Export",
                    systemImage: "square.and.arrow.down"
                )

            }

            Divider()

            Link(
                "GitHub Repository",
                destination: URL(
                    string: "https://github.com/smat1957/myDiary"
                )!
            )

            Text("""
Copyright © 2026
Shusei Matoike
""")
            .font(.footnote)
            .foregroundStyle(.secondary)

        }
        .padding(30)
        .frame(width: 420)
    }
}

#Preview {
    AboutView()
}
