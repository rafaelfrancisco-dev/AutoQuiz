//
//  SpacedRepetitionCard.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 22/06/2025.
//

import Foundation
import SwiftData

@Model
final class SpacedRepetitionCard {
    var timestamp: Date
    var questionText: String
    var answerText: String
    var questionType: Question  // Original question type (multipleChoice or trueFalse)
    var originalQuestionData: Data  // Serialized original question for reference
    
    // Spaced repetition algorithm properties
    var repetitionNumber: Int
    var easinessFactor: Double
    var intervalDays: Int
    var nextReviewDate: Date
    var isLearning: Bool
    var consecutiveCorrectAnswers: Int
    
    // Performance tracking
    var totalReviews: Int
    var correctReviews: Int
    var lastReviewDate: Date?
    var averageResponseTime: TimeInterval
    
    // Relationships
    var document: Item?
    
    init(
        questionText: String,
        answerText: String,
        questionType: Question,
        originalQuestionData: Data,
        document: Item? = nil
    ) {
        self.timestamp = Date()
        self.questionText = questionText
        self.answerText = answerText
        self.questionType = questionType
        self.originalQuestionData = originalQuestionData
        self.document = document
        
        // Initialize spaced repetition algorithm with defaults (SM-2 algorithm)
        self.repetitionNumber = 0
        self.easinessFactor = 2.5  // Default easiness factor
        self.intervalDays = 1      // First review after 1 day
        self.nextReviewDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        self.isLearning = true     // Card is in learning phase
        self.consecutiveCorrectAnswers = 0
        
        // Initialize performance tracking
        self.totalReviews = 0
        self.correctReviews = 0
        self.lastReviewDate = nil
        self.averageResponseTime = 0
    }
}

// MARK: - Spaced Repetition Algorithm Extensions

extension SpacedRepetitionCard {
    /// Reviews the card and updates spaced repetition parameters based on performance
    /// - Parameters:
    ///   - quality: Quality of response (0-5, where 3+ is considered correct)
    ///   - responseTime: Time taken to answer in seconds
    func review(quality: Int, responseTime: TimeInterval) {
        let wasCorrect = quality >= 3
        
        // Update performance tracking
        totalReviews += 1
        if wasCorrect {
            correctReviews += 1
            consecutiveCorrectAnswers += 1
        } else {
            consecutiveCorrectAnswers = 0
        }
        
        lastReviewDate = Date()
        
        // Update average response time
        if totalReviews == 1 {
            averageResponseTime = responseTime
        } else {
            averageResponseTime = (averageResponseTime * Double(totalReviews - 1) + responseTime) / Double(totalReviews)
        }
        
        // Apply SM-2 algorithm
        updateSpacedRepetitionParameters(quality: quality)
    }
    
    private func updateSpacedRepetitionParameters(quality: Int) {
        // SM-2 Algorithm implementation
        if quality >= 3 {
            // Correct answer
            if repetitionNumber == 0 {
                intervalDays = 1
            } else if repetitionNumber == 1 {
                intervalDays = 6
            } else {
                intervalDays = Int(Double(intervalDays) * easinessFactor)
            }
            repetitionNumber += 1
            
            // Graduation from learning phase
            if isLearning && consecutiveCorrectAnswers >= 2 {
                isLearning = false
            }
        } else {
            // Incorrect answer - reset to learning phase
            repetitionNumber = 0
            intervalDays = 1
            isLearning = true
            consecutiveCorrectAnswers = 0
        }
        
        // Update easiness factor based on quality
        let qualityDiff = Double(5 - quality)
        let qualityComponent = qualityDiff * 0.02
        let innerComponent = 0.08 + qualityComponent
        let outerComponent = qualityDiff * innerComponent
        let newEF = easinessFactor + (0.1 - outerComponent)
        easinessFactor = max(1.3, newEF)  // Minimum easiness factor is 1.3
        
        // Calculate next review date
        nextReviewDate = Calendar.current.date(byAdding: .day, value: intervalDays, to: Date()) ?? Date()
    }
    
    /// Checks if this card is due for review
    var isDue: Bool {
        Date() >= nextReviewDate
    }
    
    /// Returns the difficulty level based on easiness factor
    var difficultyLevel: DifficultyLevel {
        switch easinessFactor {
        case 2.5...: return .easy
        case 2.0..<2.5: return .medium
        case 1.7..<2.0: return .hard
        default: return .veryHard
        }
    }
    
    /// Returns the accuracy percentage for this card
    var accuracyPercentage: Double {
        guard totalReviews > 0 else { return 0 }
        return (Double(correctReviews) / Double(totalReviews)) * 100
    }
    
    /// Returns days until next review
    var daysUntilNextReview: Int {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Date(), to: nextReviewDate).day ?? 0
        return max(0, days)
    }
}

enum DifficultyLevel: String, CaseIterable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    case veryHard = "Very Hard"
    
    var color: String {
        switch self {
        case .easy: return "green"
        case .medium: return "yellow"
        case .hard: return "orange"
        case .veryHard: return "red"
        }
    }
}