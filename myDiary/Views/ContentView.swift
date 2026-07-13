//
//  ContentView.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/06.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {

    @State private var vm = TimelineViewModel()
    @State private var showingEditor = false
    @State private var editingPost: DiaryPost?
    @State private var showingImporter = false
    @State private var importMessage: String?
    
    var body: some View {
        NavigationStack {
            TimelineView(
                posts: vm.posts,
                postDictionary: vm.postDictionary,
                currentPostID: vm.currentPostID,

                onDeleteImage: { post, image in
                    vm.deleteImage(
                        image,
                        from: post
                    )
                },

                onDeletePost: { post in
                    vm.deletePost(post)
                },

                onEditPost: { post in
                    editingPost = post
                },

                onCreateLink: { sourcePost, targetPost in
                    vm.addLink(
                        from: sourcePost,
                        to: targetPost
                    )
                },

                onOpenLinkedPost: { targetPostID, sourcePostID in
                    vm.openLinkedPost(
                        targetPostID,
                        from: sourcePostID
                    )
                },
                onDeleteLink: { sourcePost, targetPostID in
                    vm.removeLink(
                        from: sourcePost,
                        to: targetPostID
                    )
                },

                onMoveLink: { sourcePost, sourceIndex, destinationIndex in
                    vm.moveLink(
                        in: sourcePost,
                        from: sourceIndex,
                        to: destinationIndex
                    )
                },
                
                backlinkDictionary: vm.backlinkDictionary

            )
            .navigationTitle("Diary")
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button {
                        vm.goBack()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(!vm.canGoBack)
                }

                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        showingImporter = true
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                    }
                    .help("JSONを読み込む")

                    Button {
                        showingEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .help("新しい投稿")
                }
            }
            .sheet(isPresented: $showingEditor) {
                PostEditorView(
                    vm: vm,
                    editingPost: nil
                )
            }
            .sheet(item: $editingPost) { post in
                PostEditorView(
                    vm: vm,
                    editingPost: post
                )
            }
        }

        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let packageURL = urls.first else {
                    return
                }

                Task {
                    do {
                        let importer = DiaryImporter()

                        let importResult = try await importer.importPackage(
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
                
            case .failure(let error):
                importMessage = """
                フォルダ選択に失敗しました。

                \(error.localizedDescription)
                """
            }
        }
        .alert(
            "インポート",
            isPresented: Binding(
                get: { importMessage != nil },
                set: { if !$0 { importMessage = nil } }
            )
        ) {
            Button("OK") {
                importMessage = nil
            }
        } message: {
            Text(importMessage ?? "")
        }
    }
}
