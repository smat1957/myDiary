//
//  ProgressDialog.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/22.
//

//
//  ProgressDialog.swift
//  myDiaryCore
//

import SwiftUI

public struct ProgressDialog: View {
        
    public let title: LocalizedStringKey

    @Bindable
    var progress: ImportProgressState

    public init(
        title: LocalizedStringKey,
        progress: ImportProgressState
    ) {
        self.title = title
        self.progress = progress
    }

    public var body: some View {

        VStack(spacing: 28) {
            Image(systemName: "square.and.arrow.down")
                .font(.system(size: 56))
                .foregroundColor(.accentColor)

            Text(title)
                .font(.title2)
                .fontWeight(.semibold)

            ProgressView(value: progress.fractionCompleted)
                .frame(width: 320)

            Text(progress.progressText)
                .monospacedDigit()

            Text(progress.message)
                .font(.headline)

            if !progress.detail.isEmpty {

                Text(progress.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .padding(40)
        .frame(width: 420)
    }
}
