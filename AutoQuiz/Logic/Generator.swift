//
//  Generator.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 12/06/2025.
//

import Foundation
import FoundationModels

extension String {
    func chunked(into size: Int) -> [String] {
        var chunks: [String] = []
        var currentIndex = startIndex
        
        while currentIndex < endIndex {
            let endIdx = index(currentIndex, offsetBy: size, limitedBy: endIndex) ?? endIndex
            chunks.append(String(self[currentIndex..<endIdx]))
            currentIndex = endIdx
        }
        
        return chunks
    }
}

final class Generator {
    let item: Item
    private let maxChunkSize = 3000
    
    init(item: Item) {
        self.item = item
    }
    
    private func getRandomContentChunk() -> String {
        let content = item.content
        
        if content.count <= maxChunkSize {
            return content
        }
        
        let chunks = content.chunked(into: maxChunkSize)
        return chunks.randomElement() ?? String(content.prefix(maxChunkSize))
    }
    
    func generateMultipleChoiceQuestion(_ session: LanguageModelSession) async throws -> MultipleChoiceQuestion {
        let textToPrompt = getRandomContentChunk()
        
        let response = try await session.respond(
            to: "Generate a multiple choice question with 4 choices for this content: \(textToPrompt)",
            generating: MultipleChoiceQuestion.self
        )
        
        return response.content
    }
    
    func generateTrueFalseQuestion(_ session: LanguageModelSession) async throws -> TrueFalseQuestion {
        let textToPrompt = getRandomContentChunk()
        
        let response = try await session.respond(
            to: "Generate a true or false question for this content: \(textToPrompt)",
            generating: TrueFalseQuestion.self
        )
        
        return response.content
    }
    
    func generateTitle(_ session: LanguageModelSession) async throws -> String {
        let textToPrompt = getRandomContentChunk()
        
        let response = try await session.respond(
            to: "Create a title for this content with 6 words max: \(textToPrompt)"
        )
        
        return response.content
    }
}
