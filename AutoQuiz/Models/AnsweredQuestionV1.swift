//
//  AnsweredQuestion.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 15/06/2025.
//

import Foundation
import SwiftData

@Model
final class AnsweredQuestionV1 {
    var timestamp: Date
    var questionText: String
    var userAnswer: String
    var correctAnswer: String
    var isCorrect: Bool
    var pointsEarned: Int
    var questionType: Question
    
    init(
        questionText: String,
        userAnswer: String,
        correctAnswer: String,
        isCorrect: Bool,
        pointsEarned: Int,
        questionType: Question
    ) {
        self.timestamp = Date()
        
        self.questionText = questionText
        self.userAnswer = userAnswer
        self.correctAnswer = correctAnswer
        self.isCorrect = isCorrect
        self.pointsEarned = pointsEarned
        self.questionType = questionType
    }
}
