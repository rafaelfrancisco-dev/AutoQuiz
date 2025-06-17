//
//  DocumentViewModel+WaitingState.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 17/06/2025.
//

import Foundation
import SwiftUI

extension DocumentViewModel {
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
}
