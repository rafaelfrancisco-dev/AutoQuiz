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
        return currentSessionAnswers.contains(currentQuestionIndex)
    }
    
    var canNavigateToNext: Bool {
        // Use session questions if quiz has started, otherwise use original logic
        let maxIndex = hasStartedQuiz ? 
            currentSessionQuestions.count - 1 :
            (selectedQuestionType == .multipleChoice ?
                item.questions.count - 1 :
                (item.trueFalseQuestions?.count ?? 0) - 1)
        
        // Allow skipping if enabled, otherwise only show next when answered
        let canAdvance = currentQuizSettings.allowSkipQuestions || isCurrentQuestionAnswered
        
        return currentQuestionIndex < maxIndex && canAdvance
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
