//
//  AnalyticsService.swift
//  AutoQuiz
//

import Foundation
import Observation
import OSLog

@Observable
final class AnalyticsService {
    private let store: AutoQuizStore

    init(store: AutoQuizStore) {
        self.store = store
    }

    func getPerformanceOverview(
        for timeRange: TimeRange,
        document: Item? = nil,
        sourceContentRevision: Int? = nil
    ) async -> PerformanceOverview {
        let sessions = await getSessions(for: timeRange, document: document, sourceContentRevision: sourceContentRevision)

        guard !sessions.isEmpty else { return .empty }

        let completedSessions = sessions.filter { $0.isCompleted }
        let totalQuestions = sessions.reduce(0) { $0 + $1.questionsAttempted }
        let totalCorrect = sessions.reduce(0) { $0 + $1.questionsCorrect }
        let totalPoints = sessions.reduce(0) { $0 + $1.totalPointsEarned }

        let sessionsWithDuration = sessions.compactMap { $0.duration }
        let averageDuration = sessionsWithDuration.isEmpty ? 0 : sessionsWithDuration.reduce(0, +) / Double(sessionsWithDuration.count)

        let overallAccuracy = totalQuestions > 0 ? Double(totalCorrect) / Double(totalQuestions) * 100 : 0
        let completionRate = sessions.isEmpty ? 0 : Double(completedSessions.count) / Double(sessions.count)

        return PerformanceOverview(
            totalSessions: sessions.count,
            completedSessions: completedSessions.count,
            totalQuestionsAnswered: totalQuestions,
            totalCorrectAnswers: totalCorrect,
            totalPointsEarned: totalPoints,
            averageSessionDuration: averageDuration,
            overallAccuracy: overallAccuracy,
            completionRate: completionRate
        )
    }

    func getAccuracyTrend(
        for timeRange: TimeRange,
        document: Item? = nil,
        sourceContentRevision: Int? = nil
    ) async -> [AccuracyTrend] {
        let sessions = await getSessions(for: timeRange, document: document, sourceContentRevision: sourceContentRevision)

        let calendar = Calendar.current
        let groupedSessions = Dictionary(grouping: sessions) { session in
            calendar.startOfDay(for: session.startTime)
        }

        return groupedSessions.map { date, sessions in
            let totalQuestions = sessions.reduce(0) { $0 + $1.questionsAttempted }
            let totalCorrect = sessions.reduce(0) { $0 + $1.questionsCorrect }
            let accuracy = totalQuestions > 0 ? Double(totalCorrect) / Double(totalQuestions) * 100 : 0

            return AccuracyTrend(
                date: date,
                accuracy: accuracy,
                questionsCount: totalQuestions
            )
        }.sorted { $0.date < $1.date }
    }

    func getSessionTypeMetrics(
        for timeRange: TimeRange,
        document: Item? = nil,
        sourceContentRevision: Int? = nil
    ) async -> [SessionTypeMetrics] {
        let sessions = await getSessions(for: timeRange, document: document, sourceContentRevision: sourceContentRevision)
        let groupedByType = Dictionary(grouping: sessions) { $0.questionType }

        return Question.allCases.filter { $0 != .spacedRepetition }.compactMap { questionType in
            let typeSessions = groupedByType[questionType] ?? []
            guard !typeSessions.isEmpty else { return nil }

            let totalQuestions = typeSessions.reduce(0) { $0 + $1.questionsAttempted }
            let totalCorrect = typeSessions.reduce(0) { $0 + $1.questionsCorrect }
            let averageAccuracy = totalQuestions > 0 ? Double(totalCorrect) / Double(totalQuestions) * 100 : 0

            let responseTimes = typeSessions.map { $0.averageResponseTime }
            let averageResponseTime = responseTimes.isEmpty ? 0 : responseTimes.reduce(0, +) / Double(responseTimes.count)

            let bestStreak = calculateBestStreak(for: typeSessions)

            return SessionTypeMetrics(
                questionType: questionType,
                sessionCount: typeSessions.count,
                averageAccuracy: averageAccuracy,
                averageResponseTime: averageResponseTime,
                totalQuestions: totalQuestions,
                bestStreak: bestStreak
            )
        }
    }

    func getLearningProgress(
        for timeRange: TimeRange,
        document: Item? = nil,
        sourceContentRevision: Int? = nil
    ) async -> LearningProgress {
        let sessions = await getSessions(for: timeRange, document: document, sourceContentRevision: sourceContentRevision)
        let recentSessions = sessions.suffix(10)

        return LearningProgress(
            currentStreak: calculateCurrentStreak(sessions: sessions),
            bestStreak: calculateBestStreak(for: sessions),
            improvementRate: calculateImprovementRate(sessions: sessions),
            weakestAreas: [],
            strongestAreas: [],
            recentPerformanceTrend: calculateTrend(sessions: Array(recentSessions))
        )
    }

    func getTimeRangeMetrics(
        for timeRange: TimeRange,
        document: Item? = nil,
        sourceContentRevision: Int? = nil
    ) async -> TimeRangeMetrics {
        async let sessions = getSessions(for: timeRange, document: document, sourceContentRevision: sourceContentRevision)
        async let overview = getPerformanceOverview(for: timeRange, document: document, sourceContentRevision: sourceContentRevision)
        async let accuracyTrend = getAccuracyTrend(for: timeRange, document: document, sourceContentRevision: sourceContentRevision)
        async let sessionTypeBreakdown = getSessionTypeMetrics(for: timeRange, document: document, sourceContentRevision: sourceContentRevision)

        return await TimeRangeMetrics(
            timeRange: timeRange,
            sessions: sessions,
            overview: overview,
            accuracyTrend: accuracyTrend,
            sessionTypeBreakdown: sessionTypeBreakdown
        )
    }

    private func getSessions(
        for timeRange: TimeRange,
        document: Item? = nil,
        sourceContentRevision: Int? = nil
    ) async -> [QuizSession] {
        let dateRange = timeRange.dateRange
        let documentID = document?.id
        let sessions = await store.quizSessions(documentID: documentID, sourceContentRevision: sourceContentRevision)

        return sessions.filter {
            $0.startTime >= dateRange.start && $0.startTime <= dateRange.end
        }
    }

    private func calculateCurrentStreak(sessions: [QuizSession]) -> Int {
        let recentSessions = sessions.suffix(50).reversed()
        var streak = 0

        for session in recentSessions {
            if session.questionsCorrect == session.questionsAttempted && session.questionsAttempted > 0 {
                streak += 1
            } else {
                break
            }
        }

        return streak
    }

    private func calculateBestStreak(for sessions: [QuizSession]) -> Int {
        var bestStreak = 0
        var currentStreak = 0

        for session in sessions {
            if session.questionsCorrect == session.questionsAttempted && session.questionsAttempted > 0 {
                currentStreak += 1
                bestStreak = max(bestStreak, currentStreak)
            } else {
                currentStreak = 0
            }
        }

        return bestStreak
    }

    private func calculateImprovementRate(sessions: [QuizSession]) -> Double {
        guard sessions.count >= 2 else { return 0 }

        let firstHalf = sessions.prefix(sessions.count / 2)
        let secondHalf = sessions.suffix(sessions.count / 2)

        let firstHalfAccuracy = calculateAverageAccuracy(for: Array(firstHalf))
        let secondHalfAccuracy = calculateAverageAccuracy(for: Array(secondHalf))

        guard firstHalfAccuracy > 0 else { return 0 }
        return ((secondHalfAccuracy - firstHalfAccuracy) / firstHalfAccuracy) * 100
    }

    private func calculateAverageAccuracy(for sessions: [QuizSession]) -> Double {
        guard !sessions.isEmpty else { return 0 }

        let totalQuestions = sessions.reduce(0) { $0 + $1.questionsAttempted }
        let totalCorrect = sessions.reduce(0) { $0 + $1.questionsCorrect }

        return totalQuestions > 0 ? Double(totalCorrect) / Double(totalQuestions) * 100 : 0
    }

    private func calculateTrend(sessions: [QuizSession]) -> PerformanceTrendDirection {
        guard sessions.count >= 3 else { return .stable }

        let accuracies = sessions.map { $0.accuracyPercentage }
        let recent = accuracies.suffix(3)
        let earlier = accuracies.prefix(max(1, accuracies.count - 3))

        let recentAverage = recent.reduce(0, +) / Double(recent.count)
        let earlierAverage = earlier.reduce(0, +) / Double(earlier.count)

        let difference = recentAverage - earlierAverage

        if difference > 5 { return .improving }
        if difference < -5 { return .declining }
        return .stable
    }
}
