//
//  SpacedRepetitionService.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 22/06/2025.
//

import Foundation
import SwiftData
import OSLog

@Observable
final class SpacedRepetitionService {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Card Management
    
    /// Creates spaced repetition cards from existing questions
    func createCardsFromQuestions(for document: Item, sourceContentRevision: Int? = nil) async {
        var newCards: [SpacedRepetitionCard] = []
        let resolvedRevision = sourceContentRevision ?? document.contentRevision
        
        // Create cards from multiple choice questions
        for question in document.questions {
            if let cardData = try? JSONEncoder().encode(question) {
                let card = SpacedRepetitionCard(
                    questionText: question.question,
                    answerText: question.anwswer,
                    questionType: .multipleChoice,
                    originalQuestionData: cardData,
                    document: document,
                    sourceContentRevision: resolvedRevision
                )
                newCards.append(card)
            }
        }
        
        // Create cards from true/false questions
        if let trueFalseQuestions = document.trueFalseQuestions {
            for question in trueFalseQuestions {
                if let cardData = try? JSONEncoder().encode(question) {
                    let card = SpacedRepetitionCard(
                        questionText: question.question,
                        answerText: question.isTrue ? "True" : "False",
                        questionType: .trueFalse,
                        originalQuestionData: cardData,
                        document: document,
                        sourceContentRevision: resolvedRevision
                    )
                    newCards.append(card)
                }
            }
        }
        
        // Insert new cards into context
        for card in newCards {
            modelContext.insert(card)
        }
        
        do {
            try modelContext.save()
            Logger.database.info("Created \(newCards.count) spaced repetition cards for document")
        } catch {
            Logger.error.error("Failed to save spaced repetition cards: \(error)")
        }
    }
    
    /// Gets cards that are due for review
    func getDueCards(
        for document: Item? = nil,
        sourceContentRevision: Int? = nil,
        limit: Int = 20
    ) -> [SpacedRepetitionCard] {
        let descriptor = FetchDescriptor<SpacedRepetitionCard>(
            sortBy: [
                SortDescriptor(\.nextReviewDate),
                SortDescriptor(\.repetitionNumber)
            ]
        )
        
        do {
            let allCards = try modelContext.fetch(descriptor)
            
            let filteredCards = allCards.filter { card in
                let isDue = card.isDue
                let matchesDocument = document == nil || card.document?.id == document?.id
                let matchesRevision = sourceContentRevision == nil || card.sourceContentRevision == sourceContentRevision
                return isDue && matchesDocument && matchesRevision
            }
            
            return Array(filteredCards.prefix(limit))
        } catch {
            Logger.error.error("Failed to fetch due cards: \(error)")
            return []
        }
    }
    
    /// Gets all cards for a specific document
    func getAllCards(for document: Item, sourceContentRevision: Int? = nil) -> [SpacedRepetitionCard] {
        let descriptor = FetchDescriptor<SpacedRepetitionCard>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        do {
            let allCards = try modelContext.fetch(descriptor)
            return allCards.filter {
                $0.document?.id == document.id &&
                (sourceContentRevision == nil || $0.sourceContentRevision == sourceContentRevision)
            }
        } catch {
            Logger.error.error("Failed to fetch cards for document: \(error)")
            return []
        }
    }
    
    /// Gets cards in learning phase (new cards or those being relearned)
    func getLearningCards(
        for document: Item? = nil,
        sourceContentRevision: Int? = nil,
        limit: Int = 10
    ) -> [SpacedRepetitionCard] {
        let descriptor = FetchDescriptor<SpacedRepetitionCard>(
            sortBy: [SortDescriptor(\.timestamp)]
        )
        
        do {
            let allCards = try modelContext.fetch(descriptor)
            
            let filteredCards = allCards.filter { card in
                let isLearning = card.isLearning
                let matchesDocument = document == nil || card.document?.id == document?.id
                let matchesRevision = sourceContentRevision == nil || card.sourceContentRevision == sourceContentRevision
                return isLearning && matchesDocument && matchesRevision
            }
            
            return Array(filteredCards.prefix(limit))
        } catch {
            Logger.error.error("Failed to fetch learning cards: \(error)")
            return []
        }
    }
    
    // MARK: - Review Session Management
    
    /// Starts a spaced repetition review session
    func startReviewSession(
        for document: Item? = nil,
        sourceContentRevision: Int? = nil,
        includeNewCards: Bool = true
    ) -> SpacedRepetitionSession {
        var sessionCards: [SpacedRepetitionCard] = []
        
        // Add due cards
        sessionCards.append(contentsOf: getDueCards(
            for: document,
            sourceContentRevision: sourceContentRevision,
            limit: 15
        ))
        
        // Add learning cards if needed
        if includeNewCards {
            let learningCards = getLearningCards(
                for: document,
                sourceContentRevision: sourceContentRevision,
                limit: 5
            )
            sessionCards.append(contentsOf: learningCards)
        }
        
        // Remove duplicates and shuffle
        let uniqueCards = Array(Set(sessionCards))
        let shuffledCards = uniqueCards.shuffled()
        
        return SpacedRepetitionSession(
            cards: shuffledCards,
            document: document,
            startTime: Date()
        )
    }
    
    /// Records a review for a card
    func recordReview(
        card: SpacedRepetitionCard,
        quality: Int,
        responseTime: TimeInterval
    ) {
        card.review(quality: quality, responseTime: responseTime)
        
        do {
            try modelContext.save()
            Logger.database.debug("Recorded review for card: \(card.questionText.prefix(50))")
        } catch {
            Logger.error.error("Failed to save card review: \(error)")
        }
    }
    
    // MARK: - Statistics
    
    /// Gets overall statistics for spaced repetition
    func getStatistics(for document: Item? = nil, sourceContentRevision: Int? = nil) -> SpacedRepetitionStatistics {
        let cards = document != nil
            ? getAllCards(for: document!, sourceContentRevision: sourceContentRevision)
            : getAllCards(sourceContentRevision: sourceContentRevision)
        
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
    
    private func getAllCards(sourceContentRevision: Int? = nil) -> [SpacedRepetitionCard] {
        let descriptor = FetchDescriptor<SpacedRepetitionCard>()

        do {
            let cards = try modelContext.fetch(descriptor)
            guard let sourceContentRevision else { return cards }
            return cards.filter { $0.sourceContentRevision == sourceContentRevision }
        } catch {
            Logger.error.error("Failed to fetch all cards: \(error)")
            return []
        }
    }
}

// MARK: - Supporting Types

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
