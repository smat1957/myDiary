//
//  AboutMenuCommand.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/17.
//

import SwiftUI

struct AboutMenuCommand: View {

    @Environment(\.openWindow)
    private var openWindow

    var body: some View {

        Button("About myDiary") {
            openWindow(id: "about")
        }
    }
}
