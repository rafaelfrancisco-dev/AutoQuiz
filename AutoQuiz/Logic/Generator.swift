//
//  Generator.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 12/06/2025.
//

import Foundation
import FoundationModels

enum GeneratorError: Error {
    case sessionUnavailable
}

@Generable(description: "Multiple multiple choice questions")
struct MultipleChoiceQuestionBatch: Codable {
    @Guide(description: "An array of 2-4 multiple choice questions")
    let questions: [MultipleChoiceQuestion]
}

@Generable(description: "Multiple true or false questions")
struct TrueFalseQuestionBatch: Codable {
    @Guide(description: "An array of 2-4 true or false questions")
    let questions: [TrueFalseQuestion]
}

final class Generator {
    let item: Item
    private let model = SystemLanguageModel.default
    
    private let maxChunkSize = 3500
    
    init(item: Item) {
        self.item = item
    }
    
    private func createSession() -> LanguageModelSession? {
        guard model.availability == .available else { return nil }
        return LanguageModelSession(instructions: "Always answer in English (en-US).")
    }
    
    private func getRandomContentChunk() -> String {
        let content = item.content
        
        if content.count <= maxChunkSize {
            return content
        }
        
        let chunks = content.chunked(into: maxChunkSize)
        return chunks.randomElement() ?? String(content.prefix(maxChunkSize))
    }
    
    func generateMultipleChoiceQuestions() async throws -> [MultipleChoiceQuestion] {
        guard let session = createSession() else {
            throw GeneratorError.sessionUnavailable
        }
        
        let textToPrompt = getRandomContentChunk()
        
        let response = try await session.respond(
            to: "Generate 2-4 multiple choice questions with 4 choices each for this content: \(textToPrompt)",
            generating: MultipleChoiceQuestionBatch.self
        )
        
        return response.content.questions
    }
    
    func generateTrueFalseQuestions() async throws -> [TrueFalseQuestion] {
        guard let session = createSession() else {
            throw GeneratorError.sessionUnavailable
        }
        
        let textToPrompt = getRandomContentChunk()
        
        let response = try await session.respond(
            to: "Generate 2-4 true or false questions for this content: \(textToPrompt)",
            generating: TrueFalseQuestionBatch.self
        )
        
        return response.content.questions
    }
    
    func generateTitle() async throws -> String {
        guard let session = createSession() else {
            throw GeneratorError.sessionUnavailable
        }
        
        let textToPrompt = getRandomContentChunk()
        
        let response = try await session.respond(
            to: "Create a title for this content with 6 words max: \(textToPrompt)"
        )
        
        return response.content
    }
}
