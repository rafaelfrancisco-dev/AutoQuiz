import Foundation

final class DocumentQuestionAnswer: Identifiable, Codable, Hashable {
    enum ResponseKind: String, Codable {
        case answered
        case insufficientDocumentContent
    }

    var id: UUID
    var documentID: UUID
    var question: String
    var answer: String
    var responseKind: ResponseKind
    var timestamp: Date
    var sourceContentRevision: Int

    init(
        id: UUID = UUID(),
        documentID: UUID,
        question: String,
        answer: String,
        responseKind: ResponseKind,
        timestamp: Date = .now,
        sourceContentRevision: Int
    ) {
        self.id = id
        self.documentID = documentID
        self.question = question
        self.answer = answer
        self.responseKind = responseKind
        self.timestamp = timestamp
        self.sourceContentRevision = sourceContentRevision
    }

    static func == (lhs: DocumentQuestionAnswer, rhs: DocumentQuestionAnswer) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
