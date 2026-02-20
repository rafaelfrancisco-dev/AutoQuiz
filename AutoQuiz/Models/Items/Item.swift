//
//  Item.swift
//  AutoQuiz
//

import Foundation

final class Item: Identifiable, Codable, Hashable {
    var id: UUID
    var timestamp: Date
    var content: String
    var title: String?
    var questions: [MultipleChoiceQuestion]
    var trueFalseQuestions: [TrueFalseQuestion]?
    var answeredQuestions: [AnsweredQuestion]
    var preferredFallbackLanguageIdentifier: String?
    var contentRevision: Int
    var contentRevisionUpdatedAt: Date

    init(
        id: UUID = UUID(),
        timestamp: Date,
        content: String,
        contentRevision: Int = ContentRevisionPolicy.initialRevision,
        contentRevisionUpdatedAt: Date = .now
    ) {
        self.id = id
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

    static func == (lhs: Item, rhs: Item) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
