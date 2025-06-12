//
//  Generator.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 12/06/2025.
//

import Foundation
import FoundationModels

final class Generator {
    let item: Item
    
    init(item: Item) {
        self.item = item
    }
    
    func generateQuestion(_ session: LanguageModelSession) async throws -> Question {
        let textToPrompt = item.content.prefix(3800)
        
        let response = try await session.respond(
            to: "Generate a multiple choice question with 4 choices for this content: \(textToPrompt)",
            generating: Question.self
        )
        
        return response.content
    }
    
    func generateTitle(_ session: LanguageModelSession) async throws -> String {
        let textToPrompt = item.content.prefix(3800)
        
        let response = try await session.respond(
            to: "Create a title for this content with 6 words max: \(textToPrompt)"
        )
        
        return response.content
    }
}
