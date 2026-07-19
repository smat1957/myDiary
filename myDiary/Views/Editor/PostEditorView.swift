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
    @State private var createdCachedImages: [DiaryImage] = []
    
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
                    //Text("本文")
                    Text(String(localized: "editor.body"))
                        .font(.headline)
                    TextEditor(text: $bodyText)
                        .help(String(localized: "editor.body.placeholder"))
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 220)
                        .onChange(of: bodyText) { _, newValue in

                            let urls = detectedURLs(
                                in: newValue
                            )

                            detectURLs(urls)
                        }
                    /* このonChangeはコメントのまま残しておく
                        .onChange(of: bodyText) { _, newValue in

                            let urls = detectedURLs(in: newValue)

                            detectYouTubeURLs(urls)
                            detectLinkPreviews(urls)
                        }
                     */
                    Button {
                        showingImagePicker = true
                    } label: {
                        //Label("画像を追加", systemImage: "photo")
                        Label(
                            String(localized: "image.add"),
                            systemImage: "photo"
                        )
                    }
                    
                    if !selectedImages.isEmpty {
                        ImageGridView(
                            images: selectedImages,
                            allowsDeletion: true,
                            
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
            //.navigationTitle(editingPost == nil ? "新しい投稿" : "投稿を編集")
            .navigationTitle(
                editingPost == nil
                    ? String(localized: "editor.newPost")
                    : String(localized: "editor.editPost")
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    //Button("キャンセル")
                    Button(String(localized: "common.cancel")) {
                        cleanupUnusedCachedImages()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    //Button("保存")
                    Button(String(localized: "common.save")) {
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
                        cleanupUnusedCachedImages()
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
    
    private func cleanupUnusedCachedImages() {
        // TODO:
        // cleanupUnusedCachedImages() の動作は
        // デバッグログまたはユニットテストで後日確認する
        //print("cleanup:", image.baseName)
        //print("cached image removed:", sourceURL.absoluteString)
        //print(createdCachedImages.count)

        let used = Set(
            selectedImages.map(\.baseName)
        )

        for image in createdCachedImages {

            guard !used.contains(image.baseName) else {
                continue
            }

            ImageStore.shared.delete(image)

            if let sourceURL = image.sourceURL {
                try? ImageStore.shared.deleteCachedImage(
                    sourceURL: sourceURL.absoluteString
                )
            }
        }
    }
    
    private func detectedURLs(
        in text: String
    ) -> [URL] {

        guard let detector = try? NSDataDetector(
            types: NSTextCheckingResult.CheckingType.link.rawValue
        ) else {
            return []
        }

        let range = NSRange(
            text.startIndex..<text.endIndex,
            in: text
        )

        return detector.matches(
            in: text,
            options: [],
            range: range
        )
        .compactMap(\.url)
    }
    
    private static func normalizedURLKey(_ url: URL) -> String {

        guard var components = URLComponents(
            url: url,
            resolvingAgainstBaseURL: false
        ) else {
            return url.absoluteString
        }

        // scheme, host は小文字へ
        components.scheme = components.scheme?.lowercased()
        components.host = components.host?.lowercased()

        // "/" は空にする
        if components.path == "/" {
            components.path = ""
        }

        // 末尾の ? や & を除去
        var value = components.string ?? url.absoluteString

        while value.hasSuffix("?") || value.hasSuffix("&") {
            value.removeLast()
        }

        return value
    }
    
    private func detectURLs(
        _ urls: [URL]
    ) {

        for url in urls {

            guard
                url.scheme == "http"
                || url.scheme == "https"
            else {
                continue
            }

            //
            // YouTube
            //
            if let videoID = YouTubeHelper.videoID(from: url) {

                guard
                    !importedYouTubeURLs.contains(videoID)
                else {
                    continue
                }

                importedYouTubeURLs.insert(videoID)

                Task {

                    do {

                        let image =
                            try await ImageStore.shared
                                .importYoutubeThumbnail(
                                    from: url
                                )

                        await MainActor.run {
                            selectedImages.insert(
                                image,
                                at: 0
                            )
                        }

                    } catch {

                        print(
                            "YouTubeサムネイル取得失敗。OGP画像を試します:",
                            error
                        )

                        do {
                            let alreadyCached =
                                ImageStore.shared.hasCachedImage(
                                    sourceURL: url
                                )

                            let image =
                                try await ImageStore.shared
                                    .importLinkPreview(
                                        from: url,
                                        date: Date()
                                    )

                            await MainActor.run {

                                if !alreadyCached {
                                    createdCachedImages.append(image)
                                }

                                selectedImages.append(image)
                            }
                            /*
                            let image =
                                try await ImageStore.shared
                                    .importLinkPreview(
                                        from: url,
                                        date: Date()
                                    )

                            await MainActor.run {
                                selectedImages.insert(
                                    image,
                                    at: 0
                                )
                            }
                             */
                        } catch {

                            print(
                                "YouTube OGP画像取得失敗:",
                                url.absoluteString,
                                error.localizedDescription
                            )

                        }
                    }
                }

                continue
            }

            //
            // 通常リンク
            //
            let key = Self.normalizedURLKey(url)

            guard
                !importedLinkURLs.contains(key)
            else {
                continue
            }

            importedLinkURLs.insert(key)

            Task {

                do {

                    let image =
                        try await ImageStore.shared
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

                }
            }
        }
    }
    
/* この関数はコメントのまま残しておく
    private func detectYouTubeURLs(
        _ urls: [URL]
    ) {

        for url in urls {

            guard
                url.scheme == "http"
                || url.scheme == "https"
            else {
                continue
            }

            guard
                let videoID = YouTubeHelper.videoID(from: url)
            else {
                continue
            }

            guard
                !importedYouTubeURLs.contains(videoID)
            else {
                continue
            }

            importedYouTubeURLs.insert(videoID)

            Task {
                do {
                    let image = try await ImageStore.shared
                        .importYoutubeThumbnail(
                            from: url
                        )

                    await MainActor.run {
                        selectedImages.insert(image, at: 0)
                    }

                } catch {

                    print(
                        "YouTubeサムネイル取得失敗。OGP画像を試します:",
                        error
                    )

                    do {

                        let image = try await ImageStore.shared
                            .importLinkPreview(
                                from: url,
                                date: Date()
                            )

                        await MainActor.run {
                            selectedImages.insert(
                                image,
                                at: 0
                            )
                        }

                    } catch {

                        print(
                            "YouTube OGP画像取得失敗:",
                            url.absoluteString,
                            error.localizedDescription
                        )

                    }
                }
            }
        }
    }
 
    //  この関数はコメントのまま残しておく
    private func detectLinkPreviews(
        _ urls: [URL]
    ) {
        for url in urls {

            guard
                url.scheme == "http"
                || url.scheme == "https"
            else {
                continue
            }
            // YouTube は detectYouTubeURL() が処理する。
            // サムネイル取得に失敗した場合は、
            // detectYouTubeURL() 内でOGP画像へフォールバックする。
            if YouTubeHelper.videoID(from: url) != nil {
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

                }
            }
        }
    }
*/
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
