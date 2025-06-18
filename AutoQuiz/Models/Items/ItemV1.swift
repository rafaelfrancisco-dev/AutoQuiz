//
//  ItemV1.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 17/06/2025.
//

import Foundation
import SwiftData

@Model
final class ItemV1 {
    var timestamp: Date
    var content: String
    var title: String?
    var questions: [MultipleChoiceQuestion]
    var trueFalseQuestions: [TrueFalseQuestion]?
    var answeredQuestions: [AnsweredQuestionV1]
    var totalPoints: Int
    
    init(timestamp: Date, content: String) {
        self.timestamp = timestamp
        self.content = content
        self.title = nil
        self.questions = []
        self.trueFalseQuestions = []
        self.answeredQuestions = []
        self.totalPoints = 0
    }
}
