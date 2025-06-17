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
        let maxIndex = selectedQuestionType == .multipleChoice ?
            item.questions.count - 1 :
            (item.trueFalseQuestions?.count ?? 0) - 1
        
        // Only show next button when viewing a past answered question (for navigation)
        return currentQuestionIndex < maxIndex && isCurrentQuestionAnswered
    }
    
    var currentQuestionCounts: (multiple: Int, trueFalse: Int) {
        return (item.questions.count, item.trueFalseQuestions?.count ?? 0)
    }
    
    var maxAvailableIndex: Int {
        return selectedQuestionType == .multipleChoice ?
            item.questions.count - 1 :
            (item.trueFalseQuestions?.count ?? 0) - 1
    }
    
    var isAtLastAvailableQuestion: Bool {
        return currentQuestionIndex == maxAvailableIndex
    }
}
