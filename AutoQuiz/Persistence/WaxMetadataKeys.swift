import Foundation

enum WaxMetadataKeys {
    static let entityType = "aq.entity.type"
    static let entityID = "aq.entity.id"
    static let itemID = "aq.item.id"
    static let contentRevision = "aq.content.revision"
    static let chunkDocumentID = "aq.chunk.documentID"
    static let chunkRevision = "aq.chunk.revision"
    static let chunkEmbeddingLanguage = "aq.chunk.embeddingLanguage"
}

enum WaxEntityType: String, Codable {
    case item = "item"
    case answeredQuestion = "answered_question"
    case quizSession = "quiz_session"
    case spacedRepetitionCard = "spaced_card"
    case documentQuestionAnswer = "document_question_answer"
}
