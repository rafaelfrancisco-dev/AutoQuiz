//
//  AutoQuizApp.swift
//  AutoQuiz
//

import SwiftUI

@main
struct AutoQuizApp: App {
    @State private var appStore = AppStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appStore)
                .task {
                    await appStore.bootstrap()
                }
        }
    }
}
