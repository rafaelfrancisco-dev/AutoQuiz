//
//  DocumentViewModel.swift
//  AutoQuiz
//

import Foundation
import SwiftUI
import FoundationModels

@Observable
final class DocumentViewModel {
    // MARK: - Core Properties
    let item: Item
    let generator: Generator
    var appStore: AppStore?

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
    var activeGenerationLanguageMode: Generator.QuizGenerationLanguageMode?
    var resolvedGenerationLanguageMode: Generator.QuizGenerationLanguageMode?
    var pendingSupportedLanguages: [Locale.Language] = []
    var isShowingLanguageSelection = false

    // MARK: - Internal State (accessed by extensions)
    internal var currentSessionAnswers: Set<Int> = []
    internal var currentSessionAnsweredQuestions: [AnsweredQuestion] = []
    internal var currentSessionQuestions: [QuizQuestion] = []
    internal var currentQuizSession: QuizSession?
    internal var currentQuestionStartedAt: Date?
    internal var lastAnswerCorrect: Bool?
    internal var isWaitingForNextQuestion = false
    internal var lastKnownQuestionCount: (multiple: Int, trueFalse: Int) = (0, 0)
    internal var backgroundGenerationTask: Task<Void, Never>?
    internal let maxBackgroundQuestions = 3

    // MARK: - Computed Properties
    var currentPoints: Int {
        currentSessionAnsweredQuestions.reduce(0) { $0 + $1.pointsEarned }
    }

    var generationIssueMessage: String? {
        generationIssue?.userFacingMessage
    }

    // MARK: - Initialization
    init(item: Item, appStore: AppStore? = nil) {
        self.item = item
        self.generator = Generator(item: item)
        self.appStore = appStore
    }

    // MARK: - Cleanup
    deinit {
        backgroundGenerationTask?.cancel()
    }

    func persistItemChanges() {
        guard let appStore else { return }
        let item = self.item
        Task {
            await appStore.saveItem(item)
        }
    }

    func persistAnsweredQuestion(_ answeredQuestion: AnsweredQuestion) {
        guard let appStore else { return }
        Task {
            await appStore.saveAnsweredQuestion(answeredQuestion)
        }
    }

    func persistQuizSession() {
        guard let appStore, let currentQuizSession else { return }
        Task {
            await appStore.saveQuizSession(currentQuizSession)
        }
    }
}
