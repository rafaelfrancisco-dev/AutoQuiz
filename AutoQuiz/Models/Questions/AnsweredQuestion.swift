//
//  AnsweredQuestion.swift
//  AutoQuiz
//

import Foundation

struct AnsweredQuestion: Codable, Identifiable, Hashable {
    var id: UUID
    var itemID: UUID
    var timestamp: Date
    var questionText: String
    var userAnswer: String
    var correctAnswer: String
    var isCorrect: Bool
    var pointsEarned: Int
    var questionType: Question
    var sourceContentRevision: Int

    init(
        id: UUID = UUID(),
        itemID: UUID,
        questionText: String,
        userAnswer: String,
        correctAnswer: String,
        isCorrect: Bool,
        pointsEarned: Int,
        questionType: Question,
        sourceContentRevision: Int = ContentRevisionPolicy.initialRevision
    ) {
        self.id = id
        self.itemID = itemID
        self.timestamp = Date()
        self.questionText = questionText
        self.userAnswer = userAnswer
        self.correctAnswer = correctAnswer
        self.isCorrect = isCorrect
        self.pointsEarned = pointsEarned
        self.questionType = questionType
        self.sourceContentRevision = ContentRevisionPolicy.normalized(sourceContentRevision)
    }
}
