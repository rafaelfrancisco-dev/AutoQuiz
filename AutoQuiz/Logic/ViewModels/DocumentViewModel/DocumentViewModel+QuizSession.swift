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
        
        // Prepare quiz session with settings
        prepareQuizSession()
        
        hasStartedQuiz = true
        currentQuestionIndex = 0
        currentSessionAnswers.removeAll()
        currentSessionAnsweredQuestions.removeAll()
        lastAnswerCorrect = nil
        isWaitingForNextQuestion = false
        lastKnownQuestionCount = currentQuestionCounts
        showingResults = false
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
        let failedAnswers = item.answeredQuestions.filter { !$0.isCorrect }
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
            }
        }
        
        return failedQuestions
    }
    
    func endQuiz() {
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
        hasStartedQuiz = false
        showingResults = false
        currentQuestionIndex = 0
        currentSessionAnswers.removeAll()
        currentSessionAnsweredQuestions.removeAll() // Reset points by clearing answered questions
        currentSessionQuestions.removeAll()
        lastAnswerCorrect = nil
        isWaitingForNextQuestion = false
    }
    
    var quizResults: (totalQuestions: Int, correctAnswers: Int, totalPoints: Int) {
        let correctCount = currentSessionAnsweredQuestions.filter { $0.isCorrect }.count
        let totalPoints = currentSessionAnsweredQuestions.reduce(0) { $0 + $1.pointsEarned }
        return (currentSessionAnsweredQuestions.count, correctCount, totalPoints)
    }
}
