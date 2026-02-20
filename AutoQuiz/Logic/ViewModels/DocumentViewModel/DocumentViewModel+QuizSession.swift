//
//  DocumentViewModel+QuizSession.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 17/06/2025.
//

import Foundation
import SwiftData

extension DocumentViewModel {
    func startQuiz(with settings: QuizSettings = .default) {
        // Store quiz settings for this session
        currentQuizSettings = settings
        selectedQuestionType = settings.questionType
        
        let desiredLanguageMode: Generator.QuizGenerationLanguageMode
        if let fallbackIdentifier = item.preferredFallbackLanguageIdentifier {
            desiredLanguageMode = .specificLanguage(Locale.Language(identifier: fallbackIdentifier))
        } else {
            desiredLanguageMode = settings.useOriginalLanguage ? .detectedDocumentLanguage : .appLocale(.current)
        }
        
        if activeGenerationLanguageMode != desiredLanguageMode {
            item.questions.removeAll()
            item.trueFalseQuestions?.removeAll()
            stopBackgroundGeneration()
            startBackgroundGeneration(languageMode: desiredLanguageMode)
        } else if backgroundGenerationTask == nil {
            startBackgroundGeneration(languageMode: desiredLanguageMode)
        }
        
        // COMPLETELY RESET all session state
        hasStartedQuiz = false
        currentQuestionIndex = 0
        currentSessionAnswers.removeAll()
        currentSessionAnsweredQuestions.removeAll()
        currentSessionQuestions.removeAll()
        currentQuestionStartedAt = nil
        lastAnswerCorrect = nil
        isWaitingForNextQuestion = false
        showingResults = false
        
        // Create new QuizSession for analytics tracking
        currentQuizSession = QuizSession(
            document: item,
            questionType: settings.questionType,
            maxQuestions: settings.maxQuestions,
            isUnlimitedQuestions: settings.isUnlimitedQuestions,
            shuffleQuestions: settings.shuffleQuestions,
            includeFailedQuestions: settings.includeFailedQuestions,
            sourceContentRevision: item.contentRevision
        )
        
        // Add to model context
        if let session = currentQuizSession, let context = modelContext {
            context.insert(session)
        }
        
        // Prepare quiz session with settings
        prepareQuizSession()
        
        // Now mark quiz as started
        hasStartedQuiz = true
        currentQuestionStartedAt = Date()
        lastKnownQuestionCount = currentQuestionCounts
    }
    
    private func prepareQuizSession() {
        // Reset any previous session questions
        currentSessionQuestions.removeAll()
        
        // Get base questions based on type
        var availableQuestions: [QuizQuestion] = []
        
        switch currentQuizSettings.questionType {
        case .multipleChoice:
            availableQuestions = item.questions.enumerated().map { index, question in
                QuizQuestion.multipleChoice(question, originalIndex: index)
            }
        case .trueFalse:
            availableQuestions = (item.trueFalseQuestions ?? []).enumerated().map { index, question in
                QuizQuestion.trueFalse(question, originalIndex: index)
            }
        case .spacedRepetition:
            // Spaced repetition uses its own separate view and workflow
            // No questions are prepared here as it's handled by SpacedRepetitionView
            availableQuestions = []
        }
        
        // Include previously failed questions if enabled
        if currentQuizSettings.includeFailedQuestions {
            let failedQuestions = getFailedQuestionsFromHistory()
            availableQuestions.append(contentsOf: failedQuestions)
        }
        
        // Shuffle if enabled
        if currentQuizSettings.shuffleQuestions {
            availableQuestions.shuffle()
        }
        
        // Limit questions if not unlimited
        if !currentQuizSettings.isUnlimitedQuestions {
            availableQuestions = Array(availableQuestions.prefix(currentQuizSettings.maxQuestions))
        }
        
        currentSessionQuestions = availableQuestions
    }
    
    private func getFailedQuestionsFromHistory() -> [QuizQuestion] {
        let failedAnswers = item.answeredQuestions.filter {
            !$0.isCorrect && $0.sourceContentRevision == item.contentRevision
        }
        var failedQuestions: [QuizQuestion] = []
        
        for failedAnswer in failedAnswers {
            switch failedAnswer.questionType {
            case .multipleChoice:
                if let question = item.questions.first(where: { $0.question == failedAnswer.questionText }) {
                    let originalIndex = item.questions.firstIndex(where: { $0.question == failedAnswer.questionText }) ?? 0
                    failedQuestions.append(.multipleChoice(question, originalIndex: originalIndex))
                }
            case .trueFalse:
                if let question = item.trueFalseQuestions?.first(where: { $0.question == failedAnswer.questionText }) {
                    let originalIndex = item.trueFalseQuestions?.firstIndex(where: { $0.question == failedAnswer.questionText }) ?? 0
                    failedQuestions.append(.trueFalse(question, originalIndex: originalIndex))
                }
            case .spacedRepetition:
                // Spaced repetition cards have their own review system and scheduling
                // They don't need to be included in regular quiz failed questions
                break
            }
        }
        
        return failedQuestions
    }
    
    func endQuiz() {
        // Complete the current quiz session
        if let session = currentQuizSession {
            session.completeSession()
        }
        
        // Save all current session answers to the item's permanent storage
        // Points are no longer persisted - they reset after each quiz
        for answeredQuestion in currentSessionAnsweredQuestions {
            item.answeredQuestions.append(answeredQuestion)
            
            if let context = modelContext {
                context.insert(answeredQuestion)
            }
        }
        
        // Save to database
        if let context = modelContext {
            try? context.save()
        }
        
        showingResults = true
    }
    
    func resetQuiz() {
        // Handle current quiz session if it exists
        if let session = currentQuizSession {
            if !session.isCompleted {
                session.abandonSession()
                // Save the abandoned session to database
                if let context = modelContext {
                    try? context.save()
                }
            }
        }
        currentQuizSession = nil
        
        hasStartedQuiz = false
        showingResults = false
        currentQuestionIndex = 0
        currentSessionAnswers.removeAll()
        currentSessionAnsweredQuestions.removeAll() // Reset points by clearing answered questions
        currentSessionQuestions.removeAll()
        currentQuestionStartedAt = nil
        lastAnswerCorrect = nil
        isWaitingForNextQuestion = false
    }
    
    var quizResults: (totalQuestions: Int, correctAnswers: Int, totalPoints: Int) {
        let correctCount = currentSessionAnsweredQuestions.filter { $0.isCorrect }.count
        let totalPoints = currentSessionAnsweredQuestions.reduce(0) { $0 + $1.pointsEarned }
        return (currentSessionAnsweredQuestions.count, correctCount, totalPoints)
    }
}
