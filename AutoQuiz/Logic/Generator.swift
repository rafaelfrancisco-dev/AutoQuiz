//
//  Generator.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 12/06/2025.
//

import Foundation
import FoundationModels

enum GeneratorError: Error, Equatable {
    case deviceNotEligible
    case appleIntelligenceNotEnabled
    case modelNotReady
    case unsupportedLanguageOrLocale
    case exceededContextWindowSize
    case rateLimited
    case concurrentRequests
    case generationFailed
}

extension GeneratorError {
    var isRetryable: Bool {
        switch self {
        case .modelNotReady, .rateLimited, .concurrentRequests:
            return true
        case .deviceNotEligible, .appleIntelligenceNotEnabled, .unsupportedLanguageOrLocale, .exceededContextWindowSize, .generationFailed:
            return false
        }
    }
    
    var userFacingMessage: String {
        switch self {
        case .deviceNotEligible:
            return "This device is not eligible for Apple Intelligence on-device generation."
        case .appleIntelligenceNotEnabled:
            return "Apple Intelligence is disabled. Enable it in system settings to generate questions."
        case .modelNotReady:
            return "The on-device model is still preparing. Try again in a few moments."
        case .unsupportedLanguageOrLocale:
            return "The current language or locale is not supported by the on-device model."
        case .exceededContextWindowSize:
            return "The selected content is too large for generation. Try shorter content."
        case .rateLimited:
            return "Generation is temporarily rate-limited. Retrying automatically."
        case .concurrentRequests:
            return "Another generation request is in progress. Retrying automatically."
        case .generationFailed:
            return "Question generation failed unexpectedly. Please try again."
        }
    }
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
    
    static func mapAvailability(_ availability: SystemLanguageModel.Availability) -> GeneratorError? {
        switch availability {
        case .available:
            return nil
        case .unavailable(let reason):
            switch reason {
            case .deviceNotEligible:
                return .deviceNotEligible
            case .appleIntelligenceNotEnabled:
                return .appleIntelligenceNotEnabled
            case .modelNotReady:
                return .modelNotReady
            @unknown default:
                return .generationFailed
            }
        }
    }
    
    static func mapGenerationError(_ error: LanguageModelSession.GenerationError) -> GeneratorError {
        switch error {
        case .unsupportedLanguageOrLocale:
            return .unsupportedLanguageOrLocale
        case .exceededContextWindowSize:
            return .exceededContextWindowSize
        case .rateLimited:
            return .rateLimited
        case .concurrentRequests:
            return .concurrentRequests
        default:
            return .generationFailed
        }
    }
    
    func currentAvailabilityIssue(locale: Locale = .current) -> GeneratorError? {
        if let availabilityIssue = Self.mapAvailability(model.availability) {
            return availabilityIssue
        }
        
        guard model.supportsLocale(locale) else {
            return .unsupportedLanguageOrLocale
        }
        
        return nil
    }
    
    private func createSession() throws -> LanguageModelSession {
        if let issue = currentAvailabilityIssue() {
            throw issue
        }
        
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
        let session = try createSession()
        
        let textToPrompt = getRandomContentChunk()
        do {
            let response = try await session.respond(
                to: "Generate 2-4 multiple choice questions with 4 choices each for this content: \(textToPrompt)",
                generating: MultipleChoiceQuestionBatch.self
            )
            return response.content.questions
        } catch let error as LanguageModelSession.GenerationError {
            throw Self.mapGenerationError(error)
        }
    }
    
    func generateTrueFalseQuestions() async throws -> [TrueFalseQuestion] {
        let session = try createSession()
        
        let textToPrompt = getRandomContentChunk()
        do {
            let response = try await session.respond(
                to: "Generate 2-4 true or false questions for this content: \(textToPrompt)",
                generating: TrueFalseQuestionBatch.self
            )
            return response.content.questions
        } catch let error as LanguageModelSession.GenerationError {
            throw Self.mapGenerationError(error)
        }
    }
    
    func generateTitle() async throws -> String {
        let session = try createSession()
        
        let textToPrompt = getRandomContentChunk()
        do {
            let response = try await session.respond(
                to: "Create a title for this content with 6 words max, don't add quotes: \(textToPrompt)"
            )
            return response.content
        } catch let error as LanguageModelSession.GenerationError {
            throw Self.mapGenerationError(error)
        }
    }
}
