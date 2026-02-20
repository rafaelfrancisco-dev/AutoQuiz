//
//  ItemV3.swift
//  AutoQuiz
//
//  Created by Codex on 20/02/2026.
//

import Foundation
import SwiftData

@Model
final class ItemV3 {
    var timestamp: Date
    var content: String
    var title: String?
    var questions: [MultipleChoiceQuestion]
    var trueFalseQuestions: [TrueFalseQuestion]?
    var answeredQuestions: [AnsweredQuestionV1]
    var preferredFallbackLanguageIdentifier: String?
    // Note: totalPoints removed - points are now only tracked during quiz sessions
    
    init(timestamp: Date, content: String) {
        self.timestamp = timestamp
        self.content = content
        self.title = nil
        self.questions = []
        self.trueFalseQuestions = []
        self.answeredQuestions = []
        self.preferredFallbackLanguageIdentifier = nil
    }
}
