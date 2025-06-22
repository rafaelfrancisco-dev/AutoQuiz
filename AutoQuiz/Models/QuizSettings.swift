//
//  QuizSettings.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 18/06/2025.
//

import Foundation

enum QuizQuestion {
    case multipleChoice(MultipleChoiceQuestion, originalIndex: Int)
    case trueFalse(TrueFalseQuestion, originalIndex: Int)
    case spacedRepetition(SpacedRepetitionCard)
    
    var questionText: String {
        switch self {
        case .multipleChoice(let question, _):
            return question.question
        case .trueFalse(let question, _):
            return question.question
        case .spacedRepetition(let card):
            return card.questionText
        }
    }
    
    var originalIndex: Int {
        switch self {
        case .multipleChoice(_, let index):
            return index
        case .trueFalse(_, let index):
            return index
        case .spacedRepetition(_):
            return 0 // Spaced repetition doesn't use original index
        }
    }
}

struct QuizSettings {
    // MARK: - Question Configuration
    var questionType: Question = .multipleChoice
    var maxQuestions: Int = 10
    
    // MARK: - Retry Configuration
    var includeFailedQuestions: Bool = false
    var shuffleQuestions: Bool = true
    
    // MARK: - Language Configuration
    var useOriginalLanguage: Bool = true
    
    // MARK: - Difficulty Configuration
    var allowSkipQuestions: Bool = false
    
    // MARK: - Default Settings
    static let `default` = QuizSettings()
    
    // MARK: - Validation
    var isValid: Bool {
        maxQuestions > 0 && maxQuestions <= 50
    }
}

extension QuizSettings {
    // MARK: - Helper Methods
    var maxQuestionsDescription: String {
        if maxQuestions == Int.max {
            return "Unlimited"
        }
        return "\(maxQuestions)"
    }
    
    mutating func setUnlimitedQuestions() {
        maxQuestions = Int.max
    }
    
    var isUnlimitedQuestions: Bool {
        maxQuestions == Int.max
    }
}