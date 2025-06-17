//
//  DocumentViewModel+QuizSession.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 17/06/2025.
//

import Foundation
import SwiftData

extension DocumentViewModel {
    
    func startQuiz() {
        hasStartedQuiz = true
        currentQuestionIndex = 0
        currentSessionAnswers.removeAll()
        currentSessionAnsweredQuestions.removeAll()
        lastAnswerCorrect = nil
        isWaitingForNextQuestion = false
        lastKnownQuestionCount = currentQuestionCounts
        showingResults = false
    }
    
    func endQuiz() {
        // Save all current session answers to the item's permanent storage
        for answeredQuestion in currentSessionAnsweredQuestions {
            item.answeredQuestions.append(answeredQuestion)
            item.totalPoints += answeredQuestion.pointsEarned
            
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
        lastAnswerCorrect = nil
        isWaitingForNextQuestion = false
    }
    
    var quizResults: (totalQuestions: Int, correctAnswers: Int, totalPoints: Int) {
        let correctCount = currentSessionAnsweredQuestions.filter { $0.isCorrect }.count
        let totalPoints = currentSessionAnsweredQuestions.reduce(0) { $0 + $1.pointsEarned }
        return (currentSessionAnsweredQuestions.count, correctCount, totalPoints)
    }
}