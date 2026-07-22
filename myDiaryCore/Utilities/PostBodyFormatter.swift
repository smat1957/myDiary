//
//  PostBodyFormatter.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/22.
//

//
//  PostBodyFormatter.swift
//  myDiaryCore
//

import Foundation

public enum PostBodyFormatter {

    public static func format(
        _ body: String
    ) -> AttributedString {

        var attributedBody = AttributedString(body)

        guard
            let detector = try? NSDataDetector(
                types: NSTextCheckingResult.CheckingType.link.rawValue
            )
        else {
            return attributedBody
        }

        let nsBody = body as NSString

        let matches = detector.matches(
            in: body,
            options: [],
            range: NSRange(
                location: 0,
                length: nsBody.length
            )
        )

        for match in matches {

            guard
                let url = match.url,
                let stringRange = Range(
                    match.range,
                    in: body
                ),
                let attributedRange = Range(
                    stringRange,
                    in: attributedBody
                )
            else {
                continue
            }

            attributedBody[attributedRange].link = url
        }

        return attributedBody
    }
}
