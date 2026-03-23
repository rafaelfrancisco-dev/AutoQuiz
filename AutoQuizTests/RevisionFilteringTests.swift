import Foundation
import Testing
@testable import AutoQuiz

struct RevisionFilteringTests {
    @Test
    func analyticsFiltersSessionsBySourceContentRevision() async throws {
        let (store, storeDirectory) = try await makeStore()
        defer { try? FileManager.default.removeItem(at: storeDirectory) }

        let item = Item(timestamp: .now, content: "Analytics test", contentRevision: 2)
        try await store.upsertItem(item)

        let revisionOneSession = QuizSession(
            documentID: item.id,
            questionType: .multipleChoice,
            maxQuestions: 5,
            isUnlimitedQuestions: false,
            shuffleQuestions: false,
            includeFailedQuestions: false,
            sourceContentRevision: 1
        )
        revisionOneSession.questionsAttempted = 1
        revisionOneSession.questionsCorrect = 1

        let revisionTwoSession = QuizSession(
            documentID: item.id,
            questionType: .multipleChoice,
            maxQuestions: 5,
            isUnlimitedQuestions: false,
            shuffleQuestions: false,
            includeFailedQuestions: false,
            sourceContentRevision: 2
        )
        revisionTwoSession.questionsAttempted = 1
        revisionTwoSession.questionsCorrect = 0

        try await store.upsertQuizSession(revisionOneSession)
        try await store.upsertQuizSession(revisionTwoSession)

        let service = AnalyticsService(store: store)

        let allMetrics = await service.getTimeRangeMetrics(for: .allTime, document: item)
        #expect(allMetrics.sessions.count == 2)

        let revisionTwoMetrics = await service.getTimeRangeMetrics(
            for: .allTime,
            document: item,
            sourceContentRevision: 2
        )

        #expect(revisionTwoMetrics.sessions.count == 1)
        #expect(revisionTwoMetrics.sessions.first?.sourceContentRevision == 2)

        await store.close()
    }

    @Test
    func spacedRepetitionServiceFiltersCardsBySourceContentRevision() async throws {
        let (store, storeDirectory) = try await makeStore()
        defer { try? FileManager.default.removeItem(at: storeDirectory) }

        let item = Item(timestamp: .now, content: "Spaced repetition test", contentRevision: 2)
        try await store.upsertItem(item)

        let revisionOneCard = SpacedRepetitionCard(
            questionText: "Q1",
            answerText: "A1",
            questionType: .multipleChoice,
            originalQuestionData: Data(),
            documentID: item.id,
            sourceContentRevision: 1
        )
        revisionOneCard.nextReviewDate = Date().addingTimeInterval(-3600)

        let revisionTwoCard = SpacedRepetitionCard(
            questionText: "Q2",
            answerText: "A2",
            questionType: .multipleChoice,
            originalQuestionData: Data(),
            documentID: item.id,
            sourceContentRevision: 2
        )
        revisionTwoCard.nextReviewDate = Date().addingTimeInterval(-3600)

        try await store.upsertSpacedRepetitionCard(revisionOneCard)
        try await store.upsertSpacedRepetitionCard(revisionTwoCard)

        let service = SpacedRepetitionService(store: store)
        let revisionTwoDueCards = await service.getDueCards(for: item, sourceContentRevision: 2, limit: 10)

        #expect(revisionTwoDueCards.count == 1)
        #expect(revisionTwoDueCards.first?.sourceContentRevision == 2)

        let revisionOneCards = await service.getAllCards(for: item, sourceContentRevision: 1)
        #expect(revisionOneCards.count == 1)
        #expect(revisionOneCards.first?.sourceContentRevision == 1)

        await store.close()
    }

    @Test
    func appendContentAdvancesRevisionAndInvalidatesDerivedArtifacts() {
        let item = Item(timestamp: .now, content: "Original", contentRevision: 1)
        item.questions = [
            MultipleChoiceQuestion(question: "Q", options: ["A", "B", "C", "D"], answer: "A")
        ]
        item.trueFalseQuestions = [TrueFalseQuestion(question: "TF", isTrue: true)]
        item.title = "Title"

        item.appendContentAndAdvanceRevision("New content")

        #expect(item.contentRevision == 2)
        #expect(item.content.contains("New content"))
        #expect(item.questions.isEmpty)
        #expect(item.trueFalseQuestions?.isEmpty == true)
        #expect(item.title == nil)
    }

    @Test
    func storePersistsItemsAcrossReopen() async throws {
        let storeDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("AutoQuizTests-\(UUID().uuidString)", isDirectory: true)
        let storeURL = storeDirectory.appendingPathComponent("autoquiz.mv2s")

        let store = try await AutoQuizStore.open(at: storeURL)
        let item = Item(timestamp: .now, content: "Persist me", contentRevision: 3)
        item.title = "Saved"
        try await store.upsertItem(item)
        await store.close()

        let reopened = try await AutoQuizStore.open(at: storeURL)
        let items = await reopened.items()
        #expect(items.count == 1)
        #expect(items.first?.id == item.id)
        #expect(items.first?.contentRevision == 3)
        #expect(items.first?.title == "Saved")
        await reopened.close()

        try? FileManager.default.removeItem(at: storeDirectory)
    }

    private func makeStore() async throws -> (AutoQuizStore, URL) {
        let storeDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("AutoQuizTests-\(UUID().uuidString)", isDirectory: true)
        let storeURL = storeDirectory.appendingPathComponent("autoquiz.mv2s")
        let store = try await AutoQuizStore.open(at: storeURL)
        return (store, storeDirectory)
    }
}
