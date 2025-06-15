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
    
    func generateMultipleChoiceQuestion(_ session: LanguageModelSession) async throws -> MultipleChoiceQuestion {
        let textToPrompt = item.content.prefix(3800)
        
        let response = try await session.respond(
            to: "Generate a multiple choice question with 4 choices for this content: \(textToPrompt)",
            generating: MultipleChoiceQuestion.self
        )
        
        return response.content
    }
    
    func generateTrueFalseQuestion(_ session: LanguageModelSession) async throws -> TrueFalseQuestion {
        let textToPrompt = item.content.prefix(3800)
        
        let response = try await session.respond(
            to: "Generate a true or false question for this content: \(textToPrompt)",
            generating: TrueFalseQuestion.self
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
