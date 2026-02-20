//
//  DocumentViewModelLanguageFallbackTests.swift
//  AutoQuizTests
//
//  Created by Codex on 20/02/2026.
//

import Testing
import Foundation
@testable import AutoQuiz

struct DocumentViewModelLanguageFallbackTests {
    @Test
    @MainActor
    func applyFallbackLanguagePersistsChoiceOnDocument() {
        let item = Item(timestamp: .now, content: "Documento de teste")
        let viewModel = DocumentViewModel(item: item)
        
        viewModel.pendingSupportedLanguages = [.init(identifier: "pt"), .init(identifier: "en")]
        viewModel.isShowingLanguageSelection = true
        
        viewModel.applyFallbackLanguage(.init(identifier: "pt"))
        
        #expect(item.preferredFallbackLanguageIdentifier == "pt")
        #expect(viewModel.isShowingLanguageSelection == false)
        #expect(viewModel.pendingSupportedLanguages.isEmpty)
    }
    
    @Test
    @MainActor
    func startQuizClearsQuestionPoolsWhenLanguageModeChanges() {
        let item = Item(timestamp: .now, content: "Test content")
        item.questions = [
            MultipleChoiceQuestion(question: "Q1", options: ["A", "B", "C", "D"], anwswer: "A")
        ]
        item.trueFalseQuestions = [
            TrueFalseQuestion(question: "T1", isTrue: true)
        ]
        
        let viewModel = DocumentViewModel(item: item)
        viewModel.activeGenerationLanguageMode = .appLocale(Locale(identifier: "en-US"))
        
        let settings = QuizSettings(
            questionType: .multipleChoice,
            maxQuestions: 10,
            includeFailedQuestions: false,
            shuffleQuestions: false,
            useOriginalLanguage: true,
            allowSkipQuestions: false
        )
        
        viewModel.startQuiz(with: settings)
        
        #expect(item.questions.isEmpty)
        #expect(item.trueFalseQuestions?.isEmpty == true)
    }
}
