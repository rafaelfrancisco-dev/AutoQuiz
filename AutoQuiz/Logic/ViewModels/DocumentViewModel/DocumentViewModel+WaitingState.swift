//
//  DocumentViewModel+WaitingState.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 17/06/2025.
//

import Foundation
import SwiftUI
import OSLog

extension DocumentViewModel {
    var shouldShowWaitingIndicator: Bool {
        return isWaitingForNextQuestion && isBackgroundGenerating
    }
    
    func clearWaitingStateIfNeeded() {
        // Failsafe: if we're waiting but have available questions, clear waiting state
        if isWaitingForNextQuestion && !isAtLastAvailableQuestion {
            Logger.viewModel.debug("Clearing waiting state - questions are available")
            isWaitingForNextQuestion = false
        }
    }
    
    func checkForNewQuestionsAndAutoAdvance() {
        Logger.viewModel.debug("checkForNewQuestionsAndAutoAdvance called - isWaiting: \(self.isWaitingForNextQuestion)")
        
        guard isWaitingForNextQuestion else { 
            Logger.viewModel.debug("Not waiting for next question, returning early")
            return 
        }
        
        // For session-based quizzes, check if new questions were added to currentSessionQuestions
        if hasStartedQuiz {
            let currentSessionCount = currentSessionQuestions.count
            let hasNewSessionQuestions = currentQuestionIndex < currentSessionCount - 1
            
            Logger.viewModel.debug("Session mode - currentIndex: \(self.currentQuestionIndex), sessionCount: \(currentSessionCount), hasNew: \(hasNewSessionQuestions)")
            
            if hasNewSessionQuestions {
                Logger.viewModel.debug("Auto-advancing to new session question")
                withAnimation {
                    currentQuestionIndex += 1
                    isWaitingForNextQuestion = false
                    lastAnswerCorrect = nil
                }
                return
            }
        }
        
        // Fallback to original logic for non-session quizzes
        let currentCounts = currentQuestionCounts
        let hasNewQuestions: Bool
        
        if selectedQuestionType == .multipleChoice {
            hasNewQuestions = currentCounts.multiple > lastKnownQuestionCount.multiple
        } else {
            hasNewQuestions = currentCounts.trueFalse > lastKnownQuestionCount.trueFalse
        }
        
        Logger.viewModel.debug("Checking for new questions - Has New: \(hasNewQuestions)")
        
        if hasNewQuestions {
            Logger.viewModel.debug("Auto-advancing to new question")
            // New question available, auto-advance to it
            withAnimation {
                currentQuestionIndex += 1
                isWaitingForNextQuestion = false
                lastAnswerCorrect = nil
            }
        } else {
            Logger.viewModel.debug("No new questions available yet")
        }
    }
}
