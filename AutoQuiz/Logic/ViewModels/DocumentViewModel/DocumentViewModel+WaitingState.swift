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
    
    @MainActor
    func clearWaitingStateIfNeeded() {
        // Failsafe: if we're waiting but have available questions, clear waiting state
        if isWaitingForNextQuestion && !isAtLastAvailableQuestion {
            Logger.viewModel.debug("Clearing waiting state - questions are available")
            isWaitingForNextQuestion = false
        }
    }
    
    @MainActor
    func checkForNewQuestionsAndAutoAdvance() {
        Logger.viewModel.debug("checkForNewQuestionsAndAutoAdvance called - isWaiting: \(self.isWaitingForNextQuestion)")
        
        // This method is now simplified - background generator handles auto-advance notification
        guard isWaitingForNextQuestion && canNavigateToNext else { 
            Logger.viewModel.debug("Not waiting or no questions available")
            return 
        }
        
        // Navigate if we have questions available
        Logger.viewModel.debug("Auto-advancing to next question")
        navigateToNextQuestion()
    }
}
