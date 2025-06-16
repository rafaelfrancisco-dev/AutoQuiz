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
        
        if let context = modelContext {
            context.insert(answeredQuestion)
            try? context.save()
        }
        
        if currentQuestionIndex < item.questions.count - 1 {
            withAnimation {
                currentQuestionIndex += 1
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
        
        if let context = modelContext {
            context.insert(answeredQuestion)
            try? context.save()
        }
        
        if currentQuestionIndex < (item.trueFalseQuestions?.count ?? 0) - 1 {
            withAnimation {
                currentQuestionIndex += 1
            }
        }
    }
    
    func startBackgroundGeneration(session: LanguageModelSession) {
        backgroundGenerationTask?.cancel()
        
        backgroundGenerationTask = Task { @MainActor in
            await generateBackgroundQuestions(session: session)
        }
    }
    
    func stopBackgroundGeneration() {
        backgroundGenerationTask?.cancel()
        backgroundGenerationTask = nil
        isBackgroundGenerating = false
    }
    
    @MainActor
    private func generateBackgroundQuestions(session: LanguageModelSession) async {
        guard backgroundGenerationTask?.isCancelled == false else { return }
        
        isBackgroundGenerating = true
        
        while backgroundGenerationTask?.isCancelled == false {
            let shouldGenerateMultiple = item.questions.count < maxBackgroundQuestions
            let shouldGenerateTrueFalse = (item.trueFalseQuestions?.count ?? 0) < maxBackgroundQuestions
            
            if !shouldGenerateMultiple && !shouldGenerateTrueFalse {
                break
            }
            
            if shouldGenerateMultiple {
                do {
                    let question = try await generator.generateMultipleChoiceQuestion(session)
                    guard backgroundGenerationTask?.isCancelled == false else { break }
                    
                    withAnimation {
                        item.questions.append(question)
                    }
                    
                    try? modelContext?.save()
                } catch {
                    print("Background generation error (multiple choice): \(error)")
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                }
            }
            
            guard backgroundGenerationTask?.isCancelled == false else { break }
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            if shouldGenerateTrueFalse {
                do {
                    let question = try await generator.generateTrueFalseQuestion(session)
                    guard backgroundGenerationTask?.isCancelled == false else { break }
                    
                    withAnimation {
                        if item.trueFalseQuestions == nil {
                            item.trueFalseQuestions = []
                        }
                        item.trueFalseQuestions?.append(question)
                    }
                    
                    try? modelContext?.save()
                } catch {
                    print("Background generation error (true/false): \(error)")
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                }
            }
            
            guard backgroundGenerationTask?.isCancelled == false else { break }
            try? await Task.sleep(nanoseconds: 3_000_000_000)
        }
        
        isBackgroundGenerating = false
    }
}
