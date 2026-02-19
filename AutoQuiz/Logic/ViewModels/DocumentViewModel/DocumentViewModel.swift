//
//  DocumentViewModel.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 12/06/2025.
//

import Foundation
import SwiftUI
import SwiftData
import FoundationModels

@Observable
final class DocumentViewModel {
    // MARK: - Core Properties
    let item: Item
    let generator: Generator
    var modelContext: ModelContext?
    
    // MARK: - UI State
    var isGenerating = false
    var currentQuestionIndex: Int = 0
    var isBackgroundGenerating = false
    var showingResults = false
    var generationIssue: GeneratorError?
    
    // MARK: - Quiz State
    var hasStartedQuiz = false
    var selectedQuestionType: Question = .multipleChoice
    var currentQuizSettings = QuizSettings.default
    
    // MARK: - Internal State (accessed by extensions)
    internal var currentSessionAnswers: Set<Int> = []
    internal var currentSessionAnsweredQuestions: [AnsweredQuestionV1] = []
    internal var currentSessionQuestions: [QuizQuestion] = []
    internal var currentQuizSession: QuizSession?
    internal var lastAnswerCorrect: Bool?
    internal var isWaitingForNextQuestion = false
    internal var lastKnownQuestionCount: (multiple: Int, trueFalse: Int) = (0, 0)
    internal var backgroundGenerationTask: Task<Void, Never>?
    internal let maxBackgroundQuestions = 3
    
    // MARK: - Computed Properties
    var currentPoints: Int {
        // Points are now calculated from current session only
        return currentSessionAnsweredQuestions.reduce(0) { $0 + $1.pointsEarned }
    }
    
    var generationIssueMessage: String? {
        generationIssue?.userFacingMessage
    }
    
    // MARK: - Initialization
    init(item: Item, modelContext: ModelContext? = nil) {
        self.item = item
        self.generator = Generator(item: item)
        self.modelContext = modelContext
    }
    
    // MARK: - Cleanup
    deinit {
        backgroundGenerationTask?.cancel()
    }
}
