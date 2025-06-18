//
//  DocumentViewModel+BackgroundGeneration.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 17/06/2025.
//

import Foundation
import SwiftUI
import SwiftData
import OSLog

extension DocumentViewModel {
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
        
        Logger.generation.debug("Starting background generation")
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
                Logger.generation.debug("Background generation loop - Multiple choice active")
            } else {
                currentTypeUnanswered = max(0, trueFalseCount - (currentQuestionIndex + 1))
                needMore = currentTypeUnanswered < maxBackgroundQuestions
                Logger.generation.debug("Background generation loop - True/False active")
            }
            
            let needMoreMultiple = selectedQuestionType == .multipleChoice && needMore
            let needMoreTrueFalse = selectedQuestionType == .trueFalse && needMore
            
            Logger.generation.debug("Checking if more questions needed")
            
            if !needMoreMultiple && !needMoreTrueFalse {
                Logger.generation.debug("Enough questions, sleeping...")
                isBackgroundGenerating = false
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                continue
            }
            
            // Set to true only when we actually need to generate
            if !isBackgroundGenerating {
                isBackgroundGenerating = true
            }
            
            if needMoreMultiple {
                await generateMultipleChoiceQuestions()
                guard backgroundGenerationTask?.isCancelled == false else { break }
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
            
            if needMoreTrueFalse {
                await generateTrueFalseQuestions()
                guard backgroundGenerationTask?.isCancelled == false else { break }
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
        
        isBackgroundGenerating = false
        
        // Final check to clear waiting state if needed
        clearWaitingStateIfNeeded()
    }
    
    @MainActor
    private func generateMultipleChoiceQuestions() async {
        do {
            let questions = try await generator.generateMultipleChoiceQuestions()
            guard backgroundGenerationTask?.isCancelled == false else { return }
            
            withAnimation {
                item.questions.append(contentsOf: questions)
            }
            
            Logger.generation.info("Generated multiple choice questions")
            
            // Check if user is waiting for next question and auto-advance
            checkForNewQuestionsAndAutoAdvance()
            
            try? modelContext?.save()
        } catch {
            Logger.error.error("Background generation error (multiple choice): \(error)")
            try? await Task.sleep(nanoseconds: 2_000_000_000)
        }
    }
    
    @MainActor
    private func generateTrueFalseQuestions() async {
        do {
            let questions = try await generator.generateTrueFalseQuestions()
            guard backgroundGenerationTask?.isCancelled == false else { return }
            
            withAnimation {
                if item.trueFalseQuestions == nil {
                    item.trueFalseQuestions = []
                }
                item.trueFalseQuestions?.append(contentsOf: questions)
            }
            
            Logger.generation.info("Generated true/false questions")
            
            // Check if user is waiting for next question and auto-advance
            checkForNewQuestionsAndAutoAdvance()
            
            try? modelContext?.save()
        } catch {
            Logger.error.error("Background generation error (true/false): \(error)")
            try? await Task.sleep(nanoseconds: 2_000_000_000)
        }
    }
}
