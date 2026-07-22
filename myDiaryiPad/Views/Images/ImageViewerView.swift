//
//  ImageViewerView.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/20.
//

import SwiftUI
import UIKit

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

    @State private var currentUIImage:
        UIImage?

    @State
    private var pageState =
        ViewerPageState()

    @State private var showingDeleteAlert =
        false

    @State private var dragOffset:
        CGFloat = 0

    @State private var isPaging =
        false

    var body: some View {
        VStack(spacing: 0) {

            toolbar

            Divider()

            if let currentUIImage {
                imageArea(
                    currentUIImage
                )

            } else {
                ContentUnavailableView(
                    //"画像を読み込めません",
                    String(localized: "image.cannotLoad"),
                    systemImage: "photo"
                )
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
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
            pageState.fit()
            loadCurrentImage()
        }
        .alert(
            //"この画像を削除しますか？",
            String(localized: "image.delete.confirm.title"),
            isPresented:
                $showingDeleteAlert
        ) {
            Button(
                //"キャンセル",
                String(localized: "common.cancel"),
                role: .cancel
            ) {
            }

            Button(
                //"削除",
                String(localized: "common.delete"),
                role: .destructive
            ) {
                deleteCurrentImage()
            }

        } message: {
            Text(
                String(localized: "image.delete.confirm.message")
                //"この投稿から画像を削除します。"
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
            .help(String(localized: "viewer.first.help"))
            //.help("先頭の画像")

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
            .help(String(localized: "viewer.previous.help"))
            //.help("前の画像")

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
            .help(String(localized: "viewer.next.help"))
            //.help("次の画像")

            // 最後の画像
            Button("≫") {
                showLast()
            }
            .disabled(
                !state.hasNext
            )
            .help(String(localized: "viewer.last.help"))
            //.help("最後の画像")

            Divider()
                .frame(height: 22)

            Picker(
                String(localized: "viewer.imageKind"),
                selection: Bindable(state).viewerImageKind
            ) {
                ForEach(ViewerImageKind.allCases) { kind in
                    Text(kind.localizedName)
                        .tag(kind)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .frame(width: 110)
            .help(
                String(localized: "viewer.imageKind.help")
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
            .help(String(localized: "viewer.zoomOut"))
            //.help("縮小")

            // Fit
            Button("Fit") {
                fitImage()
            }
            .help(
                String(localized: "viewer.fit.help")
                //"ウインドウに合わせる"
            )

            // 拡大
            Button {
                zoomIn()
            } label: {
                Image(
                    systemName: "plus"
                )
            }
            .help(String(localized: "viewer.zoomIn"))
            //.help("拡大")

            Spacer()

            // Finder
            Button("Finder") {
                revealCurrentImageInFinder()
            }
            .help(String(localized: "viewer.finder.help"))
            //.help("Finderで表示")

            // 削除
            Button(
                String(localized: "common.delete"),
                //"削除",
                role: .destructive
            ) {
                showingDeleteAlert = true
            }
            .help(String(localized: "image.delete.help"))
            //.help("画像を削除")

            // 閉じる
            //Button("閉じる") {
            Button(String(localized: "common.close")) {
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
        _ uiImage: UIImage
    ) -> some View {

        GeometryReader { geometry in

            let width = geometry.size.width
            let height = geometry.size.height

            ZStack {

                /*
                 前の画像
                 */
                if dragOffset > 0,
                   state.hasPrevious,
                   let previousImage = loadImage(
                       at: state.imageIndex - 1
                   ) {

                    ViewerPage(
                        image: previousImage,
                        pageWidth: width,
                        pageHeight: height,
                        state: pageState
                    )
                    .offset(
                        x: -width + dragOffset
                    )
                    /*
                     隣のプレビュー画像では
                     ズーム操作を受け付けない。
                     */
                    .allowsHitTesting(false)
                }

                /*
                 次の画像
                 */
                if dragOffset < 0,
                   state.hasNext,
                   let nextImage = loadImage(
                       at: state.imageIndex + 1
                   ) {

                    ViewerPage(
                        image: nextImage,
                        pageWidth: width,
                        pageHeight: height,
                        state: pageState
                    )
                    .offset(
                        x: width + dragOffset
                    )
                    .allowsHitTesting(false)
                }

                /*
                 現在画像
                 */
                ZStack(
                    alignment: .topLeading
                ) {

                    ViewerPage(
                        image: uiImage,
                        pageWidth: width,
                        pageHeight: height,
                        state: pageState
                    )
                    .contextMenu {
                        imageContextMenu
                    }

                    sourceButton
                        .padding(52)
                }
                .offset(
                    x: dragOffset
                )
            }
            .frame(
                width: width,
                height: height
            )
            .contentShape(Rectangle())
            .simultaneousGesture(
                imageSwipeGesture(
                    pageWidth: width
                )
            )
            .clipped()
        }
    }
    
    private func loadImage(
        at index: Int
    ) -> UIImage? {

        guard state.images.indices.contains(index)
        else {
            return nil
        }

        let image = state.images[index]

        let url: URL

        switch state.viewerImageKind {

        case .display:
            url = ImageStore.shared.url(
                for: image,
                kind: .display
            )

        case .original:
            url = ImageStore.shared.url(
                for: image,
                kind: .original
            )
        }

        return UIImage(
            contentsOfFile: url.path
        )
    }
    
    // MARK: - Context menu

    @ViewBuilder
    private var imageContextMenu:
        some View
    {
        //Button("前へ移動") {
        Button(String(localized: "image.moveBackward")) {
            moveCurrentImageBackward()
        }
        .disabled(
            !state.canMoveBackward
        )

        //Button("後ろへ移動") {
        Button(String(localized: "image.moveForward")) {
            moveCurrentImageForward()
        }
        .disabled(
            !state.canMoveForward
        )

        Divider()

        //Button("Finderで表示") {
        Button(String(localized: "viewer.finder")) {
            revealCurrentImageInFinder()
        }

        Divider()

        Button(
            //"削除",
            String(localized: "common.delete"),
            role: .destructive
        ) {
            showingDeleteAlert = true
        }
    }

    // MARK: - Source button

    @ViewBuilder
    private var sourceButton: some View {
        if state.hasImages {
            switch state.image.sourceType {

            case .youtube:
                Button {
                    if let url = state.image.sourceURL {
                        UIApplication.shared.open(url)
                        //NSWorkspace.shared.open(url)
                    }
                } label: {
                    Image(
                        systemName: "play.circle.fill"
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
                    if let url = state.image.sourceURL {
                        UIApplication.shared.open(url)
                        //NSWorkspace.shared.open(url)
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
        } else {
            EmptyView()
        }
    }
    
    // MARK: - Image loading

    private func loadCurrentImage() {
        guard state.hasImages else {
            currentUIImage = nil
            return
        }

        currentUIImage = UIImage(
            contentsOfFile:
                state.currentURL.path
        )
    }

    // MARK: - Navigation

    private func showFirst() {
        pageState.fit()
        state.showFirst()
    }

    private func showPrevious() {
        pageState.fit()
        state.showPrevious()
    }

    private func showNext() {
        pageState.fit()
        state.showNext()
    }

    private func showLast() {
        pageState.fit()
        state.showLast()
    }

    // MARK: - Zoom

    private func zoomOut() {
        pageState.zoomOut()
    }

    private func fitImage() {
        withAnimation(
            .easeInOut(duration: 0.2)
        ) {
            pageState.fit()
        }
    }

    private func zoomIn() {
        pageState.zoomIn()
    }
    
    // MARK: - Finder

    private func revealCurrentImageInFinder() {
        guard state.hasImages else {
            return
        }
        /*
        NSWorkspace.shared
            .activateFileViewerSelecting(
                [state.currentURL]
            )
         */
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

        pageState.fit()
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

        pageState.fit()
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

        pageState.fit()
        loadCurrentImage()
    }
    
    // MARK: - Swipe gesture

    private func imageSwipeGesture(
        pageWidth: CGFloat
    ) -> some Gesture {

        DragGesture(
            minimumDistance: 10
        )
        .onChanged { value in

            guard !isPaging else {
                return
            }

            /*
             拡大中は画像内の移動を優先する。
             */
            guard pageState.zoomScale <= 1.01 else {
                return
            }
            
            let dx = value.translation.width
            let dy = value.translation.height

            /*
             横方向のドラッグだけを扱う。
             */
            guard abs(dx) > abs(dy) else {
                return
            }

            /*
             最初または最後の画像を越えて
             ドラッグした場合は抵抗を付ける。
             */
            if dx > 0,
               !state.hasPrevious {

                dragOffset = dx * 0.2

            } else if dx < 0,
                      !state.hasNext {

                dragOffset = dx * 0.2

            } else {
                dragOffset = dx
            }
        }
        .onEnded { value in

            guard !isPaging else {
                return
            }

            guard pageState.zoomScale <= 1.01 else {
                return
            }
            
            let dx = value.translation.width
            let dy = value.translation.height

            guard abs(dx) > abs(dy) else {
                returnToCurrentPage()
                return
            }

            let threshold = min(
                120,
                pageWidth * 0.2
            )

            if dx < -threshold,
               state.hasNext {

                completePageMove(
                    direction: .next,
                    pageWidth: pageWidth
                )

            } else if dx > threshold,
                      state.hasPrevious {

                completePageMove(
                    direction: .previous,
                    pageWidth: pageWidth
                )

            } else {
                returnToCurrentPage()
            }
        }
    }
    
    private enum PageMoveDirection {
        case previous
        case next
    }

    private func completePageMove(
        direction: PageMoveDirection,
        pageWidth: CGFloat
    ) {
        isPaging = true

        let destination: CGFloat

        switch direction {
        case .previous:
            destination = pageWidth

        case .next:
            destination = -pageWidth
        }

        withAnimation(
            .easeOut(duration: 0.22)
        ) {
            dragOffset = destination
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.22
        ) {
            switch direction {
            case .previous:
                state.showPrevious()

            case .next:
                state.showNext()
            }

            /*
             アニメーションなしで新しい画像を
             画面中央へ配置し直す。
             */
            var transaction = Transaction()
            transaction.disablesAnimations = true

            withTransaction(transaction) {
                dragOffset = 0
            }

            pageState.fit()
            isPaging = false
        }
    }

    private func returnToCurrentPage() {
        withAnimation(
            .easeOut(duration: 0.18)
        ) {
            dragOffset = 0
        }
    }
    
}
