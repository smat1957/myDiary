//
//  ImageViewerView.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/07.
//

import SwiftUI
import AppKit

struct ImageViewerView: View {

    let state: ImageViewerState

    /*
     削除時は、現在の並びを反映した投稿と
     削除対象画像を渡す。
     */
    let onDelete: (
        DiaryPost,
        DiaryImage
    ) -> Void

    /*
     画像順を変更した投稿をDBへ保存する。
     */
    let onUpdateImageOrder:
        (DiaryPost) -> Void

    @Environment(\.dismiss)
    private var dismiss

    @State private var currentNSImage:
        NSImage?

    @State private var zoomScale:
        CGFloat = 1.0

    @State private var showingDeleteAlert =
        false

    var body: some View {
        VStack(spacing: 0) {

            toolbar

            Divider()

            if let currentNSImage {
                imageArea(
                    currentNSImage
                )

            } else {
                ContentUnavailableView(
                    "画像を読み込めません",
                    systemImage: "photo"
                )
            }
        }
        .frame(
            minWidth: 800,
            minHeight: 600
        )
        .onMoveCommand { direction in
            switch direction {

            case .left:
                showPrevious()

            case .right:
                showNext()

            default:
                break
            }
        }
        .onAppear {
            loadCurrentImage()
        }
        .onChange(
            of: state.imageIndex
        ) {
            loadCurrentImage()
        }
        .onChange(
            of: state.viewerImageKind
        ) {
            zoomScale = 1.0
            loadCurrentImage()
        }
        .alert(
            "この画像を削除しますか？",
            isPresented:
                $showingDeleteAlert
        ) {
            Button(
                "キャンセル",
                role: .cancel
            ) {
            }

            Button(
                "削除",
                role: .destructive
            ) {
                deleteCurrentImage()
            }

        } message: {
            Text(
                "この投稿から画像を削除します。"
            )
        }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: 10) {

            // 先頭画像
            Button("≪") {
                showFirst()
            }
            .disabled(
                !state.hasPrevious
            )
            .help("先頭の画像")

            // 前の画像
            Button {
                showPrevious()
            } label: {
                Image(
                    systemName:
                        "chevron.left"
                )
            }
            .disabled(
                !state.hasPrevious
            )
            .help("前の画像")

            // 現在位置
            Text(
                state.imageNumberText
            )
            .monospacedDigit()
            .foregroundStyle(
                .secondary
            )
            .frame(
                minWidth: 48
            )

            // 次の画像
            Button {
                showNext()
            } label: {
                Image(
                    systemName:
                        "chevron.right"
                )
            }
            .disabled(
                !state.hasNext
            )
            .help("次の画像")

            // 最後の画像
            Button("≫") {
                showLast()
            }
            .disabled(
                !state.hasNext
            )
            .help("最後の画像")

            Divider()
                .frame(height: 22)

            /*
             Display / Original
             プルダウンメニュー
             */
            Picker(
                "表示画像",
                selection:
                    Bindable(state)
                        .viewerImageKind
            ) {
                ForEach(
                    ViewerImageKind
                        .allCases
                ) { kind in
                    Text(kind.rawValue)
                        .tag(kind)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .frame(width: 110)
            .help(
                "Display画像またはOriginal画像を表示"
            )

            Spacer()

            // 縮小
            Button {
                zoomOut()
            } label: {
                Image(
                    systemName: "minus"
                )
            }
            .help("縮小")

            // Fit
            Button("Fit") {
                fitImage()
            }
            .help(
                "ウインドウに合わせる"
            )

            // 拡大
            Button {
                zoomIn()
            } label: {
                Image(
                    systemName: "plus"
                )
            }
            .help("拡大")

            Spacer()

            // Finder
            Button("Finder") {
                revealCurrentImageInFinder()
            }
            .help(
                "Finderで表示"
            )

            // 削除
            Button(
                "削除",
                role: .destructive
            ) {
                showingDeleteAlert = true
            }
            .help("画像を削除")

            // 閉じる
            Button("閉じる") {
                dismiss()
            }
            .keyboardShortcut(
                .cancelAction
            )
        }
        .padding()
    }

    // MARK: - Image area

    private func imageArea(
        _ nsImage: NSImage
    ) -> some View {

        GeometryReader { geometry in

            let width =
                geometry.size.width

            let height =
                geometry.size.height

            ScrollView(
                [.horizontal, .vertical]
            ) {
                ZStack(
                    alignment: .topLeading
                ) {
                    Image(
                        nsImage: nsImage
                    )
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width:
                            width
                            * zoomScale,
                        height:
                            height
                            * zoomScale
                    )
                    .padding(40)
                    .contextMenu {
                        imageContextMenu
                    }

                    sourceButton
                        .padding(52)
                }
            }
            .frame(
                width: width,
                height: height
            )
        }
    }

    // MARK: - Context menu

    @ViewBuilder
    private var imageContextMenu:
        some View
    {
        Button("前へ移動") {
            moveCurrentImageBackward()
        }
        .disabled(
            !state.canMoveBackward
        )

        Button("後ろへ移動") {
            moveCurrentImageForward()
        }
        .disabled(
            !state.canMoveForward
        )

        Divider()

        Button("Finderで表示") {
            revealCurrentImageInFinder()
        }

        Divider()

        Button(
            "削除",
            role: .destructive
        ) {
            showingDeleteAlert = true
        }
    }

    // MARK: - Source button

    @ViewBuilder
    private var sourceButton:
        some View
    {
        switch state.image.sourceType {

        case .youtube:
            Button {
                if let url =
                    state.image.sourceURL
                {
                    NSWorkspace.shared.open(
                        url
                    )
                }
            } label: {
                Image(
                    systemName:
                        "play.circle.fill"
                )
                .font(
                    .system(size: 36)
                )
                .foregroundStyle(.white)
                .shadow(radius: 3)
            }
            .buttonStyle(.plain)

        case .link:
            Button {
                if let url =
                    state.image.sourceURL
                {
                    NSWorkspace.shared.open(
                        url
                    )
                }
            } label: {
                Image(
                    systemName: "globe"
                )
                .font(
                    .system(size: 32)
                )
                .foregroundStyle(.white)
                .shadow(radius: 3)
            }
            .buttonStyle(.plain)

        case .photo, .generated:
            EmptyView()
        }
    }

    // MARK: - Image loading

    private func loadCurrentImage() {
        guard state.hasImages else {
            currentNSImage = nil
            return
        }

        currentNSImage = NSImage(
            contentsOf:
                state.currentURL
        )
    }

    // MARK: - Navigation

    private func showFirst() {
        state.showFirst()
        zoomScale = 1.0
    }

    private func showPrevious() {
        state.showPrevious()
        zoomScale = 1.0
    }

    private func showNext() {
        state.showNext()
        zoomScale = 1.0
    }

    private func showLast() {
        state.showLast()
        zoomScale = 1.0
    }

    // MARK: - Zoom

    private func zoomOut() {
        zoomScale = max(
            0.25,
            zoomScale - 0.25
        )
    }

    private func fitImage() {
        zoomScale = 1.0
    }

    private func zoomIn() {
        zoomScale = min(
            8.0,
            zoomScale + 0.25
        )
    }

    // MARK: - Finder

    private func revealCurrentImageInFinder() {
        guard state.hasImages else {
            return
        }

        NSWorkspace.shared
            .activateFileViewerSelecting(
                [state.currentURL]
            )
    }

    // MARK: - Delete

    private func deleteCurrentImage() {
        guard state.hasImages else {
            return
        }

        let deletedImage =
            state.image

        /*
         DBと画像ファイルを削除する。
         削除前の現在配列を反映した投稿を渡す。
         */
        onDelete(
            state.currentPost,
            deletedImage
        )

        /*
         Viewer内の画像配列から削除する。
         */
        state.removeCurrentImage()

        /*
         画像がすべてなくなった時だけ
         Viewerを閉じる。
         */
        guard state.hasImages else {
            dismiss()
            return
        }

        zoomScale = 1.0
        loadCurrentImage()
    }

    // MARK: - Ordering

    private func moveCurrentImageBackward() {
        guard state.canMoveBackward else {
            return
        }

        state.moveCurrentImageBackward()

        onUpdateImageOrder(
            state.currentPost
        )

        zoomScale = 1.0
        loadCurrentImage()
    }

    private func moveCurrentImageForward() {
        guard state.canMoveForward else {
            return
        }

        state.moveCurrentImageForward()

        onUpdateImageOrder(
            state.currentPost
        )

        zoomScale = 1.0
        loadCurrentImage()
    }
}
