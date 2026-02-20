//
//  SpacedRepetitionCard.swift
//  AutoQuiz
//

import Foundation

final class SpacedRepetitionCard: Identifiable, Codable, Hashable {
    var id: UUID
    var timestamp: Date
    var questionText: String
    var answerText: String
    var questionType: Question
    var originalQuestionData: Data
    var sourceContentRevision: Int

    var repetitionNumber: Int
    var easinessFactor: Double
    var intervalDays: Int
    var nextReviewDate: Date
    var isLearning: Bool
    var consecutiveCorrectAnswers: Int

    var totalReviews: Int
    var correctReviews: Int
    var lastReviewDate: Date?
    var averageResponseTime: TimeInterval

    var documentID: UUID?

    init(
        id: UUID = UUID(),
        questionText: String,
        answerText: String,
        questionType: Question,
        originalQuestionData: Data,
        documentID: UUID? = nil,
        sourceContentRevision: Int = ContentRevisionPolicy.initialRevision
    ) {
        self.id = id
        self.timestamp = Date()
        self.questionText = questionText
        self.answerText = answerText
        self.questionType = questionType
        self.originalQuestionData = originalQuestionData
        self.sourceContentRevision = ContentRevisionPolicy.normalized(sourceContentRevision)
        self.documentID = documentID

        self.repetitionNumber = 0
        self.easinessFactor = 2.5
        self.intervalDays = 1
        self.nextReviewDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        self.isLearning = true
        self.consecutiveCorrectAnswers = 0

        self.totalReviews = 0
        self.correctReviews = 0
        self.lastReviewDate = nil
        self.averageResponseTime = 0
    }

    func review(quality: Int, responseTime: TimeInterval) {
        let wasCorrect = quality >= 3

        totalReviews += 1
        if wasCorrect {
            correctReviews += 1
            consecutiveCorrectAnswers += 1
        } else {
            consecutiveCorrectAnswers = 0
        }

        lastReviewDate = Date()

        if totalReviews == 1 {
            averageResponseTime = responseTime
        } else {
            averageResponseTime = (averageResponseTime * Double(totalReviews - 1) + responseTime) / Double(totalReviews)
        }

        updateSpacedRepetitionParameters(quality: quality)
    }

    private func updateSpacedRepetitionParameters(quality: Int) {
        if quality >= 3 {
            if repetitionNumber == 0 {
                intervalDays = 1
            } else if repetitionNumber == 1 {
                intervalDays = 6
            } else {
                intervalDays = Int(Double(intervalDays) * easinessFactor)
            }
            repetitionNumber += 1

            if isLearning && consecutiveCorrectAnswers >= 2 {
                isLearning = false
            }
        } else {
            repetitionNumber = 0
            intervalDays = 1
            isLearning = true
            consecutiveCorrectAnswers = 0
        }

        let qualityDiff = Double(5 - quality)
        let qualityComponent = qualityDiff * 0.02
        let innerComponent = 0.08 + qualityComponent
        let outerComponent = qualityDiff * innerComponent
        let newEF = easinessFactor + (0.1 - outerComponent)
        easinessFactor = max(1.3, newEF)

        nextReviewDate = Calendar.current.date(byAdding: .day, value: intervalDays, to: Date()) ?? Date()
    }

    var isDue: Bool {
        Date() >= nextReviewDate
    }

    var difficultyLevel: DifficultyLevel {
        switch easinessFactor {
        case 2.5...: return .easy
        case 2.0..<2.5: return .medium
        case 1.7..<2.0: return .hard
        default: return .veryHard
        }
    }

    var accuracyPercentage: Double {
        guard totalReviews > 0 else { return 0 }
        return (Double(correctReviews) / Double(totalReviews)) * 100
    }

    var daysUntilNextReview: Int {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Date(), to: nextReviewDate).day ?? 0
        return max(0, days)
    }

    static func == (lhs: SpacedRepetitionCard, rhs: SpacedRepetitionCard) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
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
