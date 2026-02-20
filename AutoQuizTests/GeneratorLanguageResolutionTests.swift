//
//  GeneratorLanguageResolutionTests.swift
//  AutoQuizTests
//
//  Created by Codex on 20/02/2026.
//

import Testing
import Foundation
@testable import AutoQuiz

struct GeneratorLanguageResolutionTests {
    @Test
    func unsupportedSpecificLanguageRequiresSelection() {
        let item = Item(timestamp: .now, content: "Bonjour le monde")
        let generator = Generator(item: item)
        
        let resolution = generator.resolveLanguage(mode: .specificLanguage(.init(identifier: "zz-ZZ")))
        
        let requiresSelection: Bool
        if case .requiresUserSelection = resolution {
            requiresSelection = true
        } else {
            requiresSelection = false
        }
        
        if !requiresSelection {
            Issue.record("Expected unsupported language to require user selection.")
        }
        
        #expect(requiresSelection)
    }
}
