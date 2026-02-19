//
//  GeneratorErrorMappingTests.swift
//  AutoQuizTests
//
//  Created by Codex on 19/02/2026.
//

import Testing
import FoundationModels
@testable import AutoQuiz

struct GeneratorErrorMappingTests {
    @Test
    func availabilityIsMappedToGeneratorErrors() {
        #expect(Generator.mapAvailability(.available) == nil)
        #expect(Generator.mapAvailability(.unavailable(.deviceNotEligible)) == .deviceNotEligible)
        #expect(Generator.mapAvailability(.unavailable(.appleIntelligenceNotEnabled)) == .appleIntelligenceNotEnabled)
        #expect(Generator.mapAvailability(.unavailable(.modelNotReady)) == .modelNotReady)
    }
    
    @Test
    func generationErrorsAreMappedWithRetryability() {
        let context = LanguageModelSession.GenerationError.Context(debugDescription: "test")
        
        let unsupported = Generator.mapGenerationError(.unsupportedLanguageOrLocale(context))
        #expect(unsupported == .unsupportedLanguageOrLocale)
        #expect(unsupported.isRetryable == false)
        
        let exceededContext = Generator.mapGenerationError(.exceededContextWindowSize(context))
        #expect(exceededContext == .exceededContextWindowSize)
        #expect(exceededContext.isRetryable == false)
        
        let rateLimited = Generator.mapGenerationError(.rateLimited(context))
        #expect(rateLimited == .rateLimited)
        #expect(rateLimited.isRetryable)
        
        let concurrentRequests = Generator.mapGenerationError(.concurrentRequests(context))
        #expect(concurrentRequests == .concurrentRequests)
        #expect(concurrentRequests.isRetryable)
    }
}
