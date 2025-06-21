//
//  PerformanceMetrics.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 18/06/2025.
//

import Foundation

// MARK: - Performance Analytics Structures

struct PerformanceOverview {
    let totalSessions: Int
    let completedSessions: Int
    let totalQuestionsAnswered: Int
    let totalCorrectAnswers: Int
    let totalPointsEarned: Int
    let averageSessionDuration: TimeInterval
    let overallAccuracy: Double
    let completionRate: Double
    
    static let empty = PerformanceOverview(
        totalSessions: 0,
        completedSessions: 0,
        totalQuestionsAnswered: 0,
        totalCorrectAnswers: 0,
        totalPointsEarned: 0,
        averageSessionDuration: 0,
        overallAccuracy: 0,
        completionRate: 0
    )
}

struct AccuracyTrend {
    let date: Date
    let accuracy: Double
    let questionsCount: Int
}

struct SessionTypeMetrics {
    let questionType: Question
    let sessionCount: Int
    let averageAccuracy: Double
    let averageResponseTime: TimeInterval
    let totalQuestions: Int
    let bestStreak: Int
}

struct TimeRangeMetrics {
    let timeRange: TimeRange
    let sessions: [QuizSession]
    let overview: PerformanceOverview
    let accuracyTrend: [AccuracyTrend]
    let sessionTypeBreakdown: [SessionTypeMetrics]
}

struct LearningProgress {
    let currentStreak: Int
    let bestStreak: Int
    let improvementRate: Double // Percentage improvement over time
    let weakestAreas: [String] // Question types or topics with low accuracy
    let strongestAreas: [String]
    let recentPerformanceTrend: PerformanceTrendDirection
}

enum PerformanceTrendDirection {
    case improving
    case declining
    case stable
    
    var displayName: String {
        switch self {
        case .improving: return "Improving"
        case .declining: return "Needs Focus"
        case .stable: return "Consistent"
        }
    }
    
    var color: String {
        switch self {
        case .improving: return "green"
        case .declining: return "red" 
        case .stable: return "blue"
        }
    }
}

enum TimeRange: String, CaseIterable {
    case today = "today"
    case thisWeek = "this_week"
    case thisMonth = "this_month"
    case allTime = "all_time"
    
    var displayName: String {
        switch self {
        case .today: return "Today"
        case .thisWeek: return "This Week"
        case .thisMonth: return "This Month"
        case .allTime: return "All Time"
        }
    }
    
    var dateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .today:
            let startOfDay = calendar.startOfDay(for: now)
            return (startOfDay, now)
            
        case .thisWeek:
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            return (startOfWeek, now)
            
        case .thisMonth:
            let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
            return (startOfMonth, now)
            
        case .allTime:
            return (Date.distantPast, now)
        }
    }
}

// MARK: - Achievement System (Optional Enhancement)

struct Achievement {
    let id: String
    let title: String
    let description: String
    let iconName: String
    let isUnlocked: Bool
    let unlockedDate: Date?
    let progress: Double // 0.0 to 1.0
    let target: Int
    let current: Int
    
    static let achievements: [Achievement] = [
        Achievement(
            id: "first_quiz",
            title: "Getting Started",
            description: "Complete your first quiz",
            iconName: "star.fill",
            isUnlocked: false,
            unlockedDate: nil,
            progress: 0,
            target: 1,
            current: 0
        ),
        Achievement(
            id: "perfect_session",
            title: "Perfect Score",
            description: "Get 100% accuracy in a quiz session",
            iconName: "crown.fill",
            isUnlocked: false,
            unlockedDate: nil,
            progress: 0,
            target: 1,
            current: 0
        ),
        Achievement(
            id: "speed_demon",
            title: "Speed Demon",
            description: "Answer 10 questions in under 60 seconds",
            iconName: "bolt.fill",
            isUnlocked: false,
            unlockedDate: nil,
            progress: 0,
            target: 10,
            current: 0
        ),
        Achievement(
            id: "streak_master",
            title: "Streak Master",
            description: "Get 20 correct answers in a row",
            iconName: "flame.fill",
            isUnlocked: false,
            unlockedDate: nil,
            progress: 0,
            target: 20,
            current: 0
        )
    ]
}