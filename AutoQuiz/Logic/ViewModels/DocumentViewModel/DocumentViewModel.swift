//
//  DocumentViewModel.swift
//  AutoQuiz
//

import Foundation
import SwiftUI
import FoundationModels

typealias DocumentAnswerProvider = @Sendable (
    _ question: String,
    _ languageMode: Generator.QuizGenerationLanguageMode
) async throws -> DocumentAnswerResult

@MainActor
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
    var isSubmittingDocumentQuestion = false
    var isLoadingDocumentQuestionAnswers = false
    var documentQuestionInput = ""
    var documentQuestionAnswers: [DocumentQuestionAnswer] = []
    var selectedDocumentQuestionRevisionSelection: ContentRevisionSelection = .current
    var documentQuestionAnswerIssue: GeneratorError?

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
    internal var pendingDocumentQuestionAfterFallback: String?
    internal let documentAnswerProvider: DocumentAnswerProvider

    // MARK: - Computed Properties
    var currentPoints: Int {
        currentSessionAnsweredQuestions.reduce(0) { $0 + $1.pointsEarned }
    }

    var generationIssueMessage: String? {
        generationIssue?.userFacingMessage
    }

    var documentQuestionAnswerIssueMessage: String? {
        documentQuestionAnswerIssue?.userFacingMessage
    }

    // MARK: - Initialization
    init(
        item: Item,
        appStore: AppStore? = nil,
        documentAnswerProvider: DocumentAnswerProvider? = nil
    ) {
        let generator = Generator(item: item)
        self.item = item
        self.generator = generator
        self.appStore = appStore
        self.documentAnswerProvider = documentAnswerProvider ?? { question, languageMode in
            try await generator.answerQuestionAboutDocument(question, languageMode: languageMode)
        }
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
