//
//  myDiaryApp.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/06.
//

import SwiftUI

@main
struct myDiaryApp: App {

    var body: some Scene {

        WindowGroup {
            ContentView()
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                AboutMenuCommand()
            }
        }

        Window(
            "About myDiary",
            id: "about"
        ) {
            AboutView()
        }
        .windowResizability(.contentSize)
    }
}
