//
//  Generator.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 12/06/2025.
//

import Foundation
import FoundationModels
import NaturalLanguage
import OSLog

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

@Generable(description: "A document-grounded answer to a user's question")
struct DocumentAnswerPayload: Codable {
    @Guide(description: "True when the provided document excerpts contain enough information to answer the question without outside knowledge.")
    let isAnswerSupportedByDocument: Bool

    @Guide(description: "A concise answer based only on the document excerpts. If the excerpts are insufficient, explain briefly that the document does not contain the answer.")
    let answer: String
}

struct DocumentAnswerResult {
    let answer: String
    let responseKind: DocumentQuestionAnswer.ResponseKind
}

final class Generator {
    enum QuizGenerationLanguageMode: Equatable {
        case detectedDocumentLanguage
        case appLocale(Locale)
        case specificLanguage(Locale.Language)
    }
    
    enum GenerationLanguageResolution: Equatable {
        case resolved(Locale.Language)
        case requiresUserSelection([Locale.Language])
    }
    
    let item: Item
    private let model = SystemLanguageModel.default
    
    private let maxChunkSize = 3500
    private let maxDocumentAnswerChunkSize = 2500
    private let maxDocumentAnswerChunkCount = 3
    private let documentAnswerStopWords: Set<String> = [
        "about", "after", "before", "between", "document", "does", "from", "have",
        "into", "question", "should", "their", "there", "these", "this", "what",
        "when", "where", "which", "while", "who", "with", "would", "your"
    ]
    
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
    
    static func currentAvailabilityIssue() -> GeneratorError? {
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            return nil
        }
        return Self.mapAvailability(SystemLanguageModel.default.availability)
    }
    
    func currentAvailabilityIssue() -> GeneratorError? {
        Self.currentAvailabilityIssue()
    }
    
    func supportedLanguages() -> [Locale.Language] {
        model.supportedLanguages.sorted { $0.persistedIdentifier < $1.persistedIdentifier }
    }
    
    func resolveLanguage(mode: QuizGenerationLanguageMode) -> GenerationLanguageResolution {
        guard Self.currentAvailabilityIssue() == nil else {
            return .requiresUserSelection([])
        }
        
        let supportedLanguages = supportedLanguages()
        
        func resolvedSupportedLanguage(for language: Locale.Language) -> Locale.Language? {
            if let exactEquivalent = supportedLanguages.first(where: { $0.isEquivalent(to: language) }) {
                return exactEquivalent
            }
            
            if let exactIdentifier = supportedLanguages.first(where: {
                $0.persistedIdentifier.caseInsensitiveCompare(language.persistedIdentifier) == .orderedSame
            }) {
                return exactIdentifier
            }
            
            if let sameLanguageCode = supportedLanguages.first(where: {
                $0.displayIdentifier.caseInsensitiveCompare(language.displayIdentifier) == .orderedSame
            }) {
                return sameLanguageCode
            }
            
            return nil
        }
        
        switch mode {
        case .specificLanguage(let language):
            if let resolvedLanguage = resolvedSupportedLanguage(for: language) {
                return .resolved(resolvedLanguage)
            }
            return .requiresUserSelection(supportedLanguages)
        case .appLocale(let locale):
            if model.supportsLocale(locale) {
                if let resolvedLanguage = resolvedSupportedLanguage(for: locale.language) {
                    return .resolved(resolvedLanguage)
                }
                
                // Locale is supported via fallback, but we couldn't map it to an
                // explicit supported language entry.
                return .requiresUserSelection(supportedLanguages)
            }
            return .requiresUserSelection(supportedLanguages)
        case .detectedDocumentLanguage:
            guard let detectedLanguage = detectDocumentLanguage(in: item.content) else {
                return .requiresUserSelection(supportedLanguages)
            }
            
            if let resolvedLanguage = resolvedSupportedLanguage(for: detectedLanguage) {
                return .resolved(resolvedLanguage)
            }
            return .requiresUserSelection(supportedLanguages)
        }
    }
    
    private func resolveLanguageOrThrow(mode: QuizGenerationLanguageMode) throws -> Locale.Language {
        switch resolveLanguage(mode: mode) {
        case .resolved(let language):
            return language
        case .requiresUserSelection:
            throw GeneratorError.unsupportedLanguageOrLocale
        }
    }
    
    private func detectDocumentLanguage(in content: String) -> Locale.Language? {
        let sample = String(content.prefix(maxChunkSize))
        guard !sample.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            Logger.generation.info("Detected document language: none (empty content sample)")
            return nil
        }
        
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(sample)
        
        guard let dominantLanguage = recognizer.dominantLanguage else {
            Logger.generation.info("Detected document language: none (no dominant language)")
            return nil
        }
        
        let detectedLanguage = Locale.Language(identifier: dominantLanguage.rawValue)
        Logger.generation.info(
            "Detected document language: \(detectedLanguage.persistedIdentifier, privacy: .public)"
        )
        return detectedLanguage
    }
    
    private func createSession(language: Locale.Language) throws -> LanguageModelSession {
        if let issue = Self.currentAvailabilityIssue() {
            throw issue
        }
        
        let canonicalLocale = Locale(identifier: language.persistedIdentifier)
        let canonicalLocaleIdentifier = canonicalLocale.identifier
        
        let hasRegion = canonicalLocaleIdentifier.contains("-") || canonicalLocaleIdentifier.contains("_")
        
        let englishLocale = Locale(identifier: "en_US")
        let languageName = englishLocale.localizedString(forLanguageCode: language.displayIdentifier)
            ?? language.persistedIdentifier
        
        var instructionLines: [String] = []
        
        // Apple's guidance: locale phrase improves quality for locale variants.
        if hasRegion, canonicalLocaleIdentifier.lowercased() != "en_us" {
            instructionLines.append("The person's locale is \(canonicalLocaleIdentifier).")
        }
        
        instructionLines.append("You MUST respond in \(languageName).")
        
        let instructions = instructionLines.joined(separator: "\n")
        
        return LanguageModelSession(instructions: instructions)
    }
    
    private func getRandomContentChunk() -> String {
        let content = item.content
        
        if content.count <= maxChunkSize {
            return content
        }
        
        let chunks = content.chunked(into: maxChunkSize)
        return chunks.randomElement() ?? String(content.prefix(maxChunkSize))
    }

    private func documentKeywords(for question: String) -> Set<String> {
        Set(
            question
                .lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter {
                    $0.count >= 3 && !documentAnswerStopWords.contains($0)
                }
        )
    }

    private func rankedDocumentContext(for question: String) -> String {
        let trimmedContent = item.content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedContent.count > maxChunkSize else {
            return trimmedContent
        }

        let chunks = trimmedContent.chunked(into: maxDocumentAnswerChunkSize)
        let keywords = documentKeywords(for: question)

        let rankedChunks = chunks.enumerated().map { index, chunk in
            let lowercaseChunk = chunk.lowercased()
            let keywordScore = keywords.reduce(into: 0) { partialResult, keyword in
                if lowercaseChunk.contains(keyword) {
                    partialResult += 1
                }
            }

            let score = keywordScore == 0 ? (index == 0 ? 1 : 0) : keywordScore + 1
            return (index, chunk, score)
        }

        let selectedChunks = rankedChunks
            .sorted { lhs, rhs in
                if lhs.2 == rhs.2 {
                    return lhs.0 < rhs.0
                }
                return lhs.2 > rhs.2
            }
            .prefix(maxDocumentAnswerChunkCount)
            .sorted { $0.0 < $1.0 }

        return selectedChunks
            .map { index, chunk, _ in
                "Excerpt \(index + 1):\n\(chunk.trimmingCharacters(in: .whitespacesAndNewlines))"
            }
            .joined(separator: "\n\n")
    }
    
    func generateMultipleChoiceQuestions(languageMode: QuizGenerationLanguageMode) async throws -> [MultipleChoiceQuestion] {
        let language = try resolveLanguageOrThrow(mode: languageMode)
        let session = try createSession(language: language)
        
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
    
    func generateTrueFalseQuestions(languageMode: QuizGenerationLanguageMode) async throws -> [TrueFalseQuestion] {
        let language = try resolveLanguageOrThrow(mode: languageMode)
        let session = try createSession(language: language)
        
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
        let session = try createSession(language: .init(identifier: "en-US"))
        
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

    func answerQuestionAboutDocument(
        _ question: String,
        languageMode: QuizGenerationLanguageMode,
        preloadedChunks: [String]? = nil
    ) async throws -> DocumentAnswerResult {
        let language = try resolveLanguageOrThrow(mode: languageMode)
        let session = try createSession(language: language)

        let documentContext: String
        if let chunks = preloadedChunks, !chunks.isEmpty {
            Logger.generation.debug("Using \(chunks.count) semantic chunks for document Q&A")
            documentContext = chunks.enumerated().map { index, chunk in
                "Excerpt \(index + 1):\n\(chunk.trimmingCharacters(in: .whitespacesAndNewlines))"
            }.joined(separator: "\n\n")
        } else {
            documentContext = rankedDocumentContext(for: question)
        }

        do {
            let response = try await session.respond(
                to: """
                Answer the user's question using only the provided document excerpts.
                Do not use outside knowledge.
                If the document excerpts do not contain enough information, set isAnswerSupportedByDocument to false.
                Keep the answer concise and specific.

                Question:
                \(question)

                Document excerpts:
                \(documentContext)
                """,
                generating: DocumentAnswerPayload.self
            )

            return DocumentAnswerResult(
                answer: response.content.answer.trimmingCharacters(in: .whitespacesAndNewlines),
                responseKind: response.content.isAnswerSupportedByDocument ? .answered : .insufficientDocumentContent
            )
        } catch let error as LanguageModelSession.GenerationError {
            throw Self.mapGenerationError(error)
        }
    }
}
