//
//  DocumentViewModel+Navigation.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 17/06/2025.
//

import Foundation
import SwiftUI

extension DocumentViewModel {
    func switchQuestionType(to type: Question) {
        selectedQuestionType = type
        currentQuestionIndex = 0
        currentSessionAnswers.removeAll()
        lastAnswerCorrect = nil
        isWaitingForNextQuestion = false
        lastKnownQuestionCount = currentQuestionCounts
    }
    
    var isCurrentQuestionAnswered: Bool {
        // For quiz sessions, check if current question content was answered (not just index)
        if hasStartedQuiz, let currentQuestion = getCurrentSessionQuestion() {
            return isQuestionContentAnsweredInSession(currentQuestion)
        }
        
        // For non-session mode, fall back to index-based check
        return currentSessionAnswers.contains(currentQuestionIndex)
    }
    
    private func isQuestionContentAnsweredInSession(_ quizQuestion: QuizQuestion) -> Bool {
        let questionText = quizQuestion.questionText
        
        return currentSessionAnsweredQuestions.contains { answeredQ in
            answeredQ.questionText == questionText
        }
    }
    
    var canNavigateToNext: Bool {
        // Get the maximum available index based on current state
        let maxIndex = getMaxAvailableIndex()
        
        // Check if we can advance to the next question
        let hasNextQuestion = currentQuestionIndex < maxIndex
        
        // Allow skipping if enabled, otherwise only show next when answered
        let canAdvance = currentQuizSettings.allowSkipQuestions || isCurrentQuestionAnswered
        
        return hasNextQuestion && canAdvance
    }
    
    private func getMaxAvailableIndex() -> Int {
        if hasStartedQuiz {
            // For active quiz sessions, use session questions
            return max(0, currentSessionQuestions.count - 1)
        } else {
            // For non-session mode, use original questions
            return selectedQuestionType == .multipleChoice ?
                max(0, item.questions.count - 1) :
                max(0, (item.trueFalseQuestions?.count ?? 0) - 1)
        }
    }
    
    var currentQuestionCounts: (multiple: Int, trueFalse: Int) {
        return (item.questions.count, item.trueFalseQuestions?.count ?? 0)
    }
    
    var maxAvailableIndex: Int {
        // Use session questions if quiz has started, otherwise use original logic
        return hasStartedQuiz ? 
            currentSessionQuestions.count - 1 :
            (selectedQuestionType == .multipleChoice ?
                item.questions.count - 1 :
                (item.trueFalseQuestions?.count ?? 0) - 1)
    }
    
    var isAtLastAvailableQuestion: Bool {
        return currentQuestionIndex == maxAvailableIndex
    }
    
    func getCurrentSessionQuestion() -> QuizQuestion? {
        guard hasStartedQuiz,
              currentQuestionIndex < currentSessionQuestions.count else {
            return nil
        }
        
        return currentSessionQuestions[currentQuestionIndex]
    }
}
