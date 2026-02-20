//
//  ItemV4.swift
//  AutoQuiz
//
//  Created by Codex on 20/02/2026.
//

import Foundation
import SwiftData

@Model
final class ItemV4 {
    var timestamp: Date
    var content: String
    var title: String?
    var questions: [MultipleChoiceQuestion]
    var trueFalseQuestions: [TrueFalseQuestion]?
    var answeredQuestions: [AnsweredQuestion]
    var preferredFallbackLanguageIdentifier: String?
    var contentRevision: Int
    var contentRevisionUpdatedAt: Date
    // Note: totalPoints removed - points are now only tracked during quiz sessions

    init(
        timestamp: Date,
        content: String,
        contentRevision: Int = ContentRevisionPolicy.initialRevision,
        contentRevisionUpdatedAt: Date = .now
    ) {
        self.timestamp = timestamp
        self.content = content
        self.title = nil
        self.questions = []
        self.trueFalseQuestions = []
        self.answeredQuestions = []
        self.preferredFallbackLanguageIdentifier = nil
        self.contentRevision = ContentRevisionPolicy.normalized(contentRevision)
        self.contentRevisionUpdatedAt = contentRevisionUpdatedAt
    }
}
