//
//  SpacedRepetitionService.swift
//  AutoQuiz
//

import Foundation
import Observation
import OSLog

@Observable
final class SpacedRepetitionService {
    private let store: AutoQuizStore

    init(store: AutoQuizStore) {
        self.store = store
    }

    func createCardsFromQuestions(for document: Item, sourceContentRevision: Int? = nil) async {
        var newCards: [SpacedRepetitionCard] = []
        let resolvedRevision = sourceContentRevision ?? document.contentRevision

        for question in document.questions {
            if let cardData = try? JSONEncoder().encode(question) {
                let card = SpacedRepetitionCard(
                    questionText: question.question,
                    answerText: question.anwswer,
                    questionType: .multipleChoice,
                    originalQuestionData: cardData,
                    documentID: document.id,
                    sourceContentRevision: resolvedRevision
                )
                newCards.append(card)
            }
        }

        if let trueFalseQuestions = document.trueFalseQuestions {
            for question in trueFalseQuestions {
                if let cardData = try? JSONEncoder().encode(question) {
                    let card = SpacedRepetitionCard(
                        questionText: question.question,
                        answerText: question.isTrue ? "True" : "False",
                        questionType: .trueFalse,
                        originalQuestionData: cardData,
                        documentID: document.id,
                        sourceContentRevision: resolvedRevision
                    )
                    newCards.append(card)
                }
            }
        }

        do {
            try await store.upsertSpacedRepetitionCards(newCards)
            Logger.database.info("Created \(newCards.count) spaced repetition cards for document")
        } catch {
            Logger.error.error("Failed to save spaced repetition cards: \(error.localizedDescription)")
        }
    }

    func getDueCards(
        for document: Item? = nil,
        sourceContentRevision: Int? = nil,
        limit: Int = 20
    ) async -> [SpacedRepetitionCard] {
        let cards = await store.spacedRepetitionCards(documentID: document?.id, sourceContentRevision: sourceContentRevision)
            .sorted {
                if $0.nextReviewDate == $1.nextReviewDate {
                    return $0.repetitionNumber < $1.repetitionNumber
                }
                return $0.nextReviewDate < $1.nextReviewDate
            }

        return Array(cards.filter { $0.isDue }.prefix(limit))
    }

    func getAllCards(for document: Item, sourceContentRevision: Int? = nil) async -> [SpacedRepetitionCard] {
        let cards = await store.spacedRepetitionCards(documentID: document.id, sourceContentRevision: sourceContentRevision)
        return cards.sorted { $0.timestamp > $1.timestamp }
    }

    func getLearningCards(
        for document: Item? = nil,
        sourceContentRevision: Int? = nil,
        limit: Int = 10
    ) async -> [SpacedRepetitionCard] {
        let cards = await store.spacedRepetitionCards(documentID: document?.id, sourceContentRevision: sourceContentRevision)
            .filter { $0.isLearning }
            .sorted { $0.timestamp < $1.timestamp }

        return Array(cards.prefix(limit))
    }

    func startReviewSession(
        for document: Item? = nil,
        sourceContentRevision: Int? = nil,
        includeNewCards: Bool = true
    ) async -> SpacedRepetitionSession {
        var sessionCards: [SpacedRepetitionCard] = []

        sessionCards.append(contentsOf: await getDueCards(
            for: document,
            sourceContentRevision: sourceContentRevision,
            limit: 15
        ))

        if includeNewCards {
            let learningCards = await getLearningCards(
                for: document,
                sourceContentRevision: sourceContentRevision,
                limit: 5
            )
            sessionCards.append(contentsOf: learningCards)
        }

        let uniqueCards = Array(Set(sessionCards))
        let shuffledCards = uniqueCards.shuffled()

        return SpacedRepetitionSession(
            cards: shuffledCards,
            document: document,
            startTime: Date()
        )
    }

    func recordReview(
        card: SpacedRepetitionCard,
        quality: Int,
        responseTime: TimeInterval
    ) async {
        card.review(quality: quality, responseTime: responseTime)

        do {
            try await store.upsertSpacedRepetitionCard(card)
            Logger.database.debug("Recorded review for card: \(card.questionText.prefix(50))")
        } catch {
            Logger.error.error("Failed to save card review: \(error.localizedDescription)")
        }
    }

    func getStatistics(for document: Item? = nil, sourceContentRevision: Int? = nil) async -> SpacedRepetitionStatistics {
        let cards: [SpacedRepetitionCard]

        if let document {
            cards = await getAllCards(for: document, sourceContentRevision: sourceContentRevision)
        } else {
            cards = await store.spacedRepetitionCards(sourceContentRevision: sourceContentRevision)
        }

        let totalCards = cards.count
        let dueCards = cards.filter { $0.isDue }.count
        let learningCards = cards.filter { $0.isLearning }.count
        let matureCards = cards.filter { !$0.isLearning && $0.repetitionNumber > 2 }.count

        let totalReviews = cards.reduce(0) { $0 + $1.totalReviews }
        let correctReviews = cards.reduce(0) { $0 + $1.correctReviews }
        let overallAccuracy = totalReviews > 0 ? Double(correctReviews) / Double(totalReviews) * 100 : 0

        let averageEasiness = cards.isEmpty ? 0 : cards.reduce(0) { $0 + $1.easinessFactor } / Double(cards.count)

        return SpacedRepetitionStatistics(
            totalCards: totalCards,
            dueCards: dueCards,
            learningCards: learningCards,
            matureCards: matureCards,
            overallAccuracy: overallAccuracy,
            averageEasiness: averageEasiness,
            totalReviews: totalReviews
        )
    }
}

struct SpacedRepetitionSession {
    let cards: [SpacedRepetitionCard]
    let document: Item?
    let startTime: Date
    var currentCardIndex: Int = 0
    var completedCards: [SpacedRepetitionCard] = []

    var currentCard: SpacedRepetitionCard? {
        guard currentCardIndex < cards.count else { return nil }
        return cards[currentCardIndex]
    }

    var isComplete: Bool {
        currentCardIndex >= cards.count
    }

    var progress: Double {
        guard !cards.isEmpty else { return 1.0 }
        return Double(currentCardIndex) / Double(cards.count)
    }

    mutating func moveToNextCard() {
        if let current = currentCard {
            completedCards.append(current)
        }
        currentCardIndex += 1
    }
}

struct SpacedRepetitionStatistics {
    let totalCards: Int
    let dueCards: Int
    let learningCards: Int
    let matureCards: Int
    let overallAccuracy: Double
    let averageEasiness: Double
    let totalReviews: Int

    var reviewedCards: Int {
        totalCards - learningCards
    }

    var completionRate: Double {
        guard totalCards > 0 else { return 0 }
        return Double(matureCards) / Double(totalCards) * 100
    }
}
