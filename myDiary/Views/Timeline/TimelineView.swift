//
//  TimelineView.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/06.
//

import SwiftUI
import AppKit

struct TimelineView: View {
    
    let posts: [DiaryPost]
    let postDictionary: [Int64: DiaryPost]
    let currentPostID: Int64?
    let focusedPostID: Int64?
    let onClearFocusedPost: () -> Void

    let onDeleteImage: (DiaryPost, DiaryImage) -> Void
    let onDeletePost: (DiaryPost) -> Void
    let onEditPost: (DiaryPost) -> Void
    let onCreateLink: (DiaryPost, DiaryPost) -> Void

    let onOpenLinkedPost: (Int64, Int64) -> Void
    let onDeleteLink: (DiaryPost, Int64) -> Void
    let onMoveLink: (DiaryPost, Int, Int) -> Void
    let backlinkDictionary: [Int64: [DiaryPost]]
    let onLinkComment: (
        DiaryPost,
        DiaryPost
    ) -> Void
    let onUnlinkComment: (DiaryPost) -> Void
    let onReplyPost: (DiaryPost) -> Void
        
    @State private var viewerState: ImageViewerState?
    @State private var pendingDeletePost: DiaryPost?
    @State private var linkSourcePost: DiaryPost?
    @State private var commentToLink: DiaryPost?
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(
                        posts.filter { $0.parentPostId == nil }
                    ) { post in
                        
                        PostCardView(
                            post: post,
                            posts: posts,

                            postDictionary: postDictionary,
                            backlinks: backlinkDictionary[post.id] ?? [],

                            onDeleteImage: onDeleteImage,

                            onDeletePost: { post in
                                pendingDeletePost = post
                            },

                            onTapImage: { image in
                                openImage(image, in: post)
                            },

                            onOpenSource: { image in
                                openSource(image)
                            },

                            onOpenViewer: { post in
                                openViewer(for: post)
                            },
                            
                            onLinkPost: { post in
                                //print(
                                //    "TimelineView onLinkPost:",
                                //    post.id
                                //)

                                linkSourcePost = post
                            },
                            
                            onEditPost: onEditPost,

                            onOpenLinkedPost: { targetPostID in
                                onOpenLinkedPost(
                                    targetPostID,
                                    post.id
                                )
                            },
                            
                            onDeleteLink: { targetPostID in
                                onDeleteLink(
                                    post,
                                    targetPostID
                                )
                            },

                            onMoveLink: { sourceIndex, destinationIndex in
                                onMoveLink(
                                    post,
                                    sourceIndex,
                                    destinationIndex
                                )
                            },
                            
                            onLinkComment: { comment in
                                commentToLink = comment
                            },
                            onUnlinkComment: { comment in
                                onUnlinkComment(comment)
                            },
                            
                            onReplyPost: { post in
                                onReplyPost(post)
                            }

                        )
                        .id(post.id)
                    }
                }
                .padding()
            }
            .onChange(
                of: currentPostID
            ) { _, newID in

                scrollTo(
                    newID,
                    anchor: .top,
                    animated: true,
                    proxy: proxy
                )
            }
            .onChange(
                of: focusedPostID
            ) { _, focusedID in

                guard focusedID != nil else {
                    return
                }

                /*
                 親投稿の表示更新とコメントViewの生成が
                 終わった後にスクロールする。
                 */
                DispatchQueue.main.async {
                    scrollTo(
                        focusedID,
                        anchor: .center,
                        animated: true,
                        proxy: proxy
                    )

                    /*
                     focusedPostIDを消して、
                     同じ対象へ何度もスクロールしないようにする。
                     */
                    onClearFocusedPost()
                }
            }
            .onAppear {
                scrollTo(
                    currentPostID,
                    anchor: .top,
                    animated: false,
                    proxy: proxy
                )
            }
        }
        .sheet(item: $viewerState) { state in
            ImageViewerView(
                state: state,
                onDelete: { image in
                    onDeleteImage(state.post, image)
                }
            )
        }
        .alert(
            "この投稿を削除しますか？",
            isPresented: Binding(
                get: { pendingDeletePost != nil },
                set: {
                    if !$0 {
                        pendingDeletePost = nil
                    }
                }
            )
        ) {
            Button("キャンセル", role: .cancel) {
                pendingDeletePost = nil
            }

            Button("削除", role: .destructive) {
                if let post = pendingDeletePost {
                    onDeletePost(post)
                }

                pendingDeletePost = nil
            }
        } message: {
            Text("この投稿と添付画像を削除します。")
        }
        .sheet(item: $linkSourcePost) { sourcePost in
            PostLinkPickerView(
                posts: posts,
                sourcePost: sourcePost,
                onSelect: { targetPost in
                    onCreateLink(
                        sourcePost,
                        targetPost
                    )
                }
            )
        }
        .sheet(item: $commentToLink) { comment in
            ParentPostPickerView(
                comment: comment,
                posts: posts,
                onSelect: { parent in
                    onLinkComment(
                        comment,
                        parent
                    )
                }
            )
        }
    }

    private func scrollTo(
        _ id: Int64?,
        anchor: UnitPoint,
        animated: Bool,
        proxy: ScrollViewProxy
    ) {
        guard let id else {
            return
        }

        let operation = {
            proxy.scrollTo(
                id,
                anchor: anchor
            )
        }

        if animated {
            withAnimation {
                operation()
            }
        } else {
            operation()
        }
    }

    private func openImage(
        _ image: DiaryImage,
        in post: DiaryPost
    ) {
        if let index = post.images.firstIndex(where: {
            $0.baseName == image.baseName
        }) {
            viewerState = ImageViewerState(
                post: post,
                imageIndex: index
            )
        }
    }

    private func openViewer(for post: DiaryPost) {
        guard !post.images.isEmpty else {
            return
        }

        viewerState = ImageViewerState(
            post: post,
            imageIndex: 0
        )
    }

    private func openSource(_ image: DiaryImage) {
        guard let url = image.sourceURL else {
            return
        }

        NSWorkspace.shared.open(url)
    }
}
