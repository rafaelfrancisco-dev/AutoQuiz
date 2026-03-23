import Foundation
import NaturalLanguage
import Wax

struct NLEmbeddingProvider: EmbeddingProvider {
    var dimensions: Int { 512 }
    var normalize: Bool { true }
    var identity: EmbeddingIdentity? {
        EmbeddingIdentity(provider: "NLEmbedding", model: "sentence-en", dimensions: 512, normalized: true)
    }

    func embed(_ text: String) async throws -> [Float] {
        guard let embedding = NLEmbedding.sentenceEmbedding(for: .english),
              let vector = embedding.vector(for: text) else {
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
