//
//  DocumentViewModel+BackgroundGeneration.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 17/06/2025.
//

import Foundation
import SwiftUI
import OSLog

extension DocumentViewModel {
    private enum GenerationAttemptResult {
        case success
        case retryableFailure(GeneratorError)
        case terminalFailure(GeneratorError)
    }
    
    private var maxConsecutiveGenerationFailures: Int { 5 }
    
    @MainActor
    func startBackgroundGeneration(languageMode: Generator.QuizGenerationLanguageMode? = nil) {
        backgroundGenerationTask?.cancel()
        
        if let issue = Generator.currentAvailabilityIssue() {
            generationIssue = issue
            isBackgroundGenerating = false
            isWaitingForNextQuestion = false
            return
        }
        
        let desiredLanguageMode = languageMode ?? defaultGenerationLanguageMode()
        activeGenerationLanguageMode = desiredLanguageMode
        resolvedGenerationLanguageMode = nil
        generationIssue = nil
        
        backgroundGenerationTask = Task { @MainActor [weak self] in
            guard let self else { return }
            await self.generateBackgroundQuestions(languageMode: desiredLanguageMode)
        }
    }
    
    @MainActor
    func stopBackgroundGeneration() {
        backgroundGenerationTask?.cancel()
        backgroundGenerationTask = nil
        isBackgroundGenerating = false
        clearWaitingStateIfNeeded()
    }
    
    @MainActor
    private func generateBackgroundQuestions(languageMode: Generator.QuizGenerationLanguageMode) async {
        guard !Task.isCancelled else { return }
        
        Logger.generation.debug("Starting background generation")
        isBackgroundGenerating = true
        var consecutiveFailures = 0
        var lastRetryableIssue: GeneratorError?
        
        // Initial generation to ensure we have questions for both types
        while !Task.isCancelled {
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
                let result = await generateMultipleChoiceQuestions(languageMode: languageMode)
                switch result {
                case .success:
                    consecutiveFailures = 0
                case .retryableFailure(let error):
                    consecutiveFailures += 1
                    lastRetryableIssue = error
                    Logger.generation.warning("Retryable multiple choice generation failure (\(consecutiveFailures)): \(error.userFacingMessage)")
                case .terminalFailure:
                    isBackgroundGenerating = false
                    return
                }
                
                if consecutiveFailures >= maxConsecutiveGenerationFailures {
                    generationIssue = lastRetryableIssue ?? .generationFailed
                    Logger.generation.error("Stopping background generation after too many consecutive failures")
                    isBackgroundGenerating = false
                    return
                }
                
                guard !Task.isCancelled else { break }
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
            
            if needMoreTrueFalse {
                let result = await generateTrueFalseQuestions(languageMode: languageMode)
                switch result {
                case .success:
                    consecutiveFailures = 0
                case .retryableFailure(let error):
                    consecutiveFailures += 1
                    lastRetryableIssue = error
                    Logger.generation.warning("Retryable true/false generation failure (\(consecutiveFailures)): \(error.userFacingMessage)")
                case .terminalFailure:
                    isBackgroundGenerating = false
                    return
                }
                
                if consecutiveFailures >= maxConsecutiveGenerationFailures {
                    generationIssue = lastRetryableIssue ?? .generationFailed
                    Logger.generation.error("Stopping background generation after too many consecutive failures")
                    isBackgroundGenerating = false
                    return
                }
                
                guard !Task.isCancelled else { break }
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
        
        isBackgroundGenerating = false
    }
    
    @MainActor
    private func generateMultipleChoiceQuestions(languageMode: Generator.QuizGenerationLanguageMode) async -> GenerationAttemptResult {
        do {
            let questions = try await generator.generateMultipleChoiceQuestions(languageMode: languageMode)
            guard !Task.isCancelled else { return .terminalFailure(.generationFailed) }
            resolvedGenerationLanguageMode = languageMode
            
            withAnimation {
                item.questions.append(contentsOf: questions)
            }
            generationIssue = nil
            
            Logger.generation.info("Generated multiple choice questions")
            
            // Add new questions to current session if active
            addNewQuestionsToSessionIfActive(questions.count, type: .multipleChoice)
            
            persistItemChanges()
            return .success
        } catch let error as GeneratorError {
            Logger.error.error("Background generation error (multiple choice): \(error.userFacingMessage)")
            if error == .unsupportedLanguageOrLocale {
                handleUnsupportedLanguage(for: languageMode)
                stopBackgroundGeneration()
                return .terminalFailure(error)
            }
            if error.isRetryable {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                return .retryableFailure(error)
            }
            
            generationIssue = error
            stopBackgroundGeneration()
            return .terminalFailure(error)
        } catch {
            Logger.error.error("Background generation error (multiple choice): \(error)")
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            return .retryableFailure(.generationFailed)
        }
    }
    
    @MainActor
    private func generateTrueFalseQuestions(languageMode: Generator.QuizGenerationLanguageMode) async -> GenerationAttemptResult {
        do {
            let questions = try await generator.generateTrueFalseQuestions(languageMode: languageMode)
            guard !Task.isCancelled else { return .terminalFailure(.generationFailed) }
            resolvedGenerationLanguageMode = languageMode
            
            withAnimation {
                if item.trueFalseQuestions == nil {
                    item.trueFalseQuestions = []
                }
                item.trueFalseQuestions?.append(contentsOf: questions)
            }
            generationIssue = nil
            
            Logger.generation.info("Generated true/false questions")
            
            // Add new questions to current session if active
            addNewQuestionsToSessionIfActive(questions.count, type: .trueFalse)
            
            persistItemChanges()
            return .success
        } catch let error as GeneratorError {
            Logger.error.error("Background generation error (true/false): \(error.userFacingMessage)")
            if error == .unsupportedLanguageOrLocale {
                handleUnsupportedLanguage(for: languageMode)
                stopBackgroundGeneration()
                return .terminalFailure(error)
            }
            if error.isRetryable {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                return .retryableFailure(error)
            }
            
            generationIssue = error
            stopBackgroundGeneration()
            return .terminalFailure(error)
        } catch {
            Logger.error.error("Background generation error (true/false): \(error)")
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            return .retryableFailure(.generationFailed)
        }
    }
    
    @MainActor
    private func addNewQuestionsToSessionIfActive(_ newQuestionCount: Int, type: Question) {
        // Only update session if quiz is active and types match
        guard hasStartedQuiz && currentQuizSettings.questionType == type else { return }
        
        let newQuestions: [QuizQuestion]
        
        switch type {
        case .multipleChoice:
            let totalQuestions = item.questions.count
            let startIndex = totalQuestions - newQuestionCount
            
            newQuestions = Array(item.questions[startIndex...]).enumerated().map { offset, question in
                QuizQuestion.multipleChoice(question, originalIndex: startIndex + offset)
            }
            
        case .trueFalse:
            guard let trueFalseQuestions = item.trueFalseQuestions else { return }
            let totalQuestions = trueFalseQuestions.count
            let startIndex = totalQuestions - newQuestionCount
            
            newQuestions = Array(trueFalseQuestions[startIndex...]).enumerated().map { offset, question in
                QuizQuestion.trueFalse(question, originalIndex: startIndex + offset)
            }
            
        case .spacedRepetition:
            // Spaced repetition doesn't use background generation
            // It has its own dedicated view and service
            return
        }
        
        // Check if adding new questions would exceed session limits
        if !currentQuizSettings.isUnlimitedQuestions {
            let remainingSlots = currentQuizSettings.maxQuestions - currentSessionQuestions.count
            if remainingSlots <= 0 { return }
            
            // Only add questions up to the limit
            let questionsToAdd = Array(newQuestions.prefix(remainingSlots))
            currentSessionQuestions.append(contentsOf: questionsToAdd)
        } else {
            // Unlimited quiz - add all new questions
            currentSessionQuestions.append(contentsOf: newQuestions)
        }
        
        Logger.generation.debug("Added \(newQuestions.count) new questions to active session")
        
        // Notify navigation system that new questions are available
        if isWaitingForNextQuestion {
            Logger.generation.debug("Auto-advancing to newly generated question")
            navigateToNextQuestion()
        }
    }

    @MainActor
    func defaultGenerationLanguageMode() -> Generator.QuizGenerationLanguageMode {
        if let fallbackIdentifier = item.preferredFallbackLanguageIdentifier {
            return .specificLanguage(Locale.Language(identifier: fallbackIdentifier))
        }
        
        return currentQuizSettings.useOriginalLanguage ? .detectedDocumentLanguage : .appLocale(.current)
    }
    
    @MainActor
    func handleUnsupportedLanguage(for languageMode: Generator.QuizGenerationLanguageMode) {
        switch generator.resolveLanguage(mode: languageMode) {
        case .resolved:
            break
        case .requiresUserSelection(let supportedLanguages):
            pendingSupportedLanguages = supportedLanguages
            isShowingLanguageSelection = !supportedLanguages.isEmpty
            generationIssue = supportedLanguages.isEmpty ? .unsupportedLanguageOrLocale : nil
        }
    }
    
    @MainActor
    func applyFallbackLanguage(_ language: Locale.Language) {
        item.preferredFallbackLanguageIdentifier = language.persistedIdentifier
        isShowingLanguageSelection = false
        pendingSupportedLanguages = []
        generationIssue = nil
        
        withAnimation {
            item.questions.removeAll()
            item.trueFalseQuestions?.removeAll()
        }
        
        persistItemChanges()
        
        let fallbackMode = Generator.QuizGenerationLanguageMode.specificLanguage(language)
        activeGenerationLanguageMode = fallbackMode
        resolvedGenerationLanguageMode = fallbackMode
        startBackgroundGeneration(languageMode: fallbackMode)
    }
}
