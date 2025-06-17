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
    
    // MARK: - Quiz State
    var hasStartedQuiz = false
    var selectedQuestionType: Question = .multipleChoice
    
    // MARK: - Internal State (accessed by extensions)
    internal var currentSessionAnswers: Set<Int> = []
    internal var currentSessionAnsweredQuestions: [AnsweredQuestionV1] = []
    internal var lastAnswerCorrect: Bool?
    internal var isWaitingForNextQuestion = false
    internal var lastKnownQuestionCount: (multiple: Int, trueFalse: Int) = (0, 0)
    internal var backgroundGenerationTask: Task<Void, Never>?
    internal let maxBackgroundQuestions = 3
    
    // MARK: - Computed Properties
    var currentPoints: Int {
        return item.totalPoints
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
