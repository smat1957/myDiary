//
//  ContentView.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/06.
//

import SwiftUI
import UniformTypeIdentifiers

enum FolderSelectionPurpose {
    case importPackage
    case exportPackage
}

struct ContentView: View {

    @State var vm = TimelineViewModel()

    @State private var showingEditor = false
    @State private var editingPost: DiaryPost?

    @State var importMessage: String?
    @State var exportMessage: String?

    @State private var showingFolderSelector = false
    @State private var folderSelectionPurpose: FolderSelectionPurpose?

    @State private var replyParentPost: DiaryPost?
    
    @State private var showingSearch = false
    
    //@Environment(\.openWindow)
    //private var openWindow
    
    var body: some View {
        NavigationStack {
            TimelineView(
                posts: vm.posts,
                postDictionary: vm.postDictionary,
                currentPostID: vm.currentPostID,
                focusedPostID: vm.focusedPostID,

                onClearFocusedPost: {
                    vm.clearFocusedPost()
                },

                onDeleteImage: { post, image in
                    vm.deleteImage(
                        image,
                        from: post
                    )
                },
                
                onUpdateImageOrder: {
                    updatedPost in

                    vm.updatePost(
                        updatedPost
                    )
                },
                
                onDeletePost: { post in
                    vm.deletePost(post)
                },

                onEditPost: { post in
                    editingPost = post
                },

                onCreateLink: { sourcePost, targetPost in

                    //print(
                    //    "ContentView onCreateLink:",
                    //    sourcePost.id,
                    //    "->",
                    //    targetPost.id
                    //)

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

                backlinkDictionary: vm.backlinkDictionary,

                onLinkComment: { comment, parent in
                    vm.linkComment(
                        comment,
                        to: parent
                    )
                },
                onUnlinkComment: { comment in
                    vm.unlinkComment(comment)
                },
                
                onReplyPost: { parentPost in
                    replyParentPost = parentPost
                }
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
                        folderSelectionPurpose = .importPackage
                        showingFolderSelector = true
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                    }
                    .help(String(localized: "package.import.help"))
                    //.help("Diary Packageを読み込む")

                    Button {
                        folderSelectionPurpose = .exportPackage
                        showingFolderSelector = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .help(String(localized: "package.export.help"))
                    //.help("Diary Packageを書き出す")

                    Button {
                        showingSearch = true
                    } label: {
                        Image(
                            systemName: "magnifyingglass"
                        )
                    }
                    .help(String(localized: "post.search.help"))
                    //.help("投稿を検索")
                    
                    Button {
                        showingEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .help(String(localized: "post.new.help"))
                    //.help("新しい投稿")
                    
                    //Button {
                    //    openWindow(id: "about")
                    //} label: {
                    //    Image(systemName: "info.circle")
                    //}
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
            .sheet(item: $replyParentPost) { parentPost in
                PostEditorView(
                    vm: vm,
                    editingPost: nil,
                    parentPost: parentPost
                )
            }
        }
        .sheet(
            isPresented: $showingSearch
        ) {
            PostSearchView(
                vm: vm,
                onSelect: { result in
                    vm.openSearchResult(
                        result
                    )
                }
            )
        }
        .fileImporter(
            isPresented: $showingFolderSelector,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in

            guard
                let purpose = folderSelectionPurpose
            else {
                return
            }

            folderSelectionPurpose = nil

            switch result {

            case .success(let urls):

                guard let selectedFolder = urls.first else {
                    return
                }

                switch purpose {

                case .importPackage:
                    importPackage(
                        from: selectedFolder
                    )

                case .exportPackage:
                    exportPackage(
                        to: selectedFolder
                    )
                }

            case .failure(let error):

                switch purpose {

                case .importPackage:
                    importMessage = String(localized: "package.import.folderSelectionFailed")
                    //"""
                    //フォルダ選択に失敗しました。
                    //
                    //\(error.localizedDescription)
                    //"""

                case .exportPackage:
                    exportMessage = String(localized: "package.export.folderSelectionFailed")
                    //"""
                    //書き出し先フォルダの選択に失敗しました。
                    //
                    //\(error.localizedDescription)
                    //"""
                }
            }
        }
        .alert(
            //"インポート",
            String(localized: "package.import.title"),
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
        .alert(
            //"エクスポート",
            String(localized: "package.export.title"),
            isPresented: Binding(
                get: {
                    exportMessage != nil
                },
                set: {
                    if !$0 {
                        exportMessage = nil
                    }
                }
            )
        ) {
            Button("OK") {
                exportMessage = nil
            }
        } message: {
            Text(exportMessage ?? "")
        }
    }

}
