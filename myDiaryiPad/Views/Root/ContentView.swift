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
import UniformTypeIdentifiers

struct ContentView: View {

    @State var vm = TimelineViewModel()
    @State private var selectedPostID: Int64?
    @State private var isShowingEditor = false
    
    private enum PackagePickerMode {
        case importPackage
        case exportDestination
    }
    @State private var packagePickerMode: PackagePickerMode?
    @State private var showingPackagePicker = false
    // 別ファイルの extension から使用するため private を付けない
    @State var importMessage = ""
    @State var exportMessage = ""
    @State private var viewerState: ImageViewerState?
    @Environment(\.openURL)
    private var openURL
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedPostID) {
                Section("Timeline") {
                    ForEach(vm.posts, id: \.id) { post in
                        NavigationLink(value: post.id) {
                            VStack(
                                alignment: .leading,
                                spacing: 4
                            ) {
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
                ToolbarItemGroup(
                    placement: .primaryAction
                ) {
                    Menu {
                        Button {
                            packagePickerMode = .importPackage
                            showingPackagePicker = true
                        } label: {
                            Label(
                                "Diary Packageを読み込む",
                                systemImage: "square.and.arrow.down"
                            )
                        }

                        Button {
                            packagePickerMode = .exportDestination
                            showingPackagePicker = true
                        } label: {
                            Label(
                                "Diary Packageを書き出す",
                                systemImage: "square.and.arrow.up"
                            )
                        }
                    } label: {
                        Label(
                            "Diary Package",
                            systemImage: "ellipsis.circle"
                        )
                    }
                    
                    Button {
                        isShowingEditor = true
                    } label: {
                        Label(
                            "新規投稿",
                            systemImage: "plus"
                        )
                    }
                }
            }
        }
        detail: {
            if let selectedPostID,
               let post = vm.posts.first(
                   where: {
                       $0.id == selectedPostID
                   }
               ) {
                ScrollView {
                    VStack(
                        alignment: .leading,
                        spacing: 16
                    ) {
                        Text(
                            post.createdAt.formatted(
                                date: .long,
                                time: .shortened
                            )
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                        Divider()

                        if !post.body.isEmpty {
                            Text(post.body)
                                .font(.body)
                                .textSelection(.enabled)
                        }

                        if !post.images.isEmpty {
                            ImageGridView(
                                images: post.images,
                                allowsDeletion: false,

                                onTapImage: { image in
                                    openImage(
                                        image,
                                        in: post
                                    )
                                },

                                onDelete: { _ in
                                },

                                onOpenSource: { image in
                                    guard let url =
                                        image.sourceURL
                                    else {
                                        return
                                    }

                                    openURL(url)
                                }
                            )
                            .frame(
                                maxWidth: .infinity
                            )
                            .clipped()
                        }
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
        .sheet(item: $viewerState) { state in
            ImageViewerView(
                state: state,
                onDelete: { post, image in
                    vm.deleteImage(
                        image,
                        from: post
                    )
                },
                onUpdateImageOrder: { updatedPost in
                    vm.updatePost(updatedPost)
                }
            )
        }
        .fileImporter(
            isPresented: $showingPackagePicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            let selectedMode = packagePickerMode
            packagePickerMode = nil

            switch result {
            case .success(let urls):
                guard let selectedURL = urls.first else {
                    switch selectedMode {
                    case .importPackage:
                        importMessage =
                            "読み込むDiary Packageが選択されませんでした。"

                    case .exportDestination:
                        exportMessage =
                            "書き出し先フォルダが選択されませんでした。"

                    case .none:
                        break
                    }
                    return
                }

                switch selectedMode {
                case .importPackage:
                    importPackage(from: selectedURL)

                case .exportDestination:
                    exportPackage(to: selectedURL)

                case .none:
                    break
                }

            case .failure(let error):
                switch selectedMode {
                case .importPackage:
                    importMessage = """
                    Diary Packageの選択に失敗しました。

                    \(error.localizedDescription)
                    """

                case .exportDestination:
                    exportMessage = """
                    書き出し先フォルダの選択に失敗しました。

                    \(error.localizedDescription)
                    """

                case .none:
                    break
                }
            }
        }
        .alert(
            "Diary Package読み込み",
            isPresented: Binding(
                get: {
                    !importMessage.isEmpty
                },
                set: { isPresented in
                    if !isPresented {
                        importMessage = ""
                    }
                }
            )
        ) {
            Button("OK") {
                importMessage = ""
            }
        } message: {
            Text(importMessage)
        }
        .alert(
            "Diary Package書き出し",
            isPresented: Binding(
                get: {
                    !exportMessage.isEmpty
                },
                set: { isPresented in
                    if !isPresented {
                        exportMessage = ""
                    }
                }
            )
        ) {
            Button("OK") {
                exportMessage = ""
            }
        }
        .sheet(isPresented: $isShowingEditor) {
            PostEditorView(vm: vm)
        }
        .sheet(
            isPresented: importProgressPresented
        ) {
            ProgressDialog(
                title: "Diary Packageを読み込んでいます",
                progress: vm.importProgress
            )
            .interactiveDismissDisabled()
        }

    }

    private func openImage(
        _ image: DiaryImage,
        in post: DiaryPost
    ) {
        guard let index = post.images.firstIndex(
            where: {
                $0.baseName == image.baseName
            }
        ) else {
            return
        }

        viewerState = ImageViewerState(
            post: post,
            imageIndex: index
        )
    }
    
    private var importProgressPresented: Binding<Bool> {
        Binding(
            get: {
                vm.importProgress.isRunning
            },
            set: { _ in
                // Import中は閉じさせない
            }
        )
    }
}

#Preview {
    ContentView()
}

