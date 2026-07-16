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

            PostCardHeaderView(
                post: post,

                onLinkComment:
                    onLinkComment,

                onReplyPost:
                    onReplyPost,

                onOpenViewer:
                    onOpenViewer,

                onLinkPost:
                    onLinkPost,

                onEditPost:
                    onEditPost,

                onDeletePost:
                    onDeletePost
            )

            Text(attributedBody(post.body))
                .font(.body)
                .textSelection(.enabled)

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

                RelatedPostsSectionView(
                    post: post,
                    postDictionary:
                        postDictionary,

                    onOpenLinkedPost:
                        onOpenLinkedPost,

                    onDeleteLink:
                        onDeleteLink,

                    onMoveLink:
                        onMoveLink
                )
            }
            
            if !backlinks.isEmpty {

                BacklinksSectionView(
                    backlinks: backlinks,
                    onOpenLinkedPost:
                        onOpenLinkedPost
                )
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
    
}
