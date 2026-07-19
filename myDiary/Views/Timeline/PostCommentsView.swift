//
//  PostCommentsView.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/14.
//
//
//  PostCommentsView.swift
//  myDiary
//

import SwiftUI

struct PostCommentsView: View {

    let parentPost: DiaryPost
    let posts: [DiaryPost]
    
    let onEditPost: (DiaryPost) -> Void
    let onOpenViewer: (DiaryPost) -> Void
    let onLinkPost: (DiaryPost) -> Void
    
    let onUnlinkComment: (DiaryPost) -> Void
    
    let onReplyPost: (DiaryPost) -> Void

    let onTapImage: (
        DiaryPost,
        DiaryImage
    ) -> Void

    let onDeleteImage: (
        DiaryPost,
        DiaryImage
    ) -> Void

    let onOpenSource: (
        DiaryImage
    ) -> Void

    private let depth: Int

    init(
        parentPost: DiaryPost,
        posts: [DiaryPost],
        onEditPost: @escaping (DiaryPost) -> Void,
        onOpenViewer: @escaping (DiaryPost) -> Void,
        onLinkPost: @escaping (DiaryPost) -> Void,
        depth: Int = 0,
        onUnlinkComment: @escaping (
            DiaryPost
        ) -> Void,
        onTapImage: @escaping (
            DiaryPost,
            DiaryImage
        ) -> Void,
        onDeleteImage: @escaping (
            DiaryPost,
            DiaryImage
        ) -> Void,
        onOpenSource: @escaping (
            DiaryImage
        ) -> Void,
        onReplyPost: @escaping (DiaryPost) -> Void
    ) {
        self.parentPost = parentPost
        self.posts = posts
        
        self.onEditPost = onEditPost
        self.onOpenViewer = onOpenViewer
        self.onLinkPost = onLinkPost
        
        self.depth = depth

        self.onUnlinkComment =
            onUnlinkComment

        self.onTapImage =
            onTapImage

        self.onDeleteImage =
            onDeleteImage

        self.onOpenSource =
            onOpenSource
        
        self.onReplyPost = onReplyPost
    }

    // MARK: - Children

    private var comments: [DiaryPost] {

        posts
            .filter {
                $0.parentPostId
                    == parentPost.id
            }
            .sorted {
                if $0.diaryDate != $1.diaryDate {
                    return
                        $0.diaryDate
                        < $1.diaryDate
                }

                return $0.id < $1.id
            }
    }

    // MARK: - Layout

    private var effectiveDepth: Int {
        min(
            depth,
            4
        )
    }

    private var indentation: CGFloat {
        CGFloat(effectiveDepth) * 24
    }

    private var bodyFontSize: CGFloat {
        max(
            12,
            15
                - CGFloat(depth)
        )
    }

    private var headerFontSize: CGFloat {
        max(
            10,
            12
                - CGFloat(depth) * 0.5
        )
    }

    private var imageScale: CGFloat {
        max(
            0.55,
            0.9
                - CGFloat(depth) * 0.1
        )
    }

    private var cardPadding: CGFloat {
        max(
            8,
            12
                - CGFloat(depth)
        )
    }

    private var backgroundOpacity: Double {
        max(
            0.04,
            0.08
                - Double(effectiveDepth)
                    * 0.01
        )
    }

    // MARK: - Body

    var body: some View {

        if !comments.isEmpty {

            VStack(
                alignment: .leading,
                spacing: 10
            ) {

                if depth == 0 {

                    Divider()

                    HStack(spacing: 6) {

                        Image(
                            systemName:
                                "bubble.left.and.bubble.right"
                        )

                        Text(
                            String(
                                    localized: "comments.title",
                                    defaultValue: "Comments \(comments.count)"
                                )
                            //"コメント \(comments.count)件"
                        )
                        .font(.headline)
                    }
                    .foregroundStyle(
                        .secondary
                    )
                }

                ForEach(
                    comments,
                    id: \DiaryPost.id
                ) { (comment: DiaryPost) in

                    VStack(
                        alignment: .leading,
                        spacing: 6
                    ) {

                        commentView(comment)

                        PostCommentsView(
                            parentPost: comment,
                            posts: posts,
                            onEditPost: onEditPost,
                            onOpenViewer: onOpenViewer,
                            onLinkPost: onLinkPost,
                            depth: depth + 1,

                            onUnlinkComment: onUnlinkComment,
                            onTapImage: onTapImage,
                            onDeleteImage: onDeleteImage,
                            onOpenSource: onOpenSource,
                            onReplyPost: onReplyPost
                        )
                    }
                    .id(comment.id)
                    .padding(
                        .leading,
                        indentation
                    )
                }
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
        }
    }

    // MARK: - Comment

    @ViewBuilder
    private func commentView(
        _ comment: DiaryPost
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            HStack {
                Image(
                    systemName:
                        "arrowshape.turn.up.left"
                )
                .foregroundStyle(.secondary)

                Text(
                    comment.diaryDate.formatted(
                        date: .abbreviated,
                        time: .shortened
                    )
                )
                .font(.system(size: headerFontSize))
                .foregroundStyle(.secondary)

                Spacer()

                if comment.packagePostID != nil {
                    //Text("Facebook")
                    Text(String(localized: "facebook.imported"))
                        .font( .system(
                            size: headerFontSize - 1
                        ))
                        .foregroundStyle(.tertiary)
                }
                
                Button {
                    onReplyPost(comment)
                } label: {
                    Image(
                        systemName: "arrowshape.turn.up.left"
                    )
                }
                .buttonStyle(.plain)
                .help(String(localized: "post.reply.help"))
                //.help("返信")
                
                // 画像一覧
                if !comment.images.isEmpty {
                    Button {
                        onOpenViewer(comment)
                    } label: {
                        Image(
                            systemName:
                                "photo.on.rectangle"
                        )
                    }
                    .buttonStyle(.plain)
                    .help(String(localized: "viewer.open.help"))
                    //.help("画像一覧を開く")
                }

                // 関連記事
                Button {
                    onLinkPost(comment)
                } label: {
                    Image(
                        systemName: "link"
                    )
                }
                .buttonStyle(.plain)
                .help(String(localized: "post.addRelated.help"))
                //.help("関連記事を追加")

                // 編集
                Button {
                    onEditPost(comment)
                } label: {
                    Image(
                        systemName: "pencil"
                    )
                }
                .buttonStyle(.plain)
                .help(String(localized: "comment.edit.help"))
                //.help("コメントを編集")

                // 親投稿との紐付け解除
                Button {
                    onUnlinkComment(comment)
                } label: {
                    Image(systemName: "minus.circle")
                    //Image(
                    //    systemName:
                    //        "link.badge.minus"
                    //)
                }
                .buttonStyle(.plain)
                .help(String(localized: "comment.unlink.help"))
                //.help("親投稿との紐付けを解除")
            }

            if !comment.body
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )
                .isEmpty
            {
                Text(
                    comment.body
                )
                .font(
                    .system(
                        size: bodyFontSize
                    )
                )
                .textSelection(.enabled)
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
            }

            if !comment.images.isEmpty {

                ImageGridView(
                    images: comment.images,
                    scale: imageScale,
                    onTapImage: { image in
                        onTapImage(
                            comment,
                            image
                        )
                    },
                    onDelete: { image in
                        onDeleteImage(
                            comment,
                            image
                        )
                    },
                    onOpenSource: { image in
                        onOpenSource(
                            image
                        )
                    }
                )
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
                .clipped()
            }
        }
        .padding(
            cardPadding
        )
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            Color.secondary.opacity(
                backgroundOpacity
            )
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 10
            )
        )
    }
}

