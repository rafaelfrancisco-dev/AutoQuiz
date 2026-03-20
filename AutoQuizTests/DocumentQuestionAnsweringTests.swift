import Foundation
import Testing
@testable import AutoQuiz

struct DocumentQuestionAnsweringTests {
    @Test
    func storeFiltersDocumentQuestionAnswersByRevisionAndPersistsAcrossReopen() async throws {
        let storeDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("AutoQuizTests-\(UUID().uuidString)", isDirectory: true)
        let storeURL = storeDirectory.appendingPathComponent("autoquiz.mv2s")

        let store = try await AutoQuizStore.open(at: storeURL)
        let item = Item(timestamp: .now, content: "Original content", contentRevision: 1)
        try await store.upsertItem(item)

        let revisionOneAnswer = DocumentQuestionAnswer(
            documentID: item.id,
            question: "Revision one question",
            answer: "Revision one answer",
            responseKind: .answered,
            sourceContentRevision: 1
        )
        try await store.upsertDocumentQuestionAnswer(revisionOneAnswer)

        item.appendContentAndAdvanceRevision("Updated content")
        try await store.upsertItem(item)

        let revisionTwoAnswer = DocumentQuestionAnswer(
            documentID: item.id,
            question: "Revision two question",
            answer: "Revision two answer",
            responseKind: .answered,
            sourceContentRevision: item.contentRevision
        )
        try await store.upsertDocumentQuestionAnswer(revisionTwoAnswer)
        await store.close()

        let reopenedStore = try await AutoQuizStore.open(at: storeURL)
        let revisionOneResults = await reopenedStore.documentQuestionAnswers(
            documentID: item.id,
            sourceContentRevision: 1
        )
        let revisionTwoResults = await reopenedStore.documentQuestionAnswers(
            documentID: item.id,
            sourceContentRevision: 2
        )
        let allResults = await reopenedStore.documentQuestionAnswers(documentID: item.id)

        #expect(revisionOneResults.count == 1)
        #expect(revisionOneResults.first?.question == "Revision one question")
        #expect(revisionTwoResults.count == 1)
        #expect(revisionTwoResults.first?.question == "Revision two question")
        #expect(allResults.count == 2)

        await reopenedStore.close()
        try? FileManager.default.removeItem(at: storeDirectory)
    }

    @Test
    func deletingItemRemovesPersistedDocumentQuestionAnswers() async throws {
        let (store, storeDirectory) = try await makeStore()
        defer { try? FileManager.default.removeItem(at: storeDirectory) }

        let item = Item(timestamp: .now, content: "Delete me")
        try await store.upsertItem(item)

        let questionAnswer = DocumentQuestionAnswer(
            documentID: item.id,
            question: "Question",
            answer: "Answer",
            responseKind: .answered,
            sourceContentRevision: item.contentRevision
        )
        try await store.upsertDocumentQuestionAnswer(questionAnswer)

        try await store.deleteItem(id: item.id)

        let remainingAnswers = await store.documentQuestionAnswers(documentID: item.id)
        #expect(remainingAnswers.isEmpty)

        await store.close()
    }

    @Test
    @MainActor
    func submitDocumentQuestionPersistsAnswerForCurrentRevision() async throws {
        let (store, storeDirectory) = try await makeStore()
        defer { try? FileManager.default.removeItem(at: storeDirectory) }

        let item = Item(timestamp: .now, content: "AutoQuiz is a study app.")
        try await store.upsertItem(item)

        let appStore = AppStore(persistenceStore: store)
        let viewModel = DocumentViewModel(
            item: item,
            appStore: appStore,
            documentAnswerProvider: { question, _ in
                #expect(question == "What is AutoQuiz?")
                return DocumentAnswerResult(
                    answer: "AutoQuiz is a study app.",
                    responseKind: .answered
                )
            }
        )

        viewModel.documentQuestionInput = "What is AutoQuiz?"
        await viewModel.submitDocumentQuestion()

        let savedAnswers = await appStore.documentQuestionAnswers(
            documentID: item.id,
            sourceContentRevision: item.contentRevision
        )

        #expect(savedAnswers.count == 1)
        #expect(savedAnswers.first?.answer == "AutoQuiz is a study app.")
        #expect(savedAnswers.first?.responseKind == .answered)
        #expect(viewModel.documentQuestionInput.isEmpty)
        #expect(viewModel.documentQuestionAnswers.count == 1)

        await store.close()
    }

    @Test
    @MainActor
    func submitDocumentQuestionPersistsRefusalResponses() async throws {
        let (store, storeDirectory) = try await makeStore()
        defer { try? FileManager.default.removeItem(at: storeDirectory) }

        let item = Item(timestamp: .now, content: "The document covers the solar system.")
        try await store.upsertItem(item)

        let appStore = AppStore(persistenceStore: store)
        let viewModel = DocumentViewModel(
            item: item,
            appStore: appStore,
            documentAnswerProvider: { _, _ in
                DocumentAnswerResult(
                    answer: "The document does not describe that topic.",
                    responseKind: .insufficientDocumentContent
                )
            }
        )

        viewModel.documentQuestionInput = "Who wrote Hamlet?"
        await viewModel.submitDocumentQuestion()

        let savedAnswers = await appStore.documentQuestionAnswers(
            documentID: item.id,
            sourceContentRevision: item.contentRevision
        )

        #expect(savedAnswers.count == 1)
        #expect(savedAnswers.first?.responseKind == .insufficientDocumentContent)
        #expect(savedAnswers.first?.answer == "The document does not describe that topic.")
        #expect(viewModel.documentQuestionAnswers.first?.responseKind == .insufficientDocumentContent)

        await store.close()
    }

    private func makeStore() async throws -> (AutoQuizStore, URL) {
        let storeDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("AutoQuizTests-\(UUID().uuidString)", isDirectory: true)
        let storeURL = storeDirectory.appendingPathComponent("autoquiz.mv2s")
        let store = try await AutoQuizStore.open(at: storeURL)
        return (store, storeDirectory)
    }
}
