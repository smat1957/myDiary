//
//  ContentView+DiaryPackage.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/16.
//

//
//  ContentView+DiaryPackage.swift
//  myDiary
//

import SwiftUI

extension ContentView {

    // MARK: - Import

    func importPackage(
        from packageURL: URL
    ) {
        Task {
            do {
                let importer = DiaryImporter()

                let importResult =
                    try await importer.importPackage(
                        from: packageURL
                    )

                await MainActor.run {
                    vm.loadPosts()

                    importMessage = """
                    Diary Packageの読み込みが完了しました。

                    新規投稿: \(importResult.importedPostCount)件
                    既存投稿: \(importResult.skippedPostCount)件
                    メディア: \(importResult.importedMediaCount)件
                    投稿リンク: \(importResult.importedLinkCount)件
                    メディアスキップ: \(importResult.skippedMediaCount)件
                    """
                }

            } catch {
                await MainActor.run {
                    importMessage = """
                    Diary Packageの読み込みに失敗しました。

                    \(error.localizedDescription)
                    """
                }
            }
        }
    }

    // MARK: - Export

    func exportPackage(
        to selectedFolder: URL
    ) {
        let accessing =
            selectedFolder
                .startAccessingSecurityScopedResource()

        defer {
            if accessing {
                selectedFolder
                    .stopAccessingSecurityScopedResource()
            }
        }

        do {
            let exporter = DiaryExporter()

            let exportResult =
                try exporter.exportPackage(
                    posts: vm.posts,
                    title: "myDiary Export",
                    to: selectedFolder
                )

            exportMessage = """
            Diary Packageの書き出しが完了しました。

            投稿: \(exportResult.exportedPostCount)件
            メディア: \(exportResult.exportedMediaCount)件
            投稿リンク: \(exportResult.exportedLinkCount)件

            保存先:
            \(exportResult.outputURL.path)
            """

        } catch {
            exportMessage = """
            Diary Packageの書き出しに失敗しました。

            \(error.localizedDescription)
            """
        }
    }
}
