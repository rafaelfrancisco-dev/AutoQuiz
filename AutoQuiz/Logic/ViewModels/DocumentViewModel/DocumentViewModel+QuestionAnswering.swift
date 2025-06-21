//
//  DocumentViewModel+QuestionAnswering.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 17/06/2025.
//

import Foundation
import SwiftUI
import OSLog

extension DocumentViewModel {
    func answeredQuestion(question: MultipleChoiceQuestion, correct: Bool, userAnswer: String) {
        let pointsEarned = correct ? 10 : 0
        
        let answeredQuestion = AnsweredQuestionV1(
            questionText: question.question,
            userAnswer: userAnswer,
            correctAnswer: question.anwswer,
            isCorrect: correct,
            pointsEarned: pointsEarned,
            questionType: .multipleChoice
        )
        
        recordAnswer(answeredQuestion)
        
        // Auto-advance after brief delay for UI feedback
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            startContinuousAutoAdvance()
        }
    }
    
    func answeredTrueFalseQuestion(question: TrueFalseQuestion, correct: Bool, userAnswer: Bool) {
        let pointsEarned = correct ? 10 : 0
        
        let answeredQuestion = AnsweredQuestionV1(
            questionText: question.question,
            userAnswer: userAnswer ? "True" : "False",
            correctAnswer: question.isTrue ? "True" : "False",
            isCorrect: correct,
            pointsEarned: pointsEarned,
            questionType: .trueFalse
        )
        
        recordAnswer(answeredQuestion)
        
        // Auto-advance after brief delay for UI feedback
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            startContinuousAutoAdvance()
        }
    }
    
    private func recordAnswer(_ answeredQuestion: AnsweredQuestionV1) {
        currentSessionAnsweredQuestions.append(answeredQuestion)
        currentSessionAnswers.insert(currentQuestionIndex)
        lastAnswerCorrect = answeredQuestion.isCorrect
    }
    
    private func startContinuousAutoAdvance() {
        // Check if we've reached the maximum questions for non-unlimited quizzes
        let hasReachedMaxQuestions = !self.currentQuizSettings.isUnlimitedQuestions && 
                                   self.currentSessionAnsweredQuestions.count >= self.currentQuizSettings.maxQuestions
        
        if hasReachedMaxQuestions {
            Logger.quiz.debug("Reached maximum questions (\(self.currentQuizSettings.maxQuestions)) - auto-ending quiz")
            self.endQuiz()
            return
        }
        
        // Start the continuous auto-advance loop
        Task { @MainActor in
            await continuouslyTryToAdvance()
        }
    }
    
    @MainActor
    private func continuouslyTryToAdvance() async {
        Logger.quiz.debug("Starting continuous auto-advance loop")
        
        // Ensure background generation is running
        if !isBackgroundGenerating {
            startBackgroundGeneration()
        }
        
        // Keep trying to advance until we succeed or reach max questions
        while true {
            // Check if max questions reached
            let hasReachedMaxQuestions = !self.currentQuizSettings.isUnlimitedQuestions && 
                                       self.currentSessionAnsweredQuestions.count >= self.currentQuizSettings.maxQuestions
            
            if hasReachedMaxQuestions {
                Logger.quiz.debug("Reached maximum questions - ending quiz")
                self.endQuiz()
                return
            }
            
            // Try to advance
            if canNavigateToNext {
                Logger.quiz.debug("Auto-advancing to next question")
                withAnimation {
                    currentQuestionIndex += 1
                    lastAnswerCorrect = nil
                    isWaitingForNextQuestion = false
                }
                return // Success! Exit the loop
            }
            
            // No next question available yet - show waiting indicator and try again
            Logger.quiz.debug("No next question available - waiting and retrying")
            isWaitingForNextQuestion = true
            
            // Wait a bit before trying again
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        }
    }
    
    func getPreviousAnswer(for question: MultipleChoiceQuestion) -> String? {
        return currentSessionAnsweredQuestions.first(where: { 
            $0.questionText == question.question && $0.questionType == .multipleChoice 
        })?.userAnswer
    }
    
    func getPreviousAnswer(for question: TrueFalseQuestion) -> Bool? {
        guard let userAnswer = currentSessionAnsweredQuestions.first(where: { 
            $0.questionText == question.question && $0.questionType == .trueFalse 
        })?.userAnswer else { return nil }
        
        return userAnswer == "True"
    }
}
