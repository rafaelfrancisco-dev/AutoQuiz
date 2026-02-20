//
//  SpacedRepetitionAnalyticsService.swift
//  AutoQuiz
//

import Foundation
import Observation
import OSLog

@Observable
final class SpacedRepetitionAnalyticsService {
    private let store: AutoQuizStore

    init(store: AutoQuizStore) {
        self.store = store
    }

    func getSpacedRepetitionMetrics(
        for document: Item? = nil,
        timeRange: TimeRange = .allTime,
        sourceContentRevision: Int? = nil
    ) async -> SpacedRepetitionMetrics {
        let cards = await getCards(for: document, timeRange: timeRange, sourceContentRevision: sourceContentRevision)

        guard !cards.isEmpty else { return .empty }

        let totalCards = cards.count
        let dueCards = cards.filter { $0.isDue }.count
        let learningCards = cards.filter { $0.isLearning }.count
        let matureCards = cards.filter { !$0.isLearning && $0.repetitionNumber > 2 }.count

        let totalReviews = cards.reduce(0) { $0 + $1.totalReviews }
        let correctReviews = cards.reduce(0) { $0 + $1.correctReviews }
        let overallAccuracy = totalReviews > 0 ? Double(correctReviews) / Double(totalReviews) * 100 : 0

        let averageEasiness = cards.reduce(0) { $0 + $1.easinessFactor } / Double(cards.count)
        let averageInterval = cards.reduce(0) { $0 + $1.intervalDays } / cards.count

        return SpacedRepetitionMetrics(
            totalCards: totalCards,
            dueCards: dueCards,
            learningCards: learningCards,
            matureCards: matureCards,
            overallAccuracy: overallAccuracy,
            averageEasiness: averageEasiness,
            averageInterval: averageInterval,
            totalReviews: totalReviews,
            currentStreak: calculateCurrentStreak(cards: cards),
            longestStreak: calculateLongestStreak(cards: cards),
            difficultyDistribution: calculateDifficultyDistribution(cards: cards),
            retentionRate: calculateRetentionRate(cards: cards)
        )
    }

    func getLearningProgress(
        for document: Item? = nil,
        days: Int = 30,
        sourceContentRevision: Int? = nil
    ) async -> [LearningProgressPoint] {
        let timeRange: TimeRange = days <= 7 ? .thisWeek : (days <= 30 ? .thisMonth : .allTime)
        let cards = await getCards(for: document, timeRange: timeRange, sourceContentRevision: sourceContentRevision)
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) ?? endDate

        var progressPoints: [LearningProgressPoint] = []

        for i in 0...days {
            guard let date = calendar.date(byAdding: .day, value: i, to: startDate) else { continue }

            let cardsReviewedOnDate = cards.filter { card in
                guard let lastReview = card.lastReviewDate else { return false }
                return calendar.isDate(lastReview, inSameDayAs: date)
            }

            let newCards = cardsReviewedOnDate.filter { $0.totalReviews == 1 }.count
            let reviewedCards = cardsReviewedOnDate.filter { $0.totalReviews > 1 }.count
            let accuracy = cardsReviewedOnDate.isEmpty ? 0 :
                Double(cardsReviewedOnDate.reduce(0) { $0 + $1.correctReviews }) /
                Double(cardsReviewedOnDate.reduce(0) { $0 + $1.totalReviews }) * 100

            progressPoints.append(LearningProgressPoint(
                date: date,
                newCards: newCards,
                reviewedCards: reviewedCards,
                accuracy: accuracy
            ))
        }

        return progressPoints
    }

    func getDifficultyAnalysis(for document: Item? = nil, sourceContentRevision: Int? = nil) async -> [DifficultyAnalysis] {
        let cards = await getCards(for: document, sourceContentRevision: sourceContentRevision)

        return DifficultyLevel.allCases.map { difficulty in
            let cardsAtLevel = cards.filter { $0.difficultyLevel == difficulty }
            let count = cardsAtLevel.count
            let averageReviews = cardsAtLevel.isEmpty ? 0 :
                Double(cardsAtLevel.reduce(0) { $0 + $1.totalReviews }) / Double(count)
            let averageAccuracy = cardsAtLevel.isEmpty ? 0 :
                cardsAtLevel.reduce(0) { $0 + $1.accuracyPercentage } / Double(count)

            return DifficultyAnalysis(
                difficulty: difficulty,
                cardCount: count,
                averageReviews: averageReviews,
                averageAccuracy: averageAccuracy
            )
        }
    }

    private func getCards(
        for document: Item? = nil,
        timeRange: TimeRange = .allTime,
        sourceContentRevision: Int? = nil
    ) async -> [SpacedRepetitionCard] {
        let cards = await store.spacedRepetitionCards(documentID: document?.id, sourceContentRevision: sourceContentRevision)

        return cards.filter { card in
            let inTimeRange = timeRange == .allTime || isCardInTimeRange(card, timeRange: timeRange)
            return inTimeRange
        }
    }

    private func isCardInTimeRange(_ card: SpacedRepetitionCard, timeRange: TimeRange) -> Bool {
        let dateRange = timeRange.dateRange
        return card.timestamp >= dateRange.start && card.timestamp <= dateRange.end
    }

    private func calculateCurrentStreak(cards: [SpacedRepetitionCard]) -> Int {
        let recentCards = cards.filter { $0.lastReviewDate != nil }
            .sorted { $0.lastReviewDate! > $1.lastReviewDate! }
            .prefix(20)

        var streak = 0
        for card in recentCards {
            if card.correctReviews > 0 && card.accuracyPercentage >= 80 {
                streak += 1
            } else {
                break
            }
        }

        return streak
    }

    private func calculateLongestStreak(cards: [SpacedRepetitionCard]) -> Int {
        let sortedCards = cards.filter { $0.lastReviewDate != nil }
            .sorted { $0.lastReviewDate! < $1.lastReviewDate! }

        var longestStreak = 0
        var currentStreak = 0

        for card in sortedCards {
            if card.correctReviews > 0 && card.accuracyPercentage >= 80 {
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
            } else {
                currentStreak = 0
            }
        }

        return longestStreak
    }

    private func calculateDifficultyDistribution(cards: [SpacedRepetitionCard]) -> [String: Int] {
        var distribution: [String: Int] = [:]

        for difficulty in DifficultyLevel.allCases {
            distribution[difficulty.rawValue] = cards.filter { $0.difficultyLevel == difficulty }.count
        }

        return distribution
    }

    private func calculateRetentionRate(cards: [SpacedRepetitionCard]) -> Double {
        let matureCards = cards.filter { !$0.isLearning && $0.repetitionNumber > 2 }
        guard !matureCards.isEmpty else { return 0 }

        let retainedCards = matureCards.filter { $0.accuracyPercentage >= 70 }
        return Double(retainedCards.count) / Double(matureCards.count) * 100
    }
}

struct SpacedRepetitionMetrics {
    let totalCards: Int
    let dueCards: Int
    let learningCards: Int
    let matureCards: Int
    let overallAccuracy: Double
    let averageEasiness: Double
    let averageInterval: Int
    let totalReviews: Int
    let currentStreak: Int
    let longestStreak: Int
    let difficultyDistribution: [String: Int]
    let retentionRate: Double

    static let empty = SpacedRepetitionMetrics(
        totalCards: 0, dueCards: 0, learningCards: 0, matureCards: 0,
        overallAccuracy: 0, averageEasiness: 0, averageInterval: 0,
        totalReviews: 0, currentStreak: 0, longestStreak: 0,
        difficultyDistribution: [:], retentionRate: 0
    )
}

struct LearningProgressPoint {
    let date: Date
    let newCards: Int
    let reviewedCards: Int
    let accuracy: Double
}

struct DifficultyAnalysis {
    let difficulty: DifficultyLevel
    let cardCount: Int
    let averageReviews: Double
    let averageAccuracy: Double
}
