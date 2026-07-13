//
//  ImageViewerView.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/07.
//

import SwiftUI
import AppKit

struct ImageViewerView: View {
    
    @State private var currentNSImage: NSImage?
    let state: ImageViewerState
    let onDelete: (DiaryImage) -> Void

    @Environment(\.dismiss)
    private var dismiss

    @State private var zoomScale: CGFloat = 1.0
    @State private var showingDeleteAlert = false

    var body: some View {
        VStack {
            toolbar
            
            if let nsImage = currentNSImage {
                imageArea(nsImage)
            } else {
                Text("画像を読み込めません")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(minWidth: 800, minHeight: 600)
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
        .onChange(of: state.imageIndex) {
            loadCurrentImage()
        }
        .onChange(of: state.viewerImageKind) {
            loadCurrentImage()
        }
        .alert("この画像を削除しますか？", isPresented: $showingDeleteAlert) {
            Button("キャンセル", role: .cancel) {}

            Button("削除", role: .destructive) {
                onDelete(state.image)
                dismiss()
            }
        } message: {
            Text("この投稿から画像を削除します。")
        }
    }
    
    private func loadCurrentImage() {
        currentNSImage = NSImage(contentsOf: state.currentURL)
    }
    
    private func showFirst() {
        state.showFirst()
        zoomScale = 1.0
    }

    private func showLast() {
        state.showLast()
        zoomScale = 1.0
    }
    
    private var toolbar: some View {
        HStack {
            Button {
                showPrevious()
            } label: {
                Image(systemName: "chevron.left")
            }
            .disabled(!state.hasPrevious)

            Button {
                showNext()
            } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(!state.hasNext)

            Button("Fit/200%") {
                zoomScale = (zoomScale == 1.0) ? 2.0 : 1.0
            }

            Text(state.viewerImageKind == .display ? "Display" : "Original")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button(state.viewerImageKind == .display ? "Original" : "Display") {
                state.viewerImageKind =
                    (state.viewerImageKind == .display) ? .original : .display

                zoomScale = 1.0
            }
            
            Button("Finder") {
                NSWorkspace.shared.activateFileViewerSelecting([
                    state.currentURL
                ])
            }
            
            Text(state.imageNumberText)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Button("－") {
                zoomScale = max(0.25, zoomScale - 0.25)
            }

            Button("Fit") {
                zoomScale = 1.0
            }

            Button("＋") {
                zoomScale += 0.25
            }

            Text(zoomScale == 1.0 ? "Fit" : "\(Int(zoomScale * 100))%")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(state.displayImageSizeText)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Button("削除") {
                showingDeleteAlert = true
            }

            Button("閉じる") {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)
        }
        .padding()
    }

    private func imageArea(_ nsImage: NSImage) -> some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height

            ScrollView([.horizontal, .vertical]) {
                ZStack(alignment: .topLeading) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: width * zoomScale,
                            height: height * zoomScale
                        )
                        .padding(40)

                    sourceButton
                        .padding(52)
                }
            }
            .frame(width: width, height: height)
        }
    }
    
    @ViewBuilder
    private var sourceButton: some View {
        switch state.image.sourceType {

        case .youtube:
            Button {
                if let url = state.image.sourceURL {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.white)
                    .shadow(radius: 3)
            }
            .buttonStyle(.plain)

        case .link:
            Button {
                if let url = state.image.sourceURL {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                Image(systemName: "globe")
                    .font(.system(size: 32))
                    .foregroundStyle(.white)
                    .shadow(radius: 3)
            }
            .buttonStyle(.plain)

        case .photo, .generated:
            EmptyView()
        }
    }
    
    private func showPrevious() {
        state.showPrevious()
        zoomScale = 1.0
    }

    private func showNext() {
        state.showNext()
        zoomScale = 1.0
    }
}
