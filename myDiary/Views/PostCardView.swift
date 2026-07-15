//
//  PostCardView.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/06.
//

import SwiftUI

struct PostCardView: View {
    
    let post: DiaryPost
    //let comments: [DiaryPost]
    let posts: [DiaryPost]
    let postDictionary: [Int64: DiaryPost]
    let backlinks: [DiaryPost]

    let onDeleteImage: (DiaryPost, DiaryImage) -> Void
    let onDeletePost: (DiaryPost) -> Void
    let onTapImage: (DiaryImage) -> Void
    let onOpenSource: (DiaryImage) -> Void
    let onOpenViewer: (DiaryPost) -> Void
    let onLinkPost: (DiaryPost) -> Void
    let onEditPost: (DiaryPost) -> Void
    let onOpenLinkedPost: (Int64) -> Void
    let onDeleteLink: (Int64) -> Void
    let onMoveLink: (Int, Int) -> Void
    let onLinkComment: (DiaryPost) -> Void
    let onUnlinkComment: (DiaryPost) -> Void
    let onReplyPost: (DiaryPost) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack {
                Text(post.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("ID: \(post.id)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Button {
                    onLinkComment(post)
                } label: {
                    Label(
                        "親投稿に紐付ける",
                        systemImage: "arrow.turn.down.right"
                    )
                }

                Spacer()
                
                Button {
                    onReplyPost(post)
                } label: {
                    Label(
                        "返信",
                        systemImage: "arrowshape.turn.up.left"
                    )
                }
                .buttonStyle(.plain)
                .help("コメントを追加")
                
                Button {
                    onOpenViewer(post)
                } label: {
                    Image(systemName: "photo.on.rectangle")
                }

                Button {
                    //print(
                    //    "PostCardView 関連記事追加:",
                    //    post.id
                    //)

                    onLinkPost(post)
                } label: {
                    Label(
                        "関連記事を追加",
                        systemImage: "link"
                    )

                    //Image(systemName: "link")
                }
                .buttonStyle(.plain)
                .help("関連投稿を追加")

                Button {
                    onEditPost(post)
                } label: {
                    Image(systemName: "pencil")
                }
                
                Button {
                    onDeletePost(post)
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.plain)
                
            }

            Text(attributedBody(post.body))
                .font(.body)
                .textSelection(.enabled)

            Text("画像数: \(post.images.count)")
                .font(.caption)
                .foregroundStyle(.red)

            if !post.images.isEmpty {
                ImageGridView(
                    images: post.images,
                    onTapImage: { image in
                        onTapImage(image)
                    },
                    onDelete: { image in
                        onDeleteImage(post, image)
                    },
                    onOpenSource: { image in
                        onOpenSource(image)
                    }
                )
            }
            
            if !post.links.isEmpty {
                relatedPostsSection
            }
            
            if !backlinks.isEmpty {
                backlinksSection
            }
            
            PostCommentsView(
                parentPost: post,
                posts: posts,
                onEditPost: { comment in
                    onEditPost(comment)
                },

                onOpenViewer: { comment in
                    onOpenViewer(comment)
                },

                onLinkPost: { comment in
                    onLinkPost(comment)
                },
                
                onUnlinkComment: { comment in
                    onUnlinkComment(comment)
                },

                onTapImage: { comment, image in
                    onTapImage(image)
                },

                onDeleteImage: { comment, image in
                    onDeleteImage(
                        comment,
                        image
                    )
                },

                onOpenSource: { image in
                    onOpenSource(image)
                },
                
                onReplyPost: onReplyPost

            )
            /*
            PostCommentsView(
                parentPost: post,
                posts: posts,
                onUnlinkComment: { comment in
                    onUnlinkComment(comment)
                },
                onTapImage: {
                    _,
                    image in

                    onTapImage(
                        image
                    )
                },
                onDeleteImage: {
                    comment,
                    image in

                    onDeleteImage(
                        comment,
                        image
                    )
                },
                onOpenSource: {
                    image in

                    onOpenSource(
                        image
                    )
                }

            )
             */
            
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 1)
        
    }

    private func attributedBody(_ text: String) -> AttributedString {
        var attributed = AttributedString(text)

        let detector = try? NSDataDetector(
            types: NSTextCheckingResult.CheckingType.link.rawValue
        )

        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)

        detector?.enumerateMatches(
            in: text,
            options: [],
            range: nsRange
        ) { match, _, _ in
            guard
                let match,
                let url = match.url,
                let range = Range(match.range, in: text),
                let attributedRange = Range(range, in: attributed)
            else {
                return
            }

            attributed[attributedRange].link = url
        }

        return attributed
    }
    
    private var relatedPostsSection: some View {
        VStack(alignment: .leading, spacing: 8) {

            Divider()

            Text("関連投稿")
                .font(.headline)

            ForEach(
                Array(post.links.enumerated()),
                id: \.element.id
            ) { index, link in

                if let targetPost = postDictionary[link.toPostId] {
                    relatedPostRow(
                        targetPost,
                        index: index
                    )
                } else {
                    missingPostRow(
                        targetPostID: link.toPostId
                    )
                }
            }
        }
        .padding(.top, 8)
    }

    private func relatedPostRow(
        _ targetPost: DiaryPost,
        index: Int
    ) -> some View {

        HStack(spacing: 10) {

            Button {
                onOpenLinkedPost(targetPost.id)
            } label: {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "arrow.turn.down.right")
                        .padding(.top, 3)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("ID: \(targetPost.id)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(summaryText(for: targetPost))
                            .lineLimit(2)
                            .foregroundStyle(.primary)
                    }

                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                onMoveLink(index, index - 1)
            } label: {
                Image(systemName: "chevron.up")
            }
            .buttonStyle(.plain)
            .disabled(index == 0)
            .help("上へ移動")

            Button {
                onMoveLink(index, index + 1)
            } label: {
                Image(systemName: "chevron.down")
            }
            .buttonStyle(.plain)
            .disabled(index == post.links.count - 1)
            .help("下へ移動")

            Button {
                onDeleteLink(targetPost.id)
            } label: {
                Image(systemName: "xmark.circle")
            }
            .buttonStyle(.plain)
            .help("関連投稿から削除")
        }
        .padding(.vertical, 3)
    }

    private func missingPostRow(
        targetPostID: Int64
    ) -> some View {

        HStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(.secondary)

            Text("投稿 ID \(targetPostID) が見つかりません")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                onDeleteLink(targetPostID)
            } label: {
                Image(systemName: "xmark.circle")
            }
            .buttonStyle(.plain)
        }
    }

    private func summaryText(
        for post: DiaryPost
    ) -> String {

        let trimmed = post.body
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        if trimmed.isEmpty {
            return "本文なし"
        }

        return trimmed
            .replacingOccurrences(
                of: "\n",
                with: " "
            )
    }
    
    private var backlinksSection: some View {
        VStack(alignment: .leading, spacing: 8) {

            Divider()

            Text("この投稿を参照している投稿")
                .font(.headline)

            ForEach(backlinks) { sourcePost in
                Button {
                    onOpenLinkedPost(sourcePost.id)
                } label: {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "arrow.turn.up.left")
                            .padding(.top, 3)

                        VStack(alignment: .leading, spacing: 3) {
                            Text("ID: \(sourcePost.id)")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(summaryText(for: sourcePost))
                                .lineLimit(2)
                                .foregroundStyle(.primary)
                        }

                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 8)
    }
}
