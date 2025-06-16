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
    let item: Item
    let generator: Generator
    var modelContext: ModelContext?
    
    var isGenerating = false
    var currentQuestionIndex: Int = 0
    var isBackgroundGenerating = false
    
    var hasStartedQuiz = false
    var selectedQuestionType: Question = .multipleChoice
    private var currentSessionAnswers: Set<Int> = []
    private var lastAnswerCorrect: Bool?
    
    var isWaitingForNextQuestion = false
    private var lastKnownQuestionCount: (multiple: Int, trueFalse: Int) = (0, 0)
    
    private var backgroundGenerationTask: Task<Void, Never>?
    private let maxBackgroundQuestions = 3
    
    var currentPoints: Int {
        return item.totalPoints
    }
    
    init(item: Item, modelContext: ModelContext? = nil) {
        self.item = item
        self.generator = Generator(item: item)
        self.modelContext = modelContext
    }
    
    func startQuiz() {
        hasStartedQuiz = true
        currentQuestionIndex = 0
        currentSessionAnswers.removeAll()
        lastAnswerCorrect = nil
        isWaitingForNextQuestion = false
        lastKnownQuestionCount = currentQuestionCounts
    }
    
    func switchQuestionType(to type: Question) {
        selectedQuestionType = type
        currentQuestionIndex = 0
        currentSessionAnswers.removeAll()
        lastAnswerCorrect = nil
        isWaitingForNextQuestion = false
        lastKnownQuestionCount = currentQuestionCounts
    }
    
    var isCurrentQuestionAnswered: Bool {
        return currentSessionAnswers.contains(currentQuestionIndex)
    }
    
    var canNavigateToNext: Bool {
        let maxIndex = selectedQuestionType == .multipleChoice ?
            item.questions.count - 1 :
            (item.trueFalseQuestions?.count ?? 0) - 1
        
        return isCurrentQuestionAnswered && currentQuestionIndex < maxIndex
    }
    
    var nextButtonColor: Color {
        guard let lastCorrect = lastAnswerCorrect, isCurrentQuestionAnswered else { return .blue }
        return lastCorrect ? .green : .red
    }
    
    private var currentQuestionCounts: (multiple: Int, trueFalse: Int) {
        return (item.questions.count, item.trueFalseQuestions?.count ?? 0)
    }
    
    private var maxAvailableIndex: Int {
        return selectedQuestionType == .multipleChoice ?
            item.questions.count - 1 :
            (item.trueFalseQuestions?.count ?? 0) - 1
    }
    
    private var isAtLastAvailableQuestion: Bool {
        return currentQuestionIndex == maxAvailableIndex
    }
    
    var shouldShowWaitingIndicator: Bool {
        return isWaitingForNextQuestion && isBackgroundGenerating
    }
    
    func clearWaitingStateIfNeeded() {
        // Failsafe: if we're waiting but have available questions, clear waiting state
        if isWaitingForNextQuestion && !isAtLastAvailableQuestion {
            print("DEBUG: Clearing waiting state - questions are available")
            isWaitingForNextQuestion = false
        }
    }
    
    func checkForNewQuestionsAndAutoAdvance() {
        print("DEBUG: checkForNewQuestionsAndAutoAdvance called - isWaiting: \(isWaitingForNextQuestion)")
        
        guard isWaitingForNextQuestion else { 
            print("DEBUG: Not waiting for next question, returning early")
            return 
        }
        
        let currentCounts = currentQuestionCounts
        let hasNewQuestions: Bool
        
        if selectedQuestionType == .multipleChoice {
            hasNewQuestions = currentCounts.multiple > lastKnownQuestionCount.multiple
        } else {
            hasNewQuestions = currentCounts.trueFalse > lastKnownQuestionCount.trueFalse
        }
        
        print("DEBUG: Checking for new questions - Current: \(currentCounts), Last Known: \(lastKnownQuestionCount), Has New: \(hasNewQuestions)")
        
        if hasNewQuestions {
            print("DEBUG: Auto-advancing to new question")
            // New question available, auto-advance to it
            withAnimation {
                currentQuestionIndex += 1
                isWaitingForNextQuestion = false
                lastAnswerCorrect = nil
            }
        } else {
            print("DEBUG: No new questions available yet")
        }
    }
    
    deinit {
        backgroundGenerationTask?.cancel()
    }
    
    func answeredQuestion(question: MultipleChoiceQuestion, correct: Bool, userAnswer: String) {
        let pointsEarned = correct ? 10 : 0
        
        let answeredQuestion = AnsweredQuestion(
            questionText: question.question,
            userAnswer: userAnswer,
            correctAnswer: question.anwswer,
            isCorrect: correct,
            pointsEarned: pointsEarned,
            questionType: .multipleChoice
        )
        
        item.answeredQuestions.append(answeredQuestion)
        item.totalPoints += pointsEarned
        
        currentSessionAnswers.insert(currentQuestionIndex)
        lastAnswerCorrect = correct
        
        if let context = modelContext {
            context.insert(answeredQuestion)
            try? context.save()
        }
        
        // Auto-advance after 1 second delay
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            print("DEBUG: Auto-advance logic - canNavigateToNext: \(canNavigateToNext), isAtLast: \(isAtLastAvailableQuestion), isAnswered: \(isCurrentQuestionAnswered)")
            
            if canNavigateToNext {
                print("DEBUG: Auto-advancing to next existing question")
                withAnimation {
                    currentQuestionIndex += 1
                    // Clear answer tracking for new question
                    lastAnswerCorrect = nil
                    isWaitingForNextQuestion = false
                }
            } else if isAtLastAvailableQuestion && isCurrentQuestionAnswered {
                // User has answered the last question, set waiting state
                print("DEBUG: Setting waiting state - last question answered")
                isWaitingForNextQuestion = true
                lastKnownQuestionCount = currentQuestionCounts
                print("DEBUG: Waiting state set - lastKnownQuestionCount: \(lastKnownQuestionCount)")
            }
        }
    }
    
    func answeredTrueFalseQuestion(question: TrueFalseQuestion, correct: Bool, userAnswer: Bool) {
        let pointsEarned = correct ? 10 : 0
        
        let answeredQuestion = AnsweredQuestion(
            questionText: question.question,
            userAnswer: userAnswer ? "True" : "False",
            correctAnswer: question.isTrue ? "True" : "False",
            isCorrect: correct,
            pointsEarned: pointsEarned,
            questionType: .trueFalse
        )
        
        item.answeredQuestions.append(answeredQuestion)
        item.totalPoints += pointsEarned
        
        currentSessionAnswers.insert(currentQuestionIndex)
        lastAnswerCorrect = correct
        
        if let context = modelContext {
            context.insert(answeredQuestion)
            try? context.save()
        }
        
        // Auto-advance after 1 second delay
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            if canNavigateToNext {
                withAnimation {
                    currentQuestionIndex += 1
                    // Clear answer tracking for new question
                    lastAnswerCorrect = nil
                    isWaitingForNextQuestion = false
                }
            } else if isAtLastAvailableQuestion && isCurrentQuestionAnswered {
                // User has answered the last question, set waiting state
                isWaitingForNextQuestion = true
                lastKnownQuestionCount = currentQuestionCounts
            }
        }
    }
    
    func startBackgroundGeneration() {
        backgroundGenerationTask?.cancel()
        
        backgroundGenerationTask = Task { @MainActor in
            await generateBackgroundQuestions()
        }
    }
    
    func stopBackgroundGeneration() {
        backgroundGenerationTask?.cancel()
        backgroundGenerationTask = nil
        isBackgroundGenerating = false
        clearWaitingStateIfNeeded()
    }
    
    @MainActor
    private func generateBackgroundQuestions() async {
        guard backgroundGenerationTask?.isCancelled == false else { return }
        
        print("DEBUG: Starting background generation")
        isBackgroundGenerating = true
        
        // Initial generation to ensure we have questions for both types
        while backgroundGenerationTask?.isCancelled == false {
            let multipleChoiceCount = item.questions.count
            let trueFalseCount = item.trueFalseQuestions?.count ?? 0
            
            // Calculate how many questions are ahead of current position for the current type
            let currentTypeUnanswered: Int
            let needMore: Bool
            
            if selectedQuestionType == .multipleChoice {
                currentTypeUnanswered = max(0, multipleChoiceCount - (currentQuestionIndex + 1))
                needMore = currentTypeUnanswered < maxBackgroundQuestions
                print("DEBUG: Background generation loop - Multiple choice active: \(multipleChoiceCount) total, \(currentTypeUnanswered) unanswered, need more: \(needMore)")
            } else {
                currentTypeUnanswered = max(0, trueFalseCount - (currentQuestionIndex + 1))
                needMore = currentTypeUnanswered < maxBackgroundQuestions
                print("DEBUG: Background generation loop - True/False active: \(trueFalseCount) total, \(currentTypeUnanswered) unanswered, need more: \(needMore)")
            }
            
            let needMoreMultiple = selectedQuestionType == .multipleChoice && needMore
            let needMoreTrueFalse = selectedQuestionType == .trueFalse && needMore
            
            print("DEBUG: needMoreMultiple: \(needMoreMultiple), needMoreTrueFalse: \(needMoreTrueFalse)")
            
            if !needMoreMultiple && !needMoreTrueFalse {
                print("DEBUG: Enough questions, sleeping...")
                isBackgroundGenerating = false
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                continue
            }
            
            // Set to true only when we actually need to generate
            if !isBackgroundGenerating {
                isBackgroundGenerating = true
            }
            
            if needMoreMultiple {
                do {
                    let questions = try await generator.generateMultipleChoiceQuestions()
                    guard backgroundGenerationTask?.isCancelled == false else { break }
                    
                    withAnimation {
                        item.questions.append(contentsOf: questions)
                    }
                    
                    print("DEBUG: Generated \(questions.count) multiple choice questions, total count now: \(item.questions.count)")
                    
                    // Check if user is waiting for next question and auto-advance
                    checkForNewQuestionsAndAutoAdvance()
                    
                    try? modelContext?.save()
                } catch {
                    print("Background generation error (multiple choice): \(error)")
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                }
                
                guard backgroundGenerationTask?.isCancelled == false else { break }
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
            
            if needMoreTrueFalse {
                do {
                    let questions = try await generator.generateTrueFalseQuestions()
                    guard backgroundGenerationTask?.isCancelled == false else { break }
                    
                    withAnimation {
                        if item.trueFalseQuestions == nil {
                            item.trueFalseQuestions = []
                        }
                        item.trueFalseQuestions?.append(contentsOf: questions)
                    }
                    
                    print("DEBUG: Generated \(questions.count) true/false questions, total count now: \(item.trueFalseQuestions?.count ?? 0)")
                    
                    // Check if user is waiting for next question and auto-advance
                    checkForNewQuestionsAndAutoAdvance()
                    
                    try? modelContext?.save()
                } catch {
                    print("Background generation error (true/false): \(error)")
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                }
                
                guard backgroundGenerationTask?.isCancelled == false else { break }
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
        
        isBackgroundGenerating = false
        
        // Final check to clear waiting state if needed
        clearWaitingStateIfNeeded()
    }
}
