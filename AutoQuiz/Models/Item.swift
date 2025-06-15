//
//  Item.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 10/06/2025.
//

import Foundation
import SwiftData

enum QuestionType: String, CaseIterable, Codable {
    case multipleChoice = "Multiple Choice"
    case trueFalse = "True/False"
}

enum Question: Codable {
    case multipleChoice(MultipleChoiceQuestion)
    case trueFalse(TrueFalseQuestion)
}

@Model
final class Item {
    var timestamp: Date
    var content: String
    var title: String?
    var questions: [MultipleChoiceQuestion]
    var trueFalseQuestions: [TrueFalseQuestion]?
    
    init(timestamp: Date, content: String) {
        self.timestamp = timestamp
        self.content = content
        self.title = nil
        self.questions = []
        self.trueFalseQuestions = []
    }
    
    var safeTrueFalseQuestions: [TrueFalseQuestion] {
        return trueFalseQuestions ?? []
    }
}
