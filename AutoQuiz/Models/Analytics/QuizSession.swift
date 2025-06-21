//
//  QuizSession.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 18/06/2025.
//

import Foundation
import SwiftData

@Model
final class QuizSession {
    // MARK: - Identity
    var id: UUID
    
    // MARK: - Relationship
    var document: Item
    
    // MARK: - Session Metadata
    var startTime: Date
    var endTime: Date?
    var isCompleted: Bool
    
    // MARK: - Quiz Configuration
    var questionType: Question
    var maxQuestions: Int
    var isUnlimitedQuestions: Bool
    var shuffleQuestions: Bool
    var includeFailedQuestions: Bool
    
    // MARK: - Performance Metrics
    var questionsAttempted: Int
    var questionsCorrect: Int
    var totalPointsEarned: Int
    var averageResponseTime: TimeInterval // Average time per question in seconds
    
    // MARK: - Question Details
    var questionResponses: [String] // Array of question IDs/texts for this session
    
    // MARK: - Computed Properties
    var duration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }
    
    var accuracyPercentage: Double {
        guard questionsAttempted > 0 else { return 0 }
        return Double(questionsCorrect) / Double(questionsAttempted) * 100
    }
    
    var completionRate: Double {
        guard maxQuestions > 0 && !isUnlimitedQuestions else { return isCompleted ? 1.0 : 0.0 }
        return Double(questionsAttempted) / Double(maxQuestions)
    }
    
    // MARK: - Initialization
    init(
        document: Item,
        questionType: Question,
        maxQuestions: Int,
        isUnlimitedQuestions: Bool,
        shuffleQuestions: Bool,
        includeFailedQuestions: Bool
    ) {
        self.id = UUID()
        self.document = document
        self.startTime = Date()
        self.endTime = nil
        self.isCompleted = false
        
        self.questionType = questionType
        self.maxQuestions = maxQuestions
        self.isUnlimitedQuestions = isUnlimitedQuestions
        self.shuffleQuestions = shuffleQuestions
        self.includeFailedQuestions = includeFailedQuestions
        
        self.questionsAttempted = 0
        self.questionsCorrect = 0
        self.totalPointsEarned = 0
        self.averageResponseTime = 0
        self.questionResponses = []
    }
    
    // MARK: - Session Management
    func recordQuestionResponse(
        questionText: String,
        isCorrect: Bool,
        pointsEarned: Int,
        responseTime: TimeInterval
    ) {
        questionsAttempted += 1
        if isCorrect {
            questionsCorrect += 1
        }
        totalPointsEarned += pointsEarned
        questionResponses.append(questionText)
        
        // Update average response time
        let totalTime = averageResponseTime * Double(questionsAttempted - 1) + responseTime
        averageResponseTime = totalTime / Double(questionsAttempted)
    }
    
    func completeSession() {
        endTime = Date()
        isCompleted = true
    }
    
    func abandonSession() {
        endTime = Date()
        isCompleted = false
    }
}