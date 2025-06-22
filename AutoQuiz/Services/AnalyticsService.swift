//
//  AnalyticsService.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 18/06/2025.
//

import Foundation
import SwiftData
import OSLog

@Observable
final class AnalyticsService {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Overview Analytics
    
    func getPerformanceOverview(for timeRange: TimeRange, document: Item? = nil) -> PerformanceOverview {
        let sessions = getSessions(for: timeRange, document: document)
        
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
    
    // MARK: - Trend Analysis
    
    func getAccuracyTrend(for timeRange: TimeRange, document: Item? = nil) -> [AccuracyTrend] {
        let sessions = getSessions(for: timeRange, document: document)
        
        // Group sessions by day
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
    
    // MARK: - Session Type Analysis
    
    func getSessionTypeMetrics(for timeRange: TimeRange, document: Item? = nil) -> [SessionTypeMetrics] {
        let sessions = getSessions(for: timeRange, document: document)
        
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
    
    // MARK: - Learning Progress
    
    func getLearningProgress(for timeRange: TimeRange, document: Item? = nil) -> LearningProgress {
        let sessions = getSessions(for: timeRange, document: document)
        let recentSessions = sessions.suffix(10) // Last 10 sessions for trend analysis
        
        let currentStreak = calculateCurrentStreak(sessions: sessions)
        let bestStreak = calculateBestStreak(for: sessions)
        let improvementRate = calculateImprovementRate(sessions: sessions)
        let trend = calculateTrend(sessions: Array(recentSessions))
        
        return LearningProgress(
            currentStreak: currentStreak,
            bestStreak: bestStreak,
            improvementRate: improvementRate,
            weakestAreas: [], // Could be enhanced with topic analysis
            strongestAreas: [], // Could be enhanced with topic analysis
            recentPerformanceTrend: trend
        )
    }
    
    // MARK: - Time Range Metrics
    
    func getTimeRangeMetrics(for timeRange: TimeRange, document: Item? = nil) -> TimeRangeMetrics {
        let sessions = getSessions(for: timeRange, document: document)
        let overview = getPerformanceOverview(for: timeRange, document: document)
        let accuracyTrend = getAccuracyTrend(for: timeRange, document: document)
        let sessionTypeBreakdown = getSessionTypeMetrics(for: timeRange, document: document)
        
        return TimeRangeMetrics(
            timeRange: timeRange,
            sessions: sessions,
            overview: overview,
            accuracyTrend: accuracyTrend,
            sessionTypeBreakdown: sessionTypeBreakdown
        )
    }
    
    // MARK: - Private Helper Methods
    
    private func getSessions(for timeRange: TimeRange, document: Item? = nil) -> [QuizSession] {
        let dateRange = timeRange.dateRange
        
        let descriptor = FetchDescriptor<QuizSession>(
            sortBy: [SortDescriptor(\.startTime)]
        )
        
        do {
            let allSessions = try modelContext.fetch(descriptor)
            
            return allSessions.filter { session in
                let inTimeRange = session.startTime >= dateRange.start && session.startTime <= dateRange.end
                
                if let document = document {
                    return inTimeRange && session.document.id == document.id
                } else {
                    return inTimeRange
                }
            }
        } catch {
            Logger.error.error("Failed to fetch quiz sessions: \(error)")
            return []
        }
    }
    
    private func calculateCurrentStreak(sessions: [QuizSession]) -> Int {
        let recentSessions = sessions.suffix(50).reversed() // Check last 50 sessions
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
        
        if difference > 5 {
            return .improving
        } else if difference < -5 {
            return .declining
        } else {
            return .stable
        }
    }
}