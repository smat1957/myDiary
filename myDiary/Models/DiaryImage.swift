//
//  DiaryImage.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/06.
//

import Foundation

struct DiaryImage: Identifiable {

    let id = UUID()

    var baseName: String
    var originalExtension: String

    var sourceType: ImageSourceType
    var sourceURL: URL?
}
