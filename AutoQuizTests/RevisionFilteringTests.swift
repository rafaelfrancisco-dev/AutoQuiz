import Foundation
import SwiftData
import Testing
@testable import AutoQuiz

struct RevisionFilteringTests {
    @Test
    func analyticsFiltersSessionsBySourceContentRevision() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let item = Item(timestamp: .now, content: "Analytics test", contentRevision: 2)
        context.insert(item)

        let revisionOneSession = QuizSession(
            document: item,
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
            document: item,
            questionType: .multipleChoice,
            maxQuestions: 5,
            isUnlimitedQuestions: false,
            shuffleQuestions: false,
            includeFailedQuestions: false,
            sourceContentRevision: 2
        )
        revisionTwoSession.questionsAttempted = 1
        revisionTwoSession.questionsCorrect = 0

        context.insert(revisionOneSession)
        context.insert(revisionTwoSession)
        try context.save()

        let service = AnalyticsService(modelContext: context)

        let allMetrics = service.getTimeRangeMetrics(for: .allTime, document: item)
        #expect(allMetrics.sessions.count == 2)

        let revisionTwoMetrics = service.getTimeRangeMetrics(
            for: .allTime,
            document: item,
            sourceContentRevision: 2
        )

        #expect(revisionTwoMetrics.sessions.count == 1)
        #expect(revisionTwoMetrics.sessions.first?.sourceContentRevision == 2)
    }

    @Test
    func spacedRepetitionServiceFiltersCardsBySourceContentRevision() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let item = Item(timestamp: .now, content: "Spaced repetition test", contentRevision: 2)
        context.insert(item)

        let revisionOneCard = SpacedRepetitionCard(
            questionText: "Q1",
            answerText: "A1",
            questionType: .multipleChoice,
            originalQuestionData: Data(),
            document: item,
            sourceContentRevision: 1
        )
        revisionOneCard.nextReviewDate = Date().addingTimeInterval(-3600)

        let revisionTwoCard = SpacedRepetitionCard(
            questionText: "Q2",
            answerText: "A2",
            questionType: .multipleChoice,
            originalQuestionData: Data(),
            document: item,
            sourceContentRevision: 2
        )
        revisionTwoCard.nextReviewDate = Date().addingTimeInterval(-3600)

        context.insert(revisionOneCard)
        context.insert(revisionTwoCard)
        try context.save()

        let service = SpacedRepetitionService(modelContext: context)
        let revisionTwoDueCards = service.getDueCards(for: item, sourceContentRevision: 2, limit: 10)

        #expect(revisionTwoDueCards.count == 1)
        #expect(revisionTwoDueCards.first?.sourceContentRevision == 2)

        let revisionOneCards = service.getAllCards(for: item, sourceContentRevision: 1)
        #expect(revisionOneCards.count == 1)
        #expect(revisionOneCards.first?.sourceContentRevision == 1)
    }

    @Test
    func appendContentAdvancesRevisionAndInvalidatesDerivedArtifacts() {
        let item = Item(timestamp: .now, content: "Original", contentRevision: 1)
        item.questions = [
            MultipleChoiceQuestion(question: "Q", options: ["A", "B", "C", "D"], anwswer: "A")
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

    private func makeInMemoryContainer() throws -> ModelContainer {
        let schema = Schema(SchemaV4.models, version: SchemaV4.versionIdentifier)
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: configuration)
    }
}
