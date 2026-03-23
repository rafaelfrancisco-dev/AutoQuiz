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
                    await configureStore()
                }
        }
    }

    private func configureStore() async {
        guard !appStore.isReady else { return }

        if ProcessInfo.processInfo.arguments.contains("UITEST_SAMPLE_DATA") {
            await loadUITestFixture()
        } else {
            await appStore.bootstrap()
        }
    }

    private func loadUITestFixture() async {
        do {
            let storeURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("AutoQuiz-UITests-\(UUID().uuidString)")
                .appendingPathExtension("mv2s")
            
            let store = try await AutoQuizStore.open(at: storeURL)
            let item = PreviewData.sampleItem()

            await appStore.loadFixture(
                store: store,
                items: [item],
                quizSessions: PreviewData.sampleQuizSessions(for: item),
                spacedRepetitionCards: PreviewData.sampleSpacedRepetitionCards(for: item),
                documentQuestionAnswers: PreviewData.sampleDocumentAnswers(for: item)
            )
        } catch {
            await appStore.bootstrap()
        }
    }
}
