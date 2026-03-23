import Foundation
import NaturalLanguage
import Wax

struct NLEmbeddingProvider: EmbeddingProvider {
    var dimensions: Int { 512 }
    var normalize: Bool { true }
    var identity: EmbeddingIdentity? {
        EmbeddingIdentity(provider: "NLEmbedding", model: "sentence-multilingual", dimensions: 512, normalized: true)
    }

    func embed(_ text: String) async throws -> [Float] {
        let detectedLanguage = NLLanguageRecognizer.dominantLanguage(for: text) ?? .english
        return try await embed(text, language: detectedLanguage)
    }

    func embed(_ text: String, language: NLLanguage) async throws -> [Float] {
        let embedding = NLEmbedding.sentenceEmbedding(for: language) ?? NLEmbedding.sentenceEmbedding(for: .english)
        guard let embedding, let vector = embedding.vector(for: text) else {
            throw EmbeddingError.unavailable
        }
        var floats = vector.map(Float.init)
        let norm = sqrt(floats.reduce(0) { $0 + $1 * $1 })
        if norm > 0 { floats = floats.map { $0 / norm } }
        return floats
    }

    enum EmbeddingError: Error {
        case unavailable
    }
}
