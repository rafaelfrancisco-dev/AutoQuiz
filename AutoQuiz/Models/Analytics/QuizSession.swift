//
//  QuizSession.swift
//  AutoQuiz
//

import Foundation

final class QuizSession: Identifiable, Codable, Hashable {
    var id: UUID
    var documentID: UUID
    var sourceContentRevision: Int
    var startTime: Date
    var endTime: Date?
    var isCompleted: Bool
    var questionType: Question
    var maxQuestions: Int
    var isUnlimitedQuestions: Bool
    var shuffleQuestions: Bool
    var includeFailedQuestions: Bool
    var questionsAttempted: Int
    var questionsCorrect: Int
    var totalPointsEarned: Int
    var averageResponseTime: TimeInterval
    var questionResponses: [String]

    var duration: TimeInterval? {
        guard let endTime else { return nil }
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

    init(
        id: UUID = UUID(),
        documentID: UUID,
        questionType: Question,
        maxQuestions: Int,
        isUnlimitedQuestions: Bool,
        shuffleQuestions: Bool,
        includeFailedQuestions: Bool,
        sourceContentRevision: Int = ContentRevisionPolicy.initialRevision
    ) {
        self.id = id
        self.documentID = documentID
        self.sourceContentRevision = ContentRevisionPolicy.normalized(sourceContentRevision)
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

    static func == (lhs: QuizSession, rhs: QuizSession) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
