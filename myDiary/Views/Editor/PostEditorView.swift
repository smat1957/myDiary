//
//  PostEditorView.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/06.
//

import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct PostEditorView: View {

    let vm: TimelineViewModel
    /// nilなら新規作成
    let editingPost: DiaryPost?
    
    @Environment(\.dismiss)
    private var dismiss
    
    let parentPost: DiaryPost?
    
    @State private var bodyText = ""
    @State private var selectedImages: [DiaryImage] = []
    @State private var showingImagePicker = false
    @State private var viewerState: ImageViewerState?
    @State private var importedYouTubeURLs: Set<String> = []
    @State private var importedLinkURLs: Set<String> = []
    
    init(
        vm: TimelineViewModel,
        editingPost: DiaryPost? = nil,
        parentPost: DiaryPost? = nil
    ) {
        self.vm = vm
        self.editingPost = editingPost
        
        self.parentPost = parentPost
        
        let images = editingPost?.images ?? []

        _bodyText = State(
            initialValue: editingPost?.body ?? ""
        )

        _selectedImages = State(
            initialValue: images
        )

        let youtubeURLs: Set<String> = Set(
            images.compactMap { image -> String? in
                guard image.sourceType == .youtube else {
                    return nil
                }

                return image.sourceURL.map {
                    Self.normalizedURLKey($0)
                }
            }
        )

        let linkURLs: Set<String> = Set(
            images.compactMap { image -> String? in
                guard image.sourceType == .link else {
                    return nil
                }

                return image.sourceURL.map {
                    Self.normalizedURLKey($0)
                }
            }
        )
        
        _importedYouTubeURLs = State(
            initialValue: youtubeURLs
        )

        _importedLinkURLs = State(
            initialValue: linkURLs
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("本文")
                        .font(.headline)
                    TextEditor(text: $bodyText)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 220)
                        .onChange(of: bodyText) { _, newValue in
                            detectYouTubeURL(in: newValue)
                            detectLinkPreview(in: newValue)
                        }

                    Button {
                        showingImagePicker = true
                    } label: {
                        Label("画像を追加", systemImage: "photo")
                    }
                    
                    if !selectedImages.isEmpty {
                        ImageGridView(
                            images: selectedImages,
                            onTapImage: { image in
                                switch image.sourceType {

                                case .photo, .generated:
                                    let tempPost = DiaryPost(
                                        body: bodyText,
                                        createdAt: Date(),
                                        images: selectedImages
                                    )

                                    if let index = selectedImages.firstIndex(where: {
                                        $0.baseName == image.baseName
                                    }) {
                                        viewerState = ImageViewerState(
                                            post: tempPost,
                                            imageIndex: index
                                        )
                                    }

                                case .youtube, .link:
                                    if let url = image.sourceURL {
                                        NSWorkspace.shared.open(url)
                                    }
                                }
                            },
                            onDelete: { deletedImage in
                                selectedImages.removeAll {
                                    $0.baseName == deletedImage.baseName
                                }
                                ImageStore.shared.delete(deletedImage)
                            },
                            onOpenSource: { image in
                                if let url = image.sourceURL {
                                    NSWorkspace.shared.open(url)
                                }
                            }
                        )
                        .frame(maxWidth: .infinity)
                        .clipped()
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .navigationTitle(editingPost == nil ? "新しい投稿" : "投稿を編集")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        if let editingPost {
                            var updated = editingPost
                            updated.body = bodyText
                            updated.images = selectedImages
                            vm.updatePost(updated)
                        } else {
                            let post = DiaryPost(
                                body: bodyText,
                                createdAt: Date(),
                                parentPostId: parentPost?.id,
                                images: selectedImages
                            )
                            vm.addPost(post)
                        }
                        dismiss()
                    }
                    .disabled(
                        bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        && selectedImages.isEmpty
                    )
                }
            }
        }
        .frame(width: 600, height: 600)
        .sheet(item: $viewerState) { state in
            ImageViewerView(
                state: state,

                onDelete: { _, deletedImage in
                    selectedImages.removeAll {
                        $0.baseName == deletedImage.baseName
                    }

                    ImageStore.shared.delete(
                        deletedImage
                    )
                },

                onUpdateImageOrder: { updatedPost in
                    selectedImages =
                        updatedPost.images
                }
            )
        }
        .onAppear {
            guard let editingPost else {
                return
            }

            bodyText = editingPost.body
            selectedImages = editingPost.images

            importedYouTubeURLs = Set(
                editingPost.images
                    .filter { $0.sourceType == .youtube }
                    .compactMap { image in
                        image.sourceURL.flatMap {
                            YouTubeHelper.videoID(from: $0)
                        }
                    }
            )
        }
        .fileImporter(
            isPresented: $showingImagePicker,
            allowedContentTypes: [.image],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):

                for url in urls {
                    do {
                        let diaryImage = try ImageStore.shared.importImage(from: url)
                        selectedImages.append(diaryImage)
                        

                    } catch {
                        print("画像コピー失敗:", error)
                    }
                }

            case .failure(let error):
                print("画像選択エラー:", error)
            }
        }
    }
    
    private static func normalizedURLKey(_ url: URL) -> String {
        var value = url.absoluteString
            .trimmingCharacters(in: .whitespacesAndNewlines)

        while value.hasSuffix("?") || value.hasSuffix("&") {
            value.removeLast()
        }

        return value
    }
    
    private func detectYouTubeURL(in text: String) {
        let urls = YouTubeHelper.youtubeURLs(in: text)

        for url in urls {
            guard let videoID = YouTubeHelper.videoID(from: url) else {
                continue
            }

            guard !importedYouTubeURLs.contains(videoID) else {
                continue
            }

            importedYouTubeURLs.insert(videoID)

            Task {
                do {
                    let image = try await ImageStore.shared.importYoutubeThumbnail(
                        from: url
                    )

                    await MainActor.run {
                        selectedImages.insert(image, at: 0)
                    }
                } catch {
                    print("YouTubeサムネイル取得失敗:", error)
                }
            }
        }
    }
    
    private func detectLinkPreview(in text: String) {

        guard let detector = try? NSDataDetector(
            types: NSTextCheckingResult.CheckingType.link.rawValue
        ) else {
            return
        }

        let range = NSRange(
            text.startIndex..<text.endIndex,
            in: text
        )

        let matches = detector.matches(
            in: text,
            options: [],
            range: range
        )

        for match in matches {

            guard let url = match.url else {
                continue
            }

            guard
                url.scheme == "http"
                || url.scheme == "https"
            else {
                continue
            }

            let key = Self.normalizedURLKey(url)

            guard !importedLinkURLs.contains(key) else {
                continue
            }

            // Task開始前に登録して二重起動を防ぐ
            importedLinkURLs.insert(key)

            Task {
                do {
                    let image = try await ImageStore.shared
                        .importLinkPreview(
                            from: url,
                            date: Date()
                        )

                    await MainActor.run {
                        selectedImages.append(image)
                    }

                } catch {
                    print(
                        "リンク画像取得失敗:",
                        url.absoluteString,
                        error.localizedDescription
                    )

                    await MainActor.run {
                        importedLinkURLs.remove(key)
                    }
                }
            }
        }
    }
    
    private func firstURL(in text: String) -> URL? {
        let detector = try? NSDataDetector(
            types: NSTextCheckingResult.CheckingType.link.rawValue
        )

        let range = NSRange(
            text.startIndex..<text.endIndex,
            in: text
        )

        return detector?
            .firstMatch(
                in: text,
                options: [],
                range: range
            )?
            .url
    }
}

#Preview {
    PostEditorView(
        vm: TimelineViewModel(),
        editingPost: nil
    )
}
